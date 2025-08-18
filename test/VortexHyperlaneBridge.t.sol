// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { VortexBridgeBase } from "../contracts/bridge/VortexBridgeBase.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexHyperlaneBridge is Fixture {
    // hyperlane mainnet destination endpoint id
    uint32 private constant DESTINATION_ENDPOINT_ID = 1;

    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    function setUp() public virtual {
        setupVortexHyperlaneBridge();
    }

    function testVersion() public view {
        assertGt(vortexHyperlaneBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexHyperlaneBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);
        // bridge the tokens
        vortexHyperlaneBridge.bridge{ value: fee }(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - amount);
        // check that the vault received the correct amount
        assertEq(withdrawToken.balanceOf(address(vault)), amount);
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);
        Token withdrawToken = vortexHyperlaneBridge.withdrawToken();

        // bridge the tokens
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, amount);
        vortexHyperlaneBridge.bridge{ value: fee }(amount);
    }

    /// @dev test bridging returns amount bridged
    function testBridgingReturnsAmountBridged(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);
        uint256 returnedAmount = vortexHyperlaneBridge.bridge{ value: fee }(amount);
        // no slippage, so amount should always be equal to the given amount
        assertEq(returnedAmount, amount);
    }

    /// @dev test bridging refunds correctly
    function testBridgingRefundsCorrectly() public {
        vm.startPrank(user1);

        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);
        uint256 userBalanceBefore = NATIVE_TOKEN.balanceOf(user1);

        // send twice the wormhole bridge fee
        vortexHyperlaneBridge.bridge{ value: fee * 2 }(AMOUNT);

        uint256 userBalanceAfter = NATIVE_TOKEN.balanceOf(user1);

        // check that the user received a refund of fee
        assertEq(userBalanceAfter, userBalanceBefore - fee);
    }

    /// @dev test that bridging zero amount will transfer the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexHyperlaneBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);

        // bridge with 0 amount
        vortexHyperlaneBridge.bridge{ value: fee }(0);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // assert vortex withdraw token balance is zero
        assertEq(vortexBalanceAfter, 0);
        // assert vault balance is equal to the vortex balance before
        assertEq(withdrawToken.balanceOf(address(vault)), vortexBalanceBefore);
    }

    /// @dev test attempting to bridge if vortex doesn't have balance will return zero
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexHyperlaneBridge.withdrawToken();
        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);

        // bridge entire balance so vortex is empty
        vortexHyperlaneBridge.bridge{ value: fee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // try to bridge again
        uint256 amount = vortexHyperlaneBridge.bridge{ value: fee }(0);
        assertEq(amount, 0);
    }

    /// @dev test attempting to bridge if vortex doesn't have balance doesn't emit event
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexHyperlaneBridge.withdrawToken();
        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);

        // bridge entire balance so vortex is empty
        vortexHyperlaneBridge.bridge{ value: fee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // record tx logs
        vm.recordLogs();

        // try to bridge again
        vortexHyperlaneBridge.bridge{ value: fee }(0);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    /// @dev test attempting to bridge more than vortex balance will bridge the available balance
    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexHyperlaneBridge.withdrawToken();
        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        // expect to bridge exactly the vortex balance
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, vortexBalance);
        vortexHyperlaneBridge.bridge{ value: fee }(vortexBalance + 1);
    }

    /// @dev test bridging reverts if insufficient native token sent
    function testRevertsIfInsufficientNativeTokenSent() public {
        vm.startPrank(user1);

        uint256 fee = hypERC20.quoteGasPayment(DESTINATION_ENDPOINT_ID);

        vm.expectRevert(abi.encodeWithSelector(VortexBridgeBase.InsufficientNativeTokenSent.selector));
        vortexHyperlaneBridge.bridge{ value: fee - 1 }(AMOUNT);
    }
}
