// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { VortexOpStackBridge } from "../contracts/bridge/VortexOpStackBridge.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexOpStackBridgeTest is Fixture {
    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    function setUp() public virtual {
        setupVortexOpStackBridge();
    }

    function testVersion() public view {
        assertGt(vortexOpStackBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly (canonical bridge is 1:1)
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexOpStackBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        uint256 bridged = vortexOpStackBridge.bridge(amount);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // 1:1, no in-bridge slippage
        assertEq(bridged, amount);
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        assertEq(withdrawToken.balanceOf(address(vault)), amount);
    }

    /// @dev test the L2 standard bridge is invoked with the expected arguments
    function testBridgeCallsL2StandardBridgeWithExpectedArgs() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexOpStackBridge.withdrawToken();
        vortexOpStackBridge.bridge(AMOUNT);

        assertEq(l2StandardBridge.lastLocalToken(), Token.unwrap(withdrawToken));
        assertEq(l2StandardBridge.lastRemoteToken(), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // mainnet WETH (hardcoded)
        assertEq(l2StandardBridge.lastTo(), address(vault));
        assertEq(l2StandardBridge.lastAmount(), AMOUNT);
        assertEq(l2StandardBridge.lastMinGasLimit(), 200_000);
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexOpStackBridge.withdrawToken();
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, amount);
        vortexOpStackBridge.bridge(amount);
    }

    /// @dev test that bridging zero amount transfers the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexOpStackBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        vortexOpStackBridge.bridge(0);

        assertEq(withdrawToken.balanceOf(address(vortex)), 0);
        assertEq(withdrawToken.balanceOf(address(vault)), vortexBalanceBefore);
    }

    /// @dev test attempting to bridge with an empty vortex returns zero
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        // drain the vortex
        vortexOpStackBridge.bridge(0);
        assertEq(vortexOpStackBridge.withdrawToken().balanceOf(address(vortex)), 0);

        // bridging again returns zero
        uint256 amount = vortexOpStackBridge.bridge(0);
        assertEq(amount, 0);
    }

    /// @dev test that bridging an empty vortex emits no event
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        vortexOpStackBridge.bridge(0);

        vm.recordLogs();
        vortexOpStackBridge.bridge(0);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    /// @dev test attempting to bridge more than the vortex balance bridges the available balance
    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexOpStackBridge.withdrawToken();
        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        uint256 bridged = vortexOpStackBridge.bridge(vortexBalance + 1);

        assertEq(bridged, vortexBalance);
        assertEq(withdrawToken.balanceOf(address(vault)), vortexBalance);
    }

    /// @dev test should revert if attempting to send native token with the bridge function
    function testShouldRevertIfAttemptingToSendNativeTokenWithBridgeFunction() public {
        vm.prank(user1);
        vm.expectRevert(VortexOpStackBridge.UnnecessaryNativeTokenSent.selector);
        vortexOpStackBridge.bridge{ value: 1 }(0);
    }

    /// @dev test should revert if the withdraw token is the native token (unsupported by the OP-stack bridge)
    function testShouldRevertIfWithdrawTokenIsNative() public {
        vm.prank(admin);
        vortexOpStackBridge.setWithdrawToken(NATIVE_TOKEN);

        vm.prank(user1);
        vm.expectRevert(VortexOpStackBridge.NativeWithdrawTokenNotSupported.selector);
        vortexOpStackBridge.bridge(AMOUNT);
    }
}
