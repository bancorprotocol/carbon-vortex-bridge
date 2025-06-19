// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { ITokenBridge } from "../vendor/interfaces/ITokenBridge.sol";
import { IWormhole } from "../vendor/interfaces/IWormhole.sol";
import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";

/**
 * @dev VortexWormholeBridge contract
 */
contract VortexWormholeBridge is VortexBridgeBase {
    // mainnet wormhole recipient chain id
    uint16 private constant RECIPIENT_CHAIN_ID = 2;

    // wormhole token bridge
    ITokenBridge private immutable _tokenBridge;

    // wormhole contract
    IWormhole private immutable _wormhole;

    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(
        ICarbonVortex vortexInit,
        ITokenBridge tokenBridge,
        IWormhole wormhole,
        address vaultInit
    ) validAddress(address(tokenBridge)) validAddress(address(wormhole)) VortexBridgeBase(vortexInit, vaultInit) {
        _tokenBridge = tokenBridge;
        _wormhole = wormhole;

        _disableInitializers();
    }

    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}

    /**
     * @inheritdoc Upgradeable
     */
    function version() public pure override(Upgradeable) returns (uint16) {
        return 1;
    }

    /**
     * @notice function which bridges the target / final target tokens accumulated in the vortex to the mainnet vault
     * @notice if amount == 0, the entire available balance is bridged
     */
    function bridge(uint256 amount) external payable override nonReentrant returns (uint256) {
        // withdraw funds from vortex
        amount = _withdrawVortex(amount);
        // if amount == 0, there is no balance in the vortex (or only dust)
        if (amount == 0) {
            return 0;
        }

        // calculate the value to send with the tx
        uint256 valueToSend = _wormhole.messageFee();

        // validate sufficient native token sent
        _validateSufficientNativeTokenSent(msg.value, valueToSend);

        // approve token if not approved
        _setPlatformAllowance(_withdrawToken, address(_tokenBridge), amount);

        // bridge
        _tokenBridge.transferTokens{ value: valueToSend }(
            Token.unwrap(_withdrawToken),
            amount,
            RECIPIENT_CHAIN_ID, // mainnet chain id
            _addressToBytes32(_vault), // vault address on mainnet
            0, // arbiter fee
            0 // nonce
        );

        // refund user if excess native token sent
        _refundExcessNativeTokenSent(msg.sender, msg.value, valueToSend);

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return amount;
    }

    /**
     * @dev withdraws *amount* of _withdrawToken from the vortex to this contract
     * @dev if amount == 0, the entire available balance is withdrawn
     * @dev sanitizes amount by cutting off any dust (wormhole bridge specific)
     */
    function _withdrawVortex(uint256 amount) internal override returns (uint256) {
        uint256 withdrawBalance = _withdrawToken.balanceOf(address(_vortex));
        if (withdrawBalance == 0) {
            return 0;
        }
        // if amount is greater than the available balance or is 0, set amount to the available balance
        if (amount > withdrawBalance || amount == 0) {
            amount = withdrawBalance;
        }
        // cut off any dust (if token decimals > 8)
        amount = _sanitizeAmount(amount, _withdrawToken.decimals());
        // check if amount is 0 after sanitization (and return if so)
        if (amount == 0) {
            return 0;
        }
        Token[] memory tokens = new Token[](1);
        tokens[0] = _withdrawToken;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // withdraw the token from the vortex
        _vortex.withdrawFunds(tokens, payable(address(this)), amounts);

        return amount;
    }

    /**
     * @dev rounds amount down to the nearest unit with 8-decimal precision
     */
    function _sanitizeAmount(uint256 amount, uint8 decimals) private pure returns (uint256) {
        if (decimals > 8) {
            uint256 factor = 10 ** (decimals - 8);
            amount = (amount / factor) * factor;
        }
        return amount;
    }

    /**
     * @dev converts an address to bytes32
     */
    function _addressToBytes32(address _addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
