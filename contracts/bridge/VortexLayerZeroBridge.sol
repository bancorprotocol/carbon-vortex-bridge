// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { LzLib } from "@layerzerolabs/solidity-examples/contracts/lzApp/libs/LzLib.sol";

import { IWrappedTokenBridge } from "../interfaces/IWrappedTokenBridge.sol";
import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { MathEx } from "../utility/MathEx.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";

/**
 * @dev VortexLayerZeroBridge contract
 */
contract VortexLayerZeroBridge is VortexBridgeBase {
    // mainnet layerzero v2 destination endpoint id
    uint16 private constant DESTINATION_ENDPOINT_ID = 30101;

    // tx type (1) and gas limit for ethereum transfer (125k gas) encoded as bytes
    bytes private constant ADAPTER_PARAMS = hex"0001000000000000000000000000000000000000000000000000000000000001e848";

    // layer zero wrapped token bridge
    IWrappedTokenBridge private immutable _wrappedTokenBridge;

    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(
        ICarbonVortex vortexInit,
        IWrappedTokenBridge wrappedTokenBridge,
        address vaultInit
    ) validAddress(address(wrappedTokenBridge)) VortexBridgeBase(vortexInit, vaultInit) {
        _wrappedTokenBridge = wrappedTokenBridge;

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

        // estimate amount to receive on mainnet
        uint256 amountReceived = _estimateAmountToReceive(amount);

        // validate sufficient amount received
        _validateAmountReceived(amountReceived, minAmount);

        // calculate the value to send with the tx
        (uint256 nativeFee, ) = _wrappedTokenBridge.estimateBridgeFee(DESTINATION_ENDPOINT_ID, false, ADAPTER_PARAMS);
        uint256 valueToSend = nativeFee;

        // validate sufficient native token sent
        _validateSufficientNativeTokenSent(msg.value, valueToSend);

        // approve token if not approved
        _setPlatformAllowance(_withdrawToken, address(_wrappedTokenBridge), amount);

        LzLib.CallParams memory callParams = LzLib.CallParams({
            refundAddress: payable(msg.sender),
            zroPaymentAddress: address(0)
        });

        // bridge the token to the mainnet vault
        _wrappedTokenBridge.bridge{ value: valueToSend }(
            Token.unwrap(_withdrawToken),
            DESTINATION_ENDPOINT_ID,
            amount,
            _vault,
            true, // unwrap weth on mainnet
            callParams,
            ADAPTER_PARAMS // gas limit for ethereum transfer
        );

        // refund user if excess native token sent
        _refundExcessNativeTokenSent(msg.sender, msg.value, nativeFee);

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return amount;
    }

    /**
     * @dev estimate bridge output amount
     */
    function _estimateAmountToReceive(uint256 amount) private view returns (uint256) {
        // get withdrawal fee in wrapped token
        uint256 feeBps = _wrappedTokenBridge.withdrawalFeeBps();
        // calculate fee amount
        uint256 fee = MathEx.mulDivF(amount, feeBps, _wrappedTokenBridge.TOTAL_BPS());
        // calculate amount to receive
        return amount - fee;
    }
}
