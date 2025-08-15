// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { IHypERC20 } from "../vendor/interfaces/IHypERC20.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { Token } from "../token/Token.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";

/**
 * @dev VortexHyperlaneBridge contract
 */
contract VortexHyperlaneBridge is VortexBridgeBase {
    // hyperlane mainnet destination endpoint id
    uint32 private constant DESTINATION_ENDPOINT_ID = 1;

    IHypERC20 private _hypERC20; // hyperlane ERC20 token (equal to _withdrawToken)

    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(ICarbonVortex vortexInit, address vaultInit) VortexBridgeBase(vortexInit, vaultInit) {
        _disableInitializers();
    }

    /**
     * @dev initializes the contract
     */
    function initialize(Token withdrawTokenInit, uint32 slippagePPMInit) external override initializer {
        __VortexBridgeBase_init(withdrawTokenInit, slippagePPMInit);
        // set the hyperlane ERC20 token (always equal to _withdrawToken)
        _hypERC20 = IHypERC20(Token.unwrap(withdrawTokenInit));
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
        // if amount == 0, there is no balance in the vortex
        if (amount == 0) {
            return 0;
        }

        // get the messaging fee for the bridge transaction
        uint256 valueToSend = _hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);

        // validate sufficient native token sent
        _validateSufficientNativeTokenSent(msg.value, valueToSend);

        // bridge the token to the mainnet vault
        _hypERC20.transferRemote{ value: valueToSend }(DESTINATION_ENDPOINT_ID, _addressToBytes32(_vault), amount);

        // refund user if excess native token sent
        _refundExcessNativeTokenSent(msg.sender, msg.value, valueToSend);

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return amount;
    }

    /**
     * @notice sets the withdraw token
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setWithdrawToken(
        Token newWithdrawToken
    ) external override onlyAdmin validAddress(Token.unwrap(newWithdrawToken)) {
        _setWithdrawToken(newWithdrawToken);
        // set the hyperlane ERC20 token (always equal to _withdrawToken)
        _hypERC20 = IHypERC20(Token.unwrap(newWithdrawToken));
    }

    /**
     * @dev converts an address to bytes32
     */
    function _addressToBytes32(address _addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
