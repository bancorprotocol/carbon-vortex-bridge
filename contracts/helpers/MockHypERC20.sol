// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Utils } from "../utility/Utils.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev mock hyperlane erc20 token
 */
contract MockHypERC20 is ERC20, Utils {
    error InsufficientNativeTokenSent();

    uint256 private constant NATIVE_TOKEN_FEE = 1000; // native token fee

    constructor() ERC20("MockHyperlaneERC20", "MHERC20") {
        _mint(msg.sender, 100_000_000 ether); // mint tokens to the deployer
    }

    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}

    /**
     * @notice Returns the gas payment required to dispatch a message to the given domain's router.
     * @return _gasPayment Payment computed by the registered InterchainGasPaymaster.
     */
    function quoteGasPayment(uint32 /* _destinationDomain */) external pure returns (uint256) {
        return NATIVE_TOKEN_FEE;
    }

    /**
     * @notice Transfers `_amountOrId` token to `_recipient` on `_destination` domain.
     * @dev Delegates transfer logic to `_transferFromSender` implementation.
     * @dev Emits `SentTransferRemote` event on the origin chain.
     * @param _recipient The address of the recipient on the destination chain.
     * @param _amountOrId The amount or identifier of tokens to be sent to the remote recipient.
     * @return messageId The identifier of the dispatched message.
     */
    function transferRemote(
        uint32 /* _destination */,
        bytes32 _recipient,
        uint256 _amountOrId
    ) external payable returns (bytes32 messageId) {
        // validate sufficient native token sent
        _validateSufficientNativeTokenSent(msg.value, NATIVE_TOKEN_FEE);

        // transfer the token to the recipient using the internal erc-20 transfer function
        _transfer(msg.sender, _bytes32ToAddress(_recipient), _amountOrId);

        // return a dummy message id
        return bytes32(0);
    }

    /**
     * @dev validates that the native token sent is sufficient
     */
    function _validateSufficientNativeTokenSent(uint256 txValue, uint256 requiredValue) internal pure {
        if (txValue < requiredValue) {
            revert InsufficientNativeTokenSent();
        }
    }

    /**
     * @dev Converts bytes32 to an address
     */
    function _bytes32ToAddress(bytes32 _bytes32) private pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}
