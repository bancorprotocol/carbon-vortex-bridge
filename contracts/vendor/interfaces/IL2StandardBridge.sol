// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev minimal interface for the OP-stack L2StandardBridge predeploy (0x4200000000000000000000000000000000000010).
 * Only the function used by VortexOpStackBridge is declared.
 */
interface IL2StandardBridge {
    /**
     * @notice Initiates an ERC20 withdrawal from L2 to a target account on L1. The L2 representation
     * is burned; the corresponding L1 token is released to `_to` once the withdrawal is proven and
     * finalized on the L1 OptimismPortal.
     *
     * @param _localToken  Address of the L2 token (OptimismMintableERC20) being withdrawn.
     * @param _remoteToken Address of the corresponding token on L1 (must match the local token's remoteToken).
     * @param _to          Recipient of the tokens on L1.
     * @param _amount      Amount of the local token to withdraw.
     * @param _minGasLimit Minimum gas limit for the L1 finalization (relayMessage) execution.
     * @param _extraData   Optional data forwarded to L1 (unused here).
     */
    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata _extraData
    ) external;
}
