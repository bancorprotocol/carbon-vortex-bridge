// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Token } from "../token/Token.sol";

/**
 * @dev mock OP-stack L2StandardBridge predeploy for unit tests.
 *
 * Records the last `bridgeERC20To` call (for assertions) and simulates the canonical 1:1
 * withdrawal by transferring the local token straight from the caller (the vortex bridge) to the
 * L1 recipient. On a real OP-stack chain the L2 token is burned and the L1 token is released only
 * after an off-chain prove + finalize; a same-token 1:1 transfer is sufficient for unit tests.
 */
contract MockL2StandardBridge {
    address public lastLocalToken;
    address public lastRemoteToken;
    address public lastTo;
    uint256 public lastAmount;
    uint32 public lastMinGasLimit;

    function bridgeERC20To(
        address _localToken,
        address _remoteToken,
        address _to,
        uint256 _amount,
        uint32 _minGasLimit,
        bytes calldata
    ) external {
        lastLocalToken = _localToken;
        lastRemoteToken = _remoteToken;
        lastTo = _to;
        lastAmount = _amount;
        lastMinGasLimit = _minGasLimit;

        // pull the local token from the caller and deliver it 1:1 to the L1 recipient
        Token.wrap(_localToken).safeTransferFrom(msg.sender, _to, _amount);
    }
}
