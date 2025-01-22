// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { Token } from "../token/Token.sol";

import { Utils } from "../utility/Utils.sol";

/**
 * @dev mock carbon vortex contract
 */
contract MockCarbonVortex is Utils {
    error InvalidAmountLength();

    /**
     * @notice triggered when tokens have been withdrawn by the admin
     */
    event FundsWithdrawn(Token[] indexed tokens, address indexed caller, address indexed target, uint256[] amounts);

    /**
     * @dev withdraws funds held by the contract and sends them to an account
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function withdrawFunds(
        Token[] calldata tokens,
        address payable target,
        uint256[] calldata amounts
    ) external validAddress(target) {
        uint256 len = tokens.length;
        if (len != amounts.length) {
            revert InvalidAmountLength();
        }
        for (uint256 i = 0; i < len; i = ++i) {
            // safe due to nonReentrant modifier (forwards all available gas in case of ETH)
            tokens[i].unsafeTransfer(target, amounts[i]);
        }

        emit FundsWithdrawn({ tokens: tokens, caller: msg.sender, target: target, amounts: amounts });
    }
}
