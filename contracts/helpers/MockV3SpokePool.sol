// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { Token } from "../token/Token.sol";
import { Utils } from "../utility/Utils.sol";
import { IWETH } from "../interfaces/IWETH.sol";

/**
 * @dev mock across v3 spoke pool contract
 */
contract MockV3SpokePool is Utils {
    error MsgValueDoesNotMatchInputAmount();
    error InvalidDestinationChainId();

    uint256 private constant NATIVE_TOKEN_FEE = 1000; // native token fee

    uint256 private constant MAINNET_CHAIN_ID = 1; // mainnet chain id

    IWETH private _wrappedNativeToken;

    uint32 private _slippagePPM; // bridge slippage ppm

    constructor(address wrappedNativeTokenInit, uint32 slippagePPMInit) {
        _wrappedNativeToken = IWETH(wrappedNativeTokenInit);
        _slippagePPM = slippagePPMInit;
    }

    /**
     * @notice Submits deposit and sets quoteTimestamp to current Time. Sets fill and exclusivity
     * deadlines as offsets added to the current time. This function is designed to be called by users
     * such as Multisig contracts who do not have certainty when their transaction will mine.
     *
     * @notice on receiving ETH: EOA recipients will always receive ETH while contracts will always receive WETH,
     * regardless of whether ETH or WETH is deposited.
     * Must be an ERC20. Note, this can be set to the zero address (0x0) in which case,
     * fillers will replace this with the destination chain equivalent of the input token.
     *
     * @param recipient The account receiving funds on the destination chain. Can be an EOA or a contract. If
     * the output token is the wrapped native token for the chain, then the recipient will receive native token if
     * an EOA or wrapped native token if a contract.
     * @param inputToken The token pulled from the caller's account and locked into this contract to
     * initiate the deposit. The equivalent of this token on the relayer's repayment chain of choice will be sent
     * as a refund. If this is equal to the wrapped native token then the caller can optionally pass in native token as
     * msg.value, as long as msg.value = inputTokenAmount.
     * @param outputToken The token that the relayer will send to the recipient on the destination chain. Must be an
     * ERC20.
     * @param inputAmount The amount of input tokens to pull from the caller's account and lock into this contract.
     * This amount will be sent to the relayer on their repayment chain of choice as a refund following an optimistic
     * challenge window in the HubPool, plus a system fee.
     * @param outputAmount The amount of output tokens that the relayer will send to the recipient on the destination.
     * @param destinationChainId The destination chain identifier. Must be enabled along with the input token
     * as a valid deposit route from this spoke pool or this transaction will revert.
     */
    function depositV3Now(
        address, //depositor,
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 destinationChainId,
        address, //exclusiveRelayer,
        uint32, //fillDeadlineOffset,
        uint32, //exclusivityDeadline,
        bytes calldata // message
    ) external payable {
        // mock only ethereum chain support
        if (destinationChainId != MAINNET_CHAIN_ID) {
            revert InvalidDestinationChainId();
        }

        // If the address of the origin token is a wrappedNativeToken contract and there is a msg.value with the
        // transaction then the user is sending the native token. In this case, the native token should be
        // wrapped.
        if (inputToken == address(_wrappedNativeToken) && msg.value > 0) {
            if (msg.value != inputAmount) {
                revert MsgValueDoesNotMatchInputAmount();
            }
            _wrappedNativeToken.deposit{ value: msg.value }();
            // Else, it is a normal ERC20. In this case pull the token from the caller as per normal.
            // Note: this includes the case where the L2 caller has WETH (already wrapped ETH) and wants to bridge them.
            // In this case the msg.value will be set to 0, indicating a "normal" ERC20 bridging action.
        } else {
            // msg.value should be 0 if input token isn't the wrapped native token.
            if (msg.value != 0) {
                revert MsgValueDoesNotMatchInputAmount();
            }
            // transfer the inputAmount of the token from the caller to this contract
            Token.wrap(inputToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        }
        // if output token is address(0), fillers will replace this with
        // the destination chain equivalent of the input token
        Token transferToken = outputToken == address(0) ? Token.wrap(inputToken) : Token.wrap(outputToken);
        // transfer the outputAmount of the token to the recipient
        transferToken.safeTransfer(recipient, outputAmount);
    }

    function fee() external pure returns (uint256) {
        return NATIVE_TOKEN_FEE;
    }
}
