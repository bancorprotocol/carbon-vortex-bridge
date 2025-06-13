// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Token } from "../token/Token.sol";
import { Utils } from "../utility/Utils.sol";

import { IWETH } from "../interfaces/IWETH.sol";

/**
 * @dev mock wormhole token bridge
 */
contract MockWormholeBridge is Utils {
    error InsufficientFeePaid();
    error InvalidBytesLength();

    uint256 private constant NATIVE_TOKEN_FEE = 1000; // native token fee

    address private _token; // bridge token address

    address private _recipient; // recipient address for a transfer token call

    uint256 private _amount; // amount for a transfer token call

    struct BridgeData {
        address token;
        uint256 amount;
        address recipient;
    }

    BridgeData private _bridgeData; // data for a given transfer tokens call

    constructor(address tokenInit) {
        _token = tokenInit;
    }

    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}

    /// @dev estimate native token fee
    function messageFee() public pure returns (uint256) {
        return NATIVE_TOKEN_FEE;
    }

    /**
     * @dev main token bridge function
     * @dev initiates a token bridge tx
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 /* recipientChain */,
        bytes32 recipient,
        uint256 /*arbiterFee, */,
        uint32 /* nonce */
    ) external payable returns (uint64 sequence) {
        if (msg.value < messageFee()) {
            revert InsufficientFeePaid();
        }

        _bridgeData = BridgeData({ token: token, amount: amount, recipient: _bytes32ToAddress(recipient) });

        // transfer tokens from user to the bridge
        Token.wrap(token).safeTransferFrom(msg.sender, address(this), amount);

        return sequence;
    }

    /**
     * @dev finalize a token bridge tx -
     * @dev transfer to the recipient on the destination chain and unwraps eth
     */
    function completeTransferAndUnwrapETH(bytes calldata /* encodedVaa */) external {
        BridgeData memory bridgeData = _bridgeData;
        address token = bridgeData.token;
        uint256 amount = bridgeData.amount;
        address recipient = bridgeData.recipient;

        // unwrap eth
        IWETH(token).withdraw(amount);

        // send native token
        payable(recipient).transfer(amount);
    }

    function fee() public pure returns (uint256) {
        return NATIVE_TOKEN_FEE;
    }

    function getToken() external view returns (address) {
        return _token;
    }

    function setToken(address newToken) external {
        _token = newToken;
    }

    /**
     * @dev Converts bytes32 to an address
     */
    function _bytes32ToAddress(bytes32 _bytes32) private pure returns (address) {
        return address(uint160(uint256(_bytes32)));
    }
}
