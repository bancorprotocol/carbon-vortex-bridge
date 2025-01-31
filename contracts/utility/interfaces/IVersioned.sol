// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @dev an interface for a versioned contract
 */
interface IVersioned {
    /**
     * @notice returns the version of the contract
     */
    function version() external view returns (uint16);
}
