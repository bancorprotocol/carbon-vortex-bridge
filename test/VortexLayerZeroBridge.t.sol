// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { VortexBridgeBase } from "../contracts/bridge/VortexBridgeBase.sol";

import { PPM_RESOLUTION } from "../contracts/utility/Utils.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexLayerZeroBridgeTest is Fixture {
    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    function setUp() public virtual {
        setupVortexLayerZeroBridge();
    }

    function testVersion() public view {
        assertGt(vortexLayerZeroBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexLayerZeroBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        // bridge the tokens
        vortexLayerZeroBridge.bridge{ value: layerZeroBridge.fee() }(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        // the bridge unwraps weth so vault receives native token
        assertEq(address(vault).balance, getAmountOut(amount));
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 layerZeroFee = layerZeroBridge.fee();
        Token withdrawToken = vortexLayerZeroBridge.withdrawToken();
        // bridge the tokens
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, amount);
        vortexLayerZeroBridge.bridge{ value: layerZeroFee }(amount);
    }

    /// @dev test bridging refunds correctly
    function testBridgingRefundsCorrectly() public {
        vm.startPrank(user1);

        uint256 layerZeroFee = layerZeroBridge.fee();
        uint256 userBalanceBefore = NATIVE_TOKEN.balanceOf(user1);

        // send twice the layerZeroBridge fee
        vortexLayerZeroBridge.bridge{ value: layerZeroFee * 2 }(AMOUNT);

        uint256 userBalanceAfter = NATIVE_TOKEN.balanceOf(user1);

        // check that the user received a refund of layerZeroFee
        assertEq(userBalanceAfter, userBalanceBefore - layerZeroFee);
    }

    /// @dev test that bridging zero amount will transfer the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexLayerZeroBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        // bridge with 0 amount
        vortexLayerZeroBridge.bridge{ value: layerZeroBridge.fee() }(0);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // assert vortex withdraw token balance is zero
        assertEq(vortexBalanceAfter, 0);
        // assert vault balance (in native token since weth is unwrapped) is equal to the vortex balance before
        assertEq(address(vault).balance, getAmountOut(vortexBalanceBefore));
    }

    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexLayerZeroBridge.withdrawToken();
        uint256 layerZeroFee = layerZeroBridge.fee();

        // bridge entire balance so vortex is empty
        vortexLayerZeroBridge.bridge{ value: layerZeroFee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // try to bridge again
        uint256 amount = vortexLayerZeroBridge.bridge{ value: layerZeroFee }(0);
        assertEq(amount, 0);
    }

    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexLayerZeroBridge.withdrawToken();
        uint256 layerZeroFee = layerZeroBridge.fee();

        // bridge entire balance so vortex is empty
        vortexLayerZeroBridge.bridge{ value: layerZeroFee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // record tx logs
        vm.recordLogs();

        // try to bridge again
        vortexLayerZeroBridge.bridge{ value: layerZeroFee }(0);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexLayerZeroBridge.withdrawToken();
        uint256 layerZeroFee = layerZeroBridge.fee();

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        // bridge entire balance so vortex is empty
        emit TokensBridged(user1, withdrawToken, vortexBalance);
        vortexLayerZeroBridge.bridge{ value: layerZeroFee }(vortexBalance + 1);
    }

    /// @dev test bridging reverts if insufficient amount received
    function testRevertsIfInsufficientAmountReceived() public {
        vm.startPrank(user1);

        layerZeroBridge.setSlippagePPM(7000);

        uint256 expectedAmountReceived = getAmountOut(AMOUNT);
        uint256 expectedMinAmount = AMOUNT - (AMOUNT * vortexLayerZeroBridge.slippagePPM()) / PPM_RESOLUTION;

        uint256 layerZeroFee = layerZeroBridge.fee();

        vm.expectRevert(
            abi.encodeWithSelector(
                VortexBridgeBase.InsufficientAmountReceived.selector,
                expectedAmountReceived,
                expectedMinAmount
            )
        );
        vortexLayerZeroBridge.bridge{ value: layerZeroFee }(AMOUNT);
    }

    /// @dev test bridging reverts if insufficient native token sent
    function testRevertsIfInsufficientNativeTokenSent() public {
        vm.startPrank(user1);

        uint256 layerZeroFee = layerZeroBridge.fee();

        vm.expectRevert(abi.encodeWithSelector(VortexBridgeBase.InsufficientNativeTokenSent.selector));
        vortexLayerZeroBridge.bridge{ value: layerZeroFee - 1 }(AMOUNT);
    }

    /// @dev helper function to calculate the bridge amount out
    function getAmountOut(uint256 amount) public view returns (uint256) {
        return amount - (amount * layerZeroBridge.withdrawalFeeBps()) / layerZeroBridge.TOTAL_BPS();
    }
}
