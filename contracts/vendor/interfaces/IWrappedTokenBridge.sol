// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { LzLib } from "@layerzerolabs/solidity-examples/contracts/lzApp/libs/LzLib.sol";

interface IWrappedTokenBridge {
    event WrapToken(
        address indexed localToken,
        address indexed remoteToken,
        uint16 remoteChainId,
        address indexed to,
        uint256 amount
    );
    event UnwrapToken(
        address indexed localToken,
        address indexed remoteToken,
        uint16 remoteChainId,
        address indexed to,
        uint256 amount
    );
    event RegisterToken(address indexed localToken, uint16 remoteChainId, address indexed remoteToken);
    event SetWithdrawalFeeBps(uint16 withdrawalFeeBps);

    /// @notice Total bps representing 100%
    // solhint-disable-next-line func-name-mixedcase
    function TOTAL_BPS() external view returns (uint16);
    /// @notice An optional fee charged on withdrawal, expressed in bps. E.g., 1bps = 0.01%
    function withdrawalFeeBps() external view returns (uint16);
    function registerToken(address localToken, uint16 remoteChainId, address remoteToken) external;
    function setWithdrawalFeeBps(uint16 _withdrawalFeeBps) external;
    function estimateBridgeFee(
        uint16 remoteChainId,
        bool useZro,
        bytes calldata adapterParams
    ) external pure returns (uint256 nativeFee, uint256 zroFee);
    function bridge(
        address localToken,
        uint16 remoteChainId,
        uint256 amount,
        address to,
        bool unwrapWeth,
        LzLib.CallParams calldata callParams,
        bytes calldata adapterParams
    ) external payable;
}
