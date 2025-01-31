// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Token } from "../token/Token.sol";
import { Utils } from "../utility/Utils.sol";

import { PPM_RESOLUTION } from "../utility/Utils.sol";

import { IOFTWrapper } from "../interfaces/IOFTWrapper.sol";

/**
 * @dev mock layerzero oft wrapper
 */
contract MockOFTWrapper is Utils {
    error InsufficientFeePaid();
    error SlippageTooHigh();
    error InvalidBytesLength();

    uint256 private constant NATIVE_TOKEN_FEE = 1000; // native token fee

    uint32 private _slippagePPM; // bridge slippage ppm

    address private _token; // bridge token address

    constructor(address tokenInit, uint32 slippagePPMInit) {
        _token = tokenInit;
        _slippagePPM = slippagePPMInit;
    }

    function getAmountAndFees(
        address, //_token, // will be the token on proxies, and the oft on non-proxy
        uint256 _amount,
        uint256 //_callerBps
    ) public view returns (uint256 amount, uint256 wrapperFee, uint256 callerFee) {
        (uint256 amountReceived, uint256 _fee) = _calculateFeeAndAmount(_amount);
        return (amountReceived, _fee, 0);
    }

    /// @dev estimate native token fee
    function estimateSendFee(
        address, //_oft,
        uint16, // _dstChainId,
        bytes calldata, // _toAddress,
        uint256, //_amount,
        bool, // _useZro,
        bytes calldata, //_adapterParams,
        IOFTWrapper.FeeObj calldata //_feeObj
    ) public pure returns (uint256 nativeFee, uint256 zroFee) {
        return (NATIVE_TOKEN_FEE, 0);
    }

    function sendOFT(
        address _oft,
        uint16, // _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        address payable _refundAddress,
        address, // _zroPaymentAddress,
        bytes calldata, // _adapterParams,
        IOFTWrapper.FeeObj calldata // _feeObj
    ) external payable {
        if (msg.value < fee()) {
            revert InsufficientFeePaid();
        }
        (uint256 amountToSend, ) = _calculateFeeAndAmount(_amount);
        if (amountToSend < _minAmount) {
            revert SlippageTooHigh();
        }

        // transfer tokens
        Token.wrap(_oft).safeTransfer(_bytesToAddress(_toAddress), amountToSend);

        // refund any excess native token fee
        if (msg.value > fee()) {
            payable(_refundAddress).transfer(msg.value - fee());
        }
    }

    /// @dev calculate output amount and fee based on input amount
    function _calculateFeeAndAmount(uint256 amount) private view returns (uint256, uint256) {
        uint256 _fee = (amount * _slippagePPM) / PPM_RESOLUTION;
        uint256 amountToSend = amount - _fee;
        return (amountToSend, _fee);
    }

    function fee() public pure returns (uint256) {
        return NATIVE_TOKEN_FEE;
    }

    function token() external view returns (address) {
        return _token;
    }

    function slippagePPM() external view returns (uint32) {
        return _slippagePPM;
    }

    function setToken(address newToken) external {
        _token = newToken;
    }

    function setSlippagePPM(uint32 newSlippagePPM) external {
        _slippagePPM = newSlippagePPM;
    }

    /**
     * @dev Converts bytes memory to an address.
     */
    function _bytesToAddress(bytes memory _bytes) private pure returns (address) {
        if (_bytes.length != 20) {
            revert InvalidBytesLength();
        }
        address addr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(_bytes, 20))
        }
        return addr;
    }
}
