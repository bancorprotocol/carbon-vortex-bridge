// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Token } from "../token/Token.sol";

/**
 * @notice CarbonVortex interface
 */
interface ICarbonVortex {
    /**
     * @dev withdraws funds held by the contract and sends them to an account
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function withdrawFunds(Token[] calldata tokens, address payable target, uint256[] calldata amounts) external;
}
