// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { IOFTWrapper } from "../interfaces/IOFTWrapper.sol";
import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";

/**
 * @dev VortexFantomBridge contract
 */
contract VortexFantomBridge is VortexBridgeBase {
    // mainnet layerzero endpoint id
    uint16 private constant MAINNET_ENDPOINT_ID = 101;

    IOFTWrapper private immutable _oftWrapper; // layer zero oft wrapper

    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(
        ICarbonVortex vortexInit,
        IOFTWrapper oftWrapperInit,
        address vaultInit
    ) validAddress(address(oftWrapperInit)) VortexBridgeBase(vortexInit, vaultInit) {
        _oftWrapper = oftWrapperInit;

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
        // if amount == 0, there is no balance in the vortex
        if (amount == 0) {
            return 0;
        }
        // min amount to receive
        uint256 minAmount = _estimateMinAmountToReceive(amount);

        // get amount received quote
        (uint256 amountReceived, , ) = _oftWrapper.getAmountAndFees(Token.unwrap(_withdrawToken), amount, 0);

        // validate sufficient amount received
        _validateAmountReceived(amountReceived, minAmount);

        // calculate the value to send with the tx
        IOFTWrapper.FeeObj memory feeObj = IOFTWrapper.FeeObj({ callerBps: 0, caller: address(0), partnerId: "" });
        (uint256 nativeFee, ) = _oftWrapper.estimateSendFee(
            Token.unwrap(_withdrawToken),
            MAINNET_ENDPOINT_ID,
            _addressToBytes(_vault),
            amount,
            false,
            "",
            feeObj
        );
        uint256 valueToSend = nativeFee;

        // validate sufficient native token sent
        _validateSufficientNativeTokenSent(msg.value, valueToSend);

        // approve token if not approved
        _setPlatformAllowance(_withdrawToken, address(_oftWrapper), amount);

        // bridge the token to the mainnet vault
        _oftWrapper.sendOFT{ value: valueToSend }(
            Token.unwrap(_withdrawToken),
            MAINNET_ENDPOINT_ID,
            _addressToBytes(_vault),
            amount,
            minAmount,
            payable(msg.sender),
            address(0),
            "",
            feeObj
        );

        // refund user if excess native token sent
        _refundExcessNativeTokenSent(msg.sender, msg.value, nativeFee);

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return amountReceived;
    }

    /**
     * @dev Converts an address to bytes memory.
     */
    function _addressToBytes(address _addr) private pure returns (bytes memory) {
        return abi.encodePacked(_addr);
    }
}
