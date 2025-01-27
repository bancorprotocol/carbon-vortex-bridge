// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { PPM_RESOLUTION } from "../contracts/utility/Utils.sol";
import { VortexAcrossBridge } from "../contracts/bridge/VortexAcrossBridge.sol";

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
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexAcrossBridge.withdrawToken();

        // bridge entire balance so vortex is empty
        vortexAcrossBridge.bridge(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // record tx logs
        vm.recordLogs();

        // try to bridge again
        vortexAcrossBridge.bridge(0);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
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

    /// @dev test should revert if attempting to send native token with bridge function
    function testShouldRevertIfAttemptingToSendNativeTokenWithBridgeFunction() public {
        vm.prank(user1);
        vm.expectRevert(VortexAcrossBridge.UnnecessaryNativeTokenSent.selector);
        vortexAcrossBridge.bridge{ value: 1 }(0);
    }

    /// @dev helper function to calculate the bridge amount out
    function getAmountOut(uint256 amount) public view returns (uint256) {
        return amount - (amount * vortexAcrossBridge.slippagePPM()) / PPM_RESOLUTION;
    }
}
