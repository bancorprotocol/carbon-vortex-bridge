// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { VortexBridgeBase } from "../contracts/bridge/VortexBridgeBase.sol";

import { PPM_RESOLUTION } from "../contracts/utility/Utils.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexFantomBridgeTest is Fixture {
    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    function setUp() public virtual {
        setupVortexFantomBridge();
    }

    function testVersion() public view {
        assertGt(vortexFantomBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexFantomBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        // bridge the tokens
        vortexFantomBridge.bridge{ value: oftWrapper.fee() }(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        assertEq(withdrawToken.balanceOf(address(vault)), getAmountOut(amount));
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 oftWrapperFee = oftWrapper.fee();
        Token withdrawToken = vortexFantomBridge.withdrawToken();
        // bridge the tokens
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, amount);
        vortexFantomBridge.bridge{ value: oftWrapperFee }(amount);
    }

    /// @dev test native token refunds work correctly
    function testBridgingNativeTokenRefundsCorrectly() public {
        vm.startPrank(user1);

        uint256 oftWrapperFee = oftWrapper.fee();
        uint256 userBalanceBefore = NATIVE_TOKEN.balanceOf(user1);

        // send twice the oftWrapper fee
        vortexFantomBridge.bridge{ value: oftWrapperFee * 2 }(AMOUNT);

        uint256 userBalanceAfter = NATIVE_TOKEN.balanceOf(user1);

        // check that the user received a refund of oftWrapperFee
        assertEq(userBalanceAfter, userBalanceBefore - oftWrapperFee);
    }

    /// @dev test that bridging zero amount will transfer the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexFantomBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        // bridge with 0 amount
        vortexFantomBridge.bridge{ value: oftWrapper.fee() }(0);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // assert vortex withdraw token balance is zero
        assertEq(vortexBalanceAfter, 0);
        // assert vault balance is equal to the vortex balance before
        assertEq(withdrawToken.balanceOf(address(vault)), getAmountOut(vortexBalanceBefore));
    }

    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexFantomBridge.withdrawToken();
        uint256 oftWrapperFee = oftWrapper.fee();

        // bridge entire balance so vortex is empty
        vortexFantomBridge.bridge{ value: oftWrapperFee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // try to bridge again
        uint256 amount = vortexFantomBridge.bridge{ value: oftWrapperFee }(0);
        assertEq(amount, 0);
    }

    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexFantomBridge.withdrawToken();
        uint256 oftWrapperFee = oftWrapper.fee();

        // bridge entire balance so vortex is empty
        vortexFantomBridge.bridge{ value: oftWrapperFee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // record tx logs
        vm.recordLogs();

        // try to bridge again
        vortexFantomBridge.bridge{ value: oftWrapperFee }(0);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexFantomBridge.withdrawToken();
        uint256 oftWrapperFee = oftWrapper.fee();

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        // bridge entire balance so vortex is empty
        emit TokensBridged(user1, withdrawToken, vortexBalance);
        vortexFantomBridge.bridge{ value: oftWrapperFee }(vortexBalance + 1);
    }

    /// @dev test bridging reverts if insufficient amount received
    function testRevertsIfInsufficientAmountReceived() public {
        vm.startPrank(user1);

        oftWrapper.setSlippagePPM(7000);

        uint256 expectedAmountReceived = getAmountOut(AMOUNT);
        uint256 expectedMinAmount = AMOUNT - (AMOUNT * vortexFantomBridge.slippagePPM()) / PPM_RESOLUTION;

        uint256 oftWrapperFee = oftWrapper.fee();

        vm.expectRevert(
            abi.encodeWithSelector(
                VortexBridgeBase.InsufficientAmountReceived.selector,
                expectedAmountReceived,
                expectedMinAmount
            )
        );
        vortexFantomBridge.bridge{ value: oftWrapperFee }(AMOUNT);
    }

    /// @dev test bridging reverts if insufficient native token sent
    function testRevertsIfInsufficientNativeTokenSent() public {
        vm.startPrank(user1);

        uint256 oftWrapperFee = oftWrapper.fee();

        vm.expectRevert(abi.encodeWithSelector(VortexBridgeBase.InsufficientNativeTokenSent.selector));
        vortexFantomBridge.bridge{ value: oftWrapperFee - 1 }(AMOUNT);
    }

    /// @dev helper function to calculate the bridge amount out
    function getAmountOut(uint256 amount) public view returns (uint256) {
        return amount - (amount * oftWrapper.slippagePPM()) / PPM_RESOLUTION;
    }
}
