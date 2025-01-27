// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { VortexBridgeBase } from "../bridge/VortexBridgeBase.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";

contract TestVortexBridgeBase is VortexBridgeBase {
    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(ICarbonVortex vortexInit, address vaultInit) validAddress(address(vortexInit)) validAddress(vaultInit) {
        _vortex = vortexInit;
        _vault = vaultInit;

        _disableInitializers();
    }

    function version() public pure override returns (uint16) {
        return 1;
    }

    function withdrawVortex(uint256 amount) public returns (uint256) {
        return _withdrawVortex(amount);
    }

    function bridge(uint256 amount) external payable override returns (uint256) {
        // do nothing
    }
}
