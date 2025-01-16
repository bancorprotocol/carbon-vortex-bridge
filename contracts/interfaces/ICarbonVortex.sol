// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { Token } from "../token/Token.sol";

/**
 * @notice CarbonVortex interface
 */
interface ICarbonVortex {
    function withdrawFunds(Token[] calldata tokens, address payable target, uint256[] calldata amounts) external;
}
