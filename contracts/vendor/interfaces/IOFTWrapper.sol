// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IOFTV2 } from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";

/**
 * @dev taken from:
 * @dev https://github.com/LayerZero-Labs/oft-wrapper/blob/main/contracts/interfaces/IOFTWrapper.sol
 */
interface IOFTWrapper {
    event WrapperFees(bytes2 indexed partnerId, address token, uint256 wrapperFee, uint256 callerFee);
    event WrapperFeeWithdrawn(address indexed oft, address to, uint256 amount);

    struct FeeObj {
        uint256 callerBps;
        address caller;
        bytes2 partnerId;
    }

    function sendOFT(
        address _oft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendProxyOFT(
        address _proxyOft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendNativeOFT(
        address _nativeOft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendOFTV2(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendOFTFeeV2(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendProxyOFTV2(
        address _proxyOft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendProxyOFTFeeV2(
        address _proxyOft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable;

    function sendNativeOFTFeeV2(
        address _nativeOft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable;

    function getAmountAndFees(
        address _oft,
        uint256 _amount,
        uint256 _callerBps
    ) external view returns (uint256 amount, uint256 wrapperFee, uint256 callerFee);

    function estimateSendFee(
        address _oft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function estimateSendFeeV2(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}
