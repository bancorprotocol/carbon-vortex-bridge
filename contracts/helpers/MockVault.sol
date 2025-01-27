// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

/**
 * @dev mock vault contract
 */
contract MockVault {
    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}
}
