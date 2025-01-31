// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { LzLib } from "@layerzerolabs/solidity-examples/contracts/lzApp/libs/LzLib.sol";

import { Token } from "../token/Token.sol";
import { Utils } from "../utility/Utils.sol";
import { IWETH } from "../interfaces/IWETH.sol";

/**
 * @dev mock layerzero v2 wrapped asset bridge
 */
contract MockLayerZeroBridge is Utils {
    error InsufficientFeePaid();
    error SlippageTooHigh();
    error InvalidBytesLength();
    error InvalidToken();
    error InvalidTo();
    error InvalidAmount();

    uint256 private constant NATIVE_TOKEN_FEE = 1000; // native token fee

    /// @notice Total bps representing 100%
    uint16 public constant TOTAL_BPS = 10000;

    /// @notice An optional fee charged on withdrawal, expressed in bps. E.g., 1bps = 0.01%
    uint16 public withdrawalFeeBps;

    uint32 private _slippagePPM; // bridge slippage ppm

    address private _token; // bridge token address

    constructor(address tokenInit, uint32 slippagePPMInit) {
        _token = tokenInit;
        _slippagePPM = slippagePPMInit;
        withdrawalFeeBps = uint16(slippagePPMInit / 100);
    }

    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}

    function estimateBridgeFee(
        uint16 /* remoteChainId */,
        bool /* useZro */,
        bytes calldata /* adapterParams */
    ) external pure returns (uint256 nativeFee, uint256 zroFee) {
        return (NATIVE_TOKEN_FEE, 0);
    }

    /// @notice Bridges `localToken` to the remote chain
    /// @dev Burns wrapped tokens and sends LZ message to the remote chain to unlock original tokens
    function bridge(
        address localToken,
        uint16, // remoteChainId,
        uint256 amount,
        address to,
        bool unwrapWeth,
        LzLib.CallParams calldata callParams,
        bytes memory // adapterParams
    ) external payable {
        if (localToken == address(0)) {
            revert InvalidToken();
        }
        if (to == address(0)) {
            revert InvalidTo();
        }
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (msg.value < fee()) {
            revert InsufficientFeePaid();
        }

        (uint256 amountToSend, ) = _calculateFeeAndAmount(amount);

        if (unwrapWeth) {
            // transfer token to this contract
            Token.wrap(localToken).safeTransferFrom(msg.sender, address(this), amountToSend);
            // unwrap weth
            IWETH(localToken).withdraw(amountToSend);
            // send native token
            payable(to).transfer(amountToSend);
        } else {
            Token.wrap(localToken).safeTransferFrom(msg.sender, to, amountToSend);
        }

        // refund any excess native token sent
        if (msg.value > fee()) {
            payable(callParams.refundAddress).transfer(msg.value - fee());
        }
    }

    /// @dev calculate output amount and fee based on input amount
    function _calculateFeeAndAmount(uint256 amount) private view returns (uint256, uint256) {
        uint256 _fee = (amount * withdrawalFeeBps) / TOTAL_BPS;
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
        withdrawalFeeBps = uint16(newSlippagePPM / 100);
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
