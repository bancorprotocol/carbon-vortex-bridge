// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { VortexStargateBridge } from "../contracts/bridge/VortexStargateBridge.sol";

import { PPM_RESOLUTION } from "../contracts/utility/Utils.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexStargateBridgeTest is Fixture {
    uint32 private constant NEW_SLIPPAGE_PPM = 7000;

    Token private newWithdrawToken;

    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    event WithdrawTokenUpdated(Token indexed prevWithdrawToken, Token indexed newWithdrawToken);

    event SlippagePPMUpdated(uint32 prevSlippagePPM, uint32 newSlippagePPM);

    event FundsWithdrawn(Token indexed token, address indexed caller, address indexed target, uint256 amount);

    function setUp() public virtual {
        setupVortexStargateBridge();
        newWithdrawToken = Token.wrap(address(token1));
    }

    function testVersion() public view {
        assertGt(vortexBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(admin);
        Token withdrawToken = vortexBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        // bridge the tokens
        vortexBridge.bridge{ value: stargate.fee() }(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        assertEq(withdrawToken.balanceOf(address(vault)), getAmountOut(amount));
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 stargateFee = stargate.fee();
        Token withdrawToken = vortexBridge.withdrawToken();
        // bridge the tokens
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, amount);
        vortexBridge.bridge{ value: stargateFee }(amount);
    }

    /// @dev test bridging native token works correctly
    function testBridgingNativeTokenWorksCorrectly() public {
        vm.startPrank(admin);

        // set the vortex bridge withdraw token to native token
        vortexBridge.setWithdrawToken(NATIVE_TOKEN);
        // set the stargate bridge token to native token
        stargate.setToken(address(0));

        vm.stopPrank();

        vm.startPrank(user1);

        uint256 stargateFee = stargate.fee();
        uint256 vortexBalanceBefore = NATIVE_TOKEN.balanceOf(address(vortex));

        // bridge the tokens
        vortexBridge.bridge{ value: stargateFee }(AMOUNT);

        uint256 vortexBalanceAfter = NATIVE_TOKEN.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - AMOUNT);
        assertEq(NATIVE_TOKEN.balanceOf(address(vault)), getAmountOut(AMOUNT));
        vm.stopPrank();
    }

    /// @dev test native token refunds work correctly
    function testBridgingNativeTokenRefundsCorrectly() public {
        vm.startPrank(admin);

        vortexBridge.setWithdrawToken(NATIVE_TOKEN);
        stargate.setToken(address(0));

        vm.stopPrank();

        vm.startPrank(user1);

        uint256 stargateFee = stargate.fee();
        uint256 userBalanceBefore = NATIVE_TOKEN.balanceOf(user1);

        // send twice the stargate fee
        vortexBridge.bridge{ value: stargateFee * 2 }(AMOUNT);

        uint256 userBalanceAfter = NATIVE_TOKEN.balanceOf(user1);

        // check that the user received a refund of stargateFee
        assertEq(userBalanceAfter, userBalanceBefore - stargateFee);
    }

    /// @dev test that bridging zero amount will transfer the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        // bridge with 0 amount
        vortexBridge.bridge{ value: stargate.fee() }(0);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // assert vortex withdraw token balance is zero
        assertEq(vortexBalanceAfter, 0);
        // assert vault balance is equal to the vortex balance before
        assertEq(withdrawToken.balanceOf(address(vault)), getAmountOut(vortexBalanceBefore));
    }

    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexBridge.withdrawToken();
        uint256 stargateFee = stargate.fee();

        // bridge entire balance so vortex is empty
        vortexBridge.bridge{ value: stargateFee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // try to bridge again
        uint256 amount = vortexBridge.bridge{ value: stargateFee }(0);
        assertEq(amount, 0);
    }

    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexBridge.withdrawToken();
        uint256 stargateFee = stargate.fee();

        // bridge entire balance so vortex is empty
        vortexBridge.bridge{ value: stargateFee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // record tx logs
        vm.recordLogs();

        // try to bridge again
        vortexBridge.bridge{ value: stargateFee }(0);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexBridge.withdrawToken();
        uint256 stargateFee = stargate.fee();

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        // bridge entire balance so vortex is empty
        emit TokensBridged(user1, withdrawToken, vortexBalance);
        vortexBridge.bridge{ value: stargateFee }(vortexBalance + 1);
    }

    /// @dev test bridging reverts if insufficient amount received
    function testRevertsIfInsufficientAmountReceived() public {
        vm.startPrank(admin);

        stargate.setSlippagePPM(7000);

        uint256 expectedAmountReceived = getAmountOut(AMOUNT);
        uint256 expectedMinAmount = AMOUNT - (AMOUNT * vortexBridge.slippagePPM()) / PPM_RESOLUTION;

        uint256 stargateFee = stargate.fee();

        vm.expectRevert(
            abi.encodeWithSelector(
                VortexStargateBridge.InsufficientAmountReceived.selector,
                expectedAmountReceived,
                expectedMinAmount
            )
        );
        vortexBridge.bridge{ value: stargateFee }(AMOUNT);
    }

    /// @dev test bridging reverts if insufficient native token sent
    function testRevertsIfInsufficientNativeTokenSent() public {
        vm.startPrank(admin);

        uint256 stargateFee = stargate.fee();

        vm.expectRevert(abi.encodeWithSelector(VortexStargateBridge.InsufficientNativeTokenSent.selector));
        vortexBridge.bridge{ value: stargateFee - 1 }(AMOUNT);
    }

    /// @dev helper function to calculate the bridge amount out
    function getAmountOut(uint256 amount) public view returns (uint256) {
        return amount - (amount * stargate.slippagePPM()) / PPM_RESOLUTION;
    }
}
