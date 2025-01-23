// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { Vm } from "forge-std/Vm.sol";

import { Token } from "../contracts/token/Token.sol";

import { MAX_SLIPPAGE_PPM, AccessDenied, InvalidSlippage, InvalidAddress } from "../contracts/utility/Utils.sol";

import { Fixture } from "./Fixture.t.sol";

/**
 * @dev test shared admin functions
 */
contract VortexBridgeBaseTest is Fixture {
    uint32 private constant NEW_SLIPPAGE_PPM = 7000;

    Token private newWithdrawToken;

    event WithdrawTokenUpdated(Token indexed prevWithdrawToken, Token indexed newWithdrawToken);

    event SlippagePPMUpdated(uint32 prevSlippagePPM, uint32 newSlippagePPM);

    event FundsWithdrawn(Token indexed token, address indexed caller, address indexed target, uint256 amount);

    function setUp() public virtual {
        setupVortexBridgeBase();
        newWithdrawToken = Token.wrap(address(token1));
    }

    /// @dev test withdraw vortex helper function
    function testWithdrawVortexShouldCorrectlyTransferBalances() public {
        vm.startPrank(admin);

        Token withdrawToken = vortexBridgeBase.withdrawToken();

        uint256 amount = AMOUNT;

        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        uint256 amountReturn = vortexBridgeBase.withdrawVortex(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        assertEq(amountReturn, amount);
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        assertEq(withdrawToken.balanceOf(address(vortexBridgeBase)), amount);
    }

    /// @dev test withdraw vortex withdraws full balance if the amount is zero
    function testWithdrawVortexWithdrawsFullBalanceIfAmountIsZero() public {
        vm.startPrank(admin);

        Token withdrawToken = vortexBridgeBase.withdrawToken();

        uint256 amount = 0;

        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        uint256 amountReturn = vortexBridgeBase.withdrawVortex(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        assertEq(amountReturn, vortexBalanceBefore);
        assertEq(vortexBalanceAfter, 0);
        assertEq(withdrawToken.balanceOf(address(vortexBridgeBase)), vortexBalanceBefore);
    }

    /// @dev test withdraw vortex withdraws full balance if the amount is above the current balance
    function testWithdrawVortexWithdrawsFullBalanceIfAmountIsAboveTheCurrentBalance() public {
        vm.startPrank(admin);

        Token withdrawToken = vortexBridgeBase.withdrawToken();

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        uint256 amountReturn = vortexBridgeBase.withdrawVortex(vortexBalance + 1);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        assertEq(amountReturn, vortexBalance);
        assertEq(vortexBalanceAfter, 0);
        assertEq(withdrawToken.balanceOf(address(vortexBridgeBase)), vortexBalance);
    }

    function testWithdrawVortexReturnsZeroIfVortexBalanceIsZero() public {
        vm.startPrank(admin);

        vortexBridgeBase.withdrawVortex(0);

        uint256 amount = vortexBridgeBase.withdrawVortex(0);

        assertEq(amount, 0);
    }

    /**
     * @dev admin functions tests
     */

    /// @dev set slippage ppm tests

    function testShouldRevertWhenANonAdminAttemptsToSetTheSlippagePPM() public {
        vm.prank(user1);
        vm.expectRevert(AccessDenied.selector);
        vortexBridgeBase.setSlippagePPM(NEW_SLIPPAGE_PPM);
    }

    function testShouldRevertWhenSettingTheSlippagePPMToAnInvalidValue() public {
        vm.prank(admin);
        vm.expectRevert(InvalidSlippage.selector);
        vortexBridgeBase.setSlippagePPM(MAX_SLIPPAGE_PPM + 1);
    }

    function testShouldIgnoreUpdatingToTheSameSlippagePPM() public {
        uint32 slippagePPM = vortexBridgeBase.slippagePPM();
        vm.prank(admin);

        vm.recordLogs();

        vortexBridgeBase.setSlippagePPM(slippagePPM);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);

        uint32 newSlippagePPM = vortexBridgeBase.slippagePPM();
        assertEq(newSlippagePPM, slippagePPM);
    }

    function testShouldBeAbleToSetAndUpdateTheSlippagePPM() public {
        uint32 slippagePPM = vortexBridgeBase.slippagePPM();
        vm.prank(admin);
        vm.expectEmit();
        emit SlippagePPMUpdated(slippagePPM, NEW_SLIPPAGE_PPM);
        vortexBridgeBase.setSlippagePPM(NEW_SLIPPAGE_PPM);

        slippagePPM = vortexBridgeBase.slippagePPM();
        assertEq(slippagePPM, NEW_SLIPPAGE_PPM);
    }

    /// @dev set withdraw token tests

    function testShouldRevertWhenANonAdminAttemptsToSetTheWithdrawToken() public {
        vm.prank(user1);
        vm.expectRevert(AccessDenied.selector);
        vortexBridgeBase.setWithdrawToken(newWithdrawToken);
    }

    function testShouldRevertWhenSettingTheWithdrawTokenToAnInvalidValue() public {
        vm.prank(admin);
        vm.expectRevert(InvalidAddress.selector);
        vortexBridgeBase.setWithdrawToken(Token.wrap(address(0)));
    }

    function testShouldIgnoreUpdatingToTheSameWithdrawToken() public {
        Token withdrawToken = vortexBridgeBase.withdrawToken();
        vm.prank(admin);

        vm.recordLogs();

        vortexBridgeBase.setWithdrawToken(withdrawToken);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);

        Token newToken = vortexBridgeBase.withdrawToken();
        assertTrue(newToken == withdrawToken);
    }

    function testShouldBeAbleToSetAndUpdateTheWithdrawToken() public {
        Token withdrawToken = vortexBridgeBase.withdrawToken();
        vm.prank(admin);
        vm.expectEmit();
        emit WithdrawTokenUpdated(withdrawToken, newWithdrawToken);
        vortexBridgeBase.setWithdrawToken(newWithdrawToken);

        withdrawToken = vortexBridgeBase.withdrawToken();
        assertTrue(withdrawToken == newWithdrawToken);
    }

    /// @dev withdrawFunds tests

    /// @dev test should revert when attempting to withdraw funds without the admin role
    function testShouldRevertWhenAttemptingToWithdrawFundsWithoutTheAdminRole() public {
        vm.prank(user1);
        vm.expectRevert(AccessDenied.selector);
        vortexBridgeBase.withdrawFunds(Token.wrap(address(token0)), user1, 1000);
    }

    /// @dev test should revert when attempting to withdraw funds to an invalid address
    function testShouldRevertWhenAttemptingToWithdrawFundsToAnInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert(InvalidAddress.selector);
        vortexBridgeBase.withdrawFunds(Token.wrap(address(token0)), payable(address(0)), 1000);
    }

    /// @dev test admin should be able to withdraw funds
    function testAdminShouldBeAbleToWithdrawFunds() public {
        vm.startPrank(admin);
        // send funds to vortex bridge
        uint256 amount = 1000;
        Token.wrap(address(token0)).safeTransfer(address(vortexBridgeBase), amount);

        uint256 adminBalanceBefore = token0.balanceOf(address(admin));

        vortexBridgeBase.withdrawFunds(Token.wrap(address(token0)), admin, amount);

        uint256 adminBalanceAfter = token0.balanceOf(address(admin));
        assertEq(adminBalanceAfter, adminBalanceBefore + amount);
        vm.stopPrank();
    }

    /// @dev test withdraw funds emits event
    function testWithdrawFundsEmitsEvent() public {
        vm.startPrank(admin);
        // send funds to vortex bridge
        uint256 amount = 1000;
        Token.wrap(address(token0)).safeTransfer(address(vortexBridgeBase), amount);

        vm.expectEmit();
        emit FundsWithdrawn(Token.wrap(address(token0)), admin, admin, amount);
        vortexBridgeBase.withdrawFunds(Token.wrap(address(token0)), admin, amount);
    }

    /// @dev test withdraw funds with zero amount doesn't emit event
    function testWithdrawFundsWithZeroAmountDoesntEmitEvent() public {
        vm.startPrank(admin);
        uint256 amount = 0;

        // record tx logs
        vm.recordLogs();

        // withdraw funds
        vortexBridgeBase.withdrawFunds(Token.wrap(address(token0)), admin, amount);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }
}
