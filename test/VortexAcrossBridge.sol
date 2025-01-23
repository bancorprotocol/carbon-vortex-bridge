// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { PPM_RESOLUTION, MAX_SLIPPAGE_PPM, AccessDenied, InvalidSlippage, InvalidAddress } from "../contracts/utility/Utils.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexAcrossBridgeTest is Fixture {
    uint32 private constant NEW_SLIPPAGE_PPM = 7000;

    Token private newWithdrawToken;

    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    event WithdrawTokenUpdated(Token indexed prevWithdrawToken, Token indexed newWithdrawToken);

    event SlippagePPMUpdated(uint32 prevSlippagePPM, uint32 newSlippagePPM);

    event FundsWithdrawn(Token indexed token, address indexed caller, address indexed target, uint256 amount);

    function setUp() public virtual {
        setupVortexAcrossBridge();
        newWithdrawToken = Token.wrap(address(token1));
    }

    function testVersion() public view {
        assertGt(vortexAcrossBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(admin);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        // bridge the tokens
        vortexAcrossBridge.bridge(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        assertEq(withdrawToken.balanceOf(address(vault)), getAmountOut(amount));
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();
        // bridge the tokens
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, amount);
        vortexAcrossBridge.bridge(amount);
    }

    /// @dev test bridging native token works correctly
    /// @dev native token gets bridged as weth for contracts in Across
    function testBridgingNativeTokenWorksCorrectly() public {
        vm.startPrank(admin);

        // set the vortex bridge withdraw token to native token
        vortexAcrossBridge.setWithdrawToken(NATIVE_TOKEN);

        vm.stopPrank();

        vm.startPrank(user1);

        uint256 vortexBalanceBefore = NATIVE_TOKEN.balanceOf(address(vortex));

        // bridge the tokens
        vortexAcrossBridge.bridge(AMOUNT);

        uint256 vortexBalanceAfter = NATIVE_TOKEN.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - AMOUNT);
        // across bridge transfers the native wrapped token to the vault if token is native
        assertEq(weth.balanceOf(address(vault)), getAmountOut(AMOUNT));
        vm.stopPrank();
    }

    /// @dev test that bridging zero amount will transfer the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        // bridge with 0 amount
        vortexAcrossBridge.bridge(0);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // assert vortex withdraw token balance is zero
        assertEq(vortexBalanceAfter, 0);
        // assert vault balance is equal to the vortex balance before
        assertEq(withdrawToken.balanceOf(address(vault)), getAmountOut(vortexBalanceBefore));
    }

    /// @dev test attempting to bridge if vortex doesn't have balance will return zero
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();

        // bridge entire balance so vortex is empty
        vortexAcrossBridge.bridge(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // try to bridge again
        uint256 amount = vortexAcrossBridge.bridge(0);
        assertEq(amount, 0);
    }

    /// @dev test if vortex doesn't have balance, attempting to bridge will not emit event
    function testFailAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();

        // bridge entire balance so vortex is empty
        vortexAcrossBridge.bridge(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // try to bridge again
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, 0);
        vortexAcrossBridge.bridge(0);
    }

    /// @dev test attempting to bridge more than vortex balance will bridge the available balance
    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        // bridge vortexBalance + 1
        emit TokensBridged(user1, withdrawToken, vortexBalance);
        vortexAcrossBridge.bridge(vortexBalance + 1);
    }

    /**
     * @dev admin functions
     * @dev slippage ppm and withdraw token
     */

    /// @dev set slippage ppm tests

    function testShouldRevertWhenANonAdminAttemptsToSetTheSlippagePPM() public {
        vm.prank(user1);
        vm.expectRevert(AccessDenied.selector);
        vortexAcrossBridge.setSlippagePPM(NEW_SLIPPAGE_PPM);
    }

    function testShouldRevertWhenSettingTheSlippagePPMToAnInvalidValue() public {
        vm.prank(admin);
        vm.expectRevert(InvalidSlippage.selector);
        vortexAcrossBridge.setSlippagePPM(MAX_SLIPPAGE_PPM + 1);
    }

    function testFailShouldIgnoreUpdatingToTheSameSlippagePPM() public {
        uint32 slippagePPM = vortexAcrossBridge.slippagePPM();
        vm.prank(admin);
        vm.expectEmit();
        emit SlippagePPMUpdated(slippagePPM, slippagePPM);
        vortexAcrossBridge.setSlippagePPM(slippagePPM);
    }

    function testShouldBeAbleToSetAndUpdateTheSlippagePPM() public {
        uint32 slippagePPM = vortexAcrossBridge.slippagePPM();
        vm.prank(admin);
        vm.expectEmit();
        emit SlippagePPMUpdated(slippagePPM, NEW_SLIPPAGE_PPM);
        vortexAcrossBridge.setSlippagePPM(NEW_SLIPPAGE_PPM);

        slippagePPM = vortexAcrossBridge.slippagePPM();
        assertEq(slippagePPM, NEW_SLIPPAGE_PPM);
    }

    /// @dev set withdraw token tests

    function testShouldRevertWhenANonAdminAttemptsToSetTheWithdrawToken() public {
        vm.prank(user1);
        vm.expectRevert(AccessDenied.selector);
        vortexAcrossBridge.setWithdrawToken(newWithdrawToken);
    }

    function testShouldRevertWhenSettingTheWithdrawTokenToAnInvalidValue() public {
        vm.prank(admin);
        vm.expectRevert(InvalidAddress.selector);
        vortexAcrossBridge.setWithdrawToken(Token.wrap(address(0)));
    }

    function testFailShouldIgnoreUpdatingToTheSameWithdrawToken() public {
        Token withdrawToken = vortexAcrossBridge.withdrawToken();
        vm.prank(admin);
        vm.expectEmit();
        emit WithdrawTokenUpdated(withdrawToken, withdrawToken);
        vortexAcrossBridge.setWithdrawToken(withdrawToken);
    }

    function testShouldBeAbleToSetAndUpdateTheWithdrawToken() public {
        Token withdrawToken = vortexAcrossBridge.withdrawToken();
        vm.prank(admin);
        vm.expectEmit();
        emit WithdrawTokenUpdated(withdrawToken, newWithdrawToken);
        vortexAcrossBridge.setWithdrawToken(newWithdrawToken);

        withdrawToken = vortexAcrossBridge.withdrawToken();
        assertTrue(withdrawToken == newWithdrawToken);
    }

    /// @dev withdrawFunds tests

    /// @dev test should revert when attempting to withdraw funds without the admin role
    function testShouldRevertWhenAttemptingToWithdrawFundsWithoutTheAdminRole() public {
        vm.prank(user1);
        vm.expectRevert(AccessDenied.selector);
        vortexAcrossBridge.withdrawFunds(Token.wrap(address(token0)), user1, 1000);
    }

    /// @dev test should revert when attempting to withdraw funds to an invalid address
    function testShouldRevertWhenAttemptingToWithdrawFundsToAnInvalidAddress() public {
        vm.prank(admin);
        vm.expectRevert(InvalidAddress.selector);
        vortexAcrossBridge.withdrawFunds(Token.wrap(address(token0)), payable(address(0)), 1000);
    }

    /// @dev test admin should be able to withdraw funds
    function testAdminShouldBeAbleToWithdrawFunds() public {
        vm.startPrank(admin);
        // send funds to vortex bridge
        uint256 amount = 1000;
        Token.wrap(address(token0)).safeTransfer(address(vortexAcrossBridge), amount);

        uint256 adminBalanceBefore = token0.balanceOf(address(admin));

        vortexAcrossBridge.withdrawFunds(Token.wrap(address(token0)), admin, amount);

        uint256 adminBalanceAfter = token0.balanceOf(address(admin));
        assertEq(adminBalanceAfter, adminBalanceBefore + amount);
        vm.stopPrank();
    }

    /// @dev test withdraw funds emits event
    function testWithdrawFundsEmitsEvent() public {
        vm.startPrank(admin);
        // send funds to vortex bridge
        uint256 amount = 1000;
        Token.wrap(address(token0)).safeTransfer(address(vortexAcrossBridge), amount);

        vm.expectEmit();
        emit FundsWithdrawn(Token.wrap(address(token0)), admin, admin, amount);
        vortexAcrossBridge.withdrawFunds(Token.wrap(address(token0)), admin, amount);
    }

    /// @dev test withdraw funds with zero amount doesn't emit event
    function testFailWithdrawFundsWithZeroAmountDoesntEmitEvent() public {
        vm.startPrank(admin);
        uint256 amount = 0;

        vm.expectEmit();
        emit FundsWithdrawn(Token.wrap(address(token0)), admin, admin, amount);
        vortexAcrossBridge.withdrawFunds(Token.wrap(address(token0)), admin, amount);
    }

    /// @dev helper function to calculate the bridge amount out (Across)
    function getAmountOut(uint256 amount) public view returns (uint256) {
        return amount - (amount * vortexAcrossBridge.slippagePPM()) / PPM_RESOLUTION;
    }
}
