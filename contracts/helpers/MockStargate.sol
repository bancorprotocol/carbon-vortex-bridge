// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { SendParam, MessagingFee, OFTReceipt, OFTLimit, OFTFeeDetail, MessagingReceipt } from "../vendor/interfaces/IOFT.sol";

import { Token, NATIVE_TOKEN } from "../token/Token.sol";
import { Utils } from "../utility/Utils.sol";
import { Ticket } from "../vendor/interfaces/IStargate.sol";

import { PPM_RESOLUTION } from "../utility/Utils.sol";
/**
 * @dev mock stargate pool / OFT contract
 */
contract MockStargate is Utils {
    error Stargate_InsufficientFeePaid();
    error Stargate_SlippageTooHigh();
    error Stargate_InvalidAmount();

    uint256 private constant NATIVE_TOKEN_FEE = 1000; // native token fee

    uint32 private _slippagePPM; // bridge slippage ppm

    address private _token; // bridge token address

    constructor(address tokenInit, uint32 slippagePPMInit) {
        _token = tokenInit;
        _slippagePPM = slippagePPMInit;
    }

    /// @notice Provides a quote for sending OFT to another chain.
    /// @dev Implements the IOFT interface
    /// @param _sendParam The parameters for the send operation
    /// @return limit The information on OFT transfer limits
    /// @return oftFeeDetails The details of OFT transaction cost or reward
    /// @return receipt The OFT receipt information, indicating how many tokens would be sent and received
    function quoteOFT(
        SendParam calldata _sendParam
    ) external view returns (OFTLimit memory limit, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory receipt) {
        uint256 amount = _sendParam.amountLD;
        uint256 minAmount = amount - (amount * _slippagePPM) / PPM_RESOLUTION;
        limit = OFTLimit({ minAmountLD: minAmount, maxAmountLD: amount });
        oftFeeDetails = new OFTFeeDetail[](1);
        oftFeeDetails[0] = OFTFeeDetail({ feeAmountLD: int256(NATIVE_TOKEN_FEE), description: "" });
        receipt = OFTReceipt({ amountSentLD: amount, amountReceivedLD: minAmount });
        return (limit, oftFeeDetails, receipt);
    }

    /// @notice Provides a quote for the send() operation.
    /// @dev Implements the IOFT interface.
    /// @dev Reverts with InvalidAmount if send mode is drive but value is specified.
    /// @param _sendParam The parameters for the send() operation
    /// @return _fee The calculated LayerZero messaging fee from the send() operation
    /// @dev MessagingFee: LayerZero message fee
    ///   - nativeFee: The native fee.
    ///   - lzTokenFee: The LZ token fee.
    function quoteSend(
        SendParam calldata _sendParam,
        bool //_payInLzToken
    ) external pure returns (MessagingFee memory _fee) {
        if (_sendParam.amountLD == 0) revert Stargate_InvalidAmount();

        return MessagingFee({ nativeFee: NATIVE_TOKEN_FEE, lzTokenFee: 0 });
    }

    /// @dev This function is same as `send` in OFT interface but returns the ticket data if in the bus ride mode,
    /// which allows the caller to ride and drive the bus in the same transaction.
    function sendToken(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) public payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket) {
        if (msg.value < _fee.nativeFee) {
            revert Stargate_InsufficientFeePaid();
        }
        uint256 amountToSend = _sendParam.amountLD - (_sendParam.amountLD * _slippagePPM) / PPM_RESOLUTION;
        if (amountToSend < _sendParam.minAmountLD) {
            revert Stargate_SlippageTooHigh();
        }
        uint256 feeSent;
        // stargate treats address(0) as the native token
        if (_token == address(0)) {
            NATIVE_TOKEN.unsafeTransfer(bytes32ToAddress(_sendParam.to), amountToSend);
            feeSent = msg.value - _sendParam.amountLD;
        } else {
            Token.wrap(_token).safeTransferFrom(msg.sender, bytes32ToAddress(_sendParam.to), amountToSend);
            feeSent = msg.value;
        }

        // refund any excess native token fee
        if (feeSent > _fee.nativeFee) {
            payable(_refundAddress).transfer(feeSent - _fee.nativeFee);
        }

        msgReceipt = MessagingReceipt({
            guid: 0,
            nonce: 0,
            fee: MessagingFee({ nativeFee: _fee.nativeFee, lzTokenFee: _fee.lzTokenFee })
        });

        oftReceipt = OFTReceipt({ amountSentLD: amountToSend, amountReceivedLD: amountToSend });

        ticket = Ticket({ ticketId: 0, passengerBytes: "" });

        return (msgReceipt, oftReceipt, ticket);
    }

    function token() external view returns (address) {
        return _token;
    }

    function slippagePPM() external view returns (uint32) {
        return _slippagePPM;
    }

    function fee() external pure returns (uint256) {
        return NATIVE_TOKEN_FEE;
    }

    function setToken(address newToken) external {
        _token = newToken;
    }

    function setSlippagePPM(uint32 newSlippagePPM) external {
        _slippagePPM = newSlippagePPM;
    }

    /**
     * @dev converts an bytes32 to address
     */
    function bytes32ToAddress(bytes32 _addr) private pure returns (address) {
        return address(uint160(uint256(_addr)));
    }
}
