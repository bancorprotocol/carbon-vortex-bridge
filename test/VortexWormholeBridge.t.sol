// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Vm } from "forge-std/Vm.sol";

import { Token, NATIVE_TOKEN } from "../contracts/token/Token.sol";

import { VortexBridgeBase } from "../contracts/bridge/VortexBridgeBase.sol";

import { Fixture } from "./Fixture.t.sol";

contract VortexWormholeBridge is Fixture {
    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    function setUp() public virtual {
        setupVortexWormholeBridge();
    }

    function testVersion() public view {
        assertGt(vortexWormholeBridge.version(), 0);
    }

    /// @dev test bridging transfers balances to the vault correctly
    function testBridgingTransfersBalancesCorrectly(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        Token withdrawToken = vortexWormholeBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));
        // bridge the tokens
        vortexWormholeBridge.bridge{ value: wormholeBridge.messageFee() }(amount);
        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // cut off any dust (if token decimals > 8)
        uint256 expectedAmount = _sanitizeAmount(amount, withdrawToken.decimals());
        vm.assume(expectedAmount > 0);

        // finalize token transfer
        wormholeBridge.completeTransferAndUnwrapETH("");

        // check the tokens were bridged correctly
        assertEq(vortexBalanceAfter, vortexBalanceBefore - expectedAmount);
        // the bridge unwraps weth so vault receives native token
        assertEq(address(vault).balance, expectedAmount);
    }

    /// @dev test bridging emits event
    function testBridgingEmitsEvent(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 fee = wormholeBridge.messageFee();
        Token withdrawToken = vortexWormholeBridge.withdrawToken();

        // cut off any dust (if token decimals > 8)
        uint256 expectedAmount = _sanitizeAmount(amount, withdrawToken.decimals());
        vm.assume(expectedAmount > 0);

        // bridge the tokens
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, expectedAmount);
        vortexWormholeBridge.bridge{ value: fee }(amount);
    }

    /// @dev test bridging returns amount bridged
    function testBridgingReturnsAmountBridged(uint256 amount) public {
        amount = bound(amount, 1, MAX_SOURCE_AMOUNT);
        vm.startPrank(user1);
        uint256 fee = wormholeBridge.messageFee();
        Token withdrawToken = vortexWormholeBridge.withdrawToken();
        uint256 returnedAmount = vortexWormholeBridge.bridge{ value: fee }(amount);
        // cut off any dust (if token decimals > 8)
        uint256 expectedAmount = _sanitizeAmount(amount, withdrawToken.decimals());
        // no slippage, so amount should always be equal to the given amount
        assertEq(returnedAmount, expectedAmount);
    }

    /// @dev test bridging refunds correctly
    function testBridgingRefundsCorrectly() public {
        vm.startPrank(user1);

        uint256 fee = wormholeBridge.messageFee();
        uint256 userBalanceBefore = NATIVE_TOKEN.balanceOf(user1);

        // send twice the wormhole bridge fee
        vortexWormholeBridge.bridge{ value: fee * 2 }(AMOUNT);

        uint256 userBalanceAfter = NATIVE_TOKEN.balanceOf(user1);

        // check that the user received a refund of fee
        assertEq(userBalanceAfter, userBalanceBefore - fee);
    }

    /// @dev test that bridging zero amount will transfer the entire vortex balance
    function testBridgingZeroAmountWillTransferEntireVortexBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexWormholeBridge.withdrawToken();
        uint256 vortexBalanceBefore = withdrawToken.balanceOf(address(vortex));

        // bridge with 0 amount
        vortexWormholeBridge.bridge{ value: wormholeBridge.messageFee() }(0);

        uint256 vortexBalanceAfter = withdrawToken.balanceOf(address(vortex));

        // finalize bridge transaction on destination chain
        wormholeBridge.completeTransferAndUnwrapETH("");

        // assert vortex withdraw token balance is zero
        assertEq(vortexBalanceAfter, 0);
        // assert vault balance (in native token since weth is unwrapped) is equal to the vortex balance before
        assertEq(address(vault).balance, vortexBalanceBefore);
    }

    /// @dev test attempting to bridge if vortex doesn't have balance will return zero
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceWillReturnZero() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexWormholeBridge.withdrawToken();
        uint256 fee = wormholeBridge.messageFee();

        // bridge entire balance so vortex is empty
        vortexWormholeBridge.bridge{ value: fee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // finalize bridge transaction on destination chain
        wormholeBridge.completeTransferAndUnwrapETH("");

        // try to bridge again
        uint256 amount = vortexWormholeBridge.bridge{ value: fee }(0);
        assertEq(amount, 0);
    }

    /// @dev test attempting to bridge if vortex doesn't have balance doesn't emit event
    function testAttemptingToBridgeIfVortexDoesntHaveBalanceDoesntEmitEvent() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexWormholeBridge.withdrawToken();
        uint256 fee = wormholeBridge.messageFee();

        // bridge entire balance so vortex is empty
        vortexWormholeBridge.bridge{ value: fee }(0);

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        assertEq(vortexBalance, 0);

        // record tx logs
        vm.recordLogs();

        // try to bridge again
        vortexWormholeBridge.bridge{ value: fee }(0);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    /// @dev test attempting to bridge dust amounts doesn't emit event
    function testAttemptingToBridgeDustAmountsDoesntEmitEvent(uint256 amount) public {
        vm.startPrank(user1);
        amount = bound(amount, 1, 1e10 - 1);
        uint256 fee = wormholeBridge.messageFee();

        // record tx logs
        vm.recordLogs();
        // bridge only up to 1e10 - 1 tokens - which get truncated to 0 due to sanitization
        vortexWormholeBridge.bridge{ value: fee }(amount);

        // assert no events were emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 0);
    }

    /// @dev test attempting to bridge more than vortex balance will bridge the available balance
    function testAttemptingToBridgeMoreThanVortexBalanceWillBridgeTheAvailableBalance() public {
        vm.startPrank(user1);
        Token withdrawToken = vortexWormholeBridge.withdrawToken();
        uint256 fee = wormholeBridge.messageFee();

        uint256 vortexBalance = withdrawToken.balanceOf(address(vortex));

        // expect to bridge exactly the vortex balance
        vm.expectEmit();
        emit TokensBridged(user1, withdrawToken, vortexBalance);
        vortexWormholeBridge.bridge{ value: fee }(vortexBalance + 1);
    }

    /// @dev test bridging reverts if insufficient native token sent
    function testRevertsIfInsufficientNativeTokenSent() public {
        vm.startPrank(user1);

        uint256 fee = wormholeBridge.messageFee();

        vm.expectRevert(abi.encodeWithSelector(VortexBridgeBase.InsufficientNativeTokenSent.selector));
        vortexWormholeBridge.bridge{ value: fee - 1 }(AMOUNT);
    }

    /// @dev helper functions

    /**
     * @dev rounds amount to the nearest unit with 8-decimal precision
     */
    function _sanitizeAmount(uint256 amount, uint8 decimals) private pure returns (uint256) {
        if (decimals > 8) {
            uint256 factor = 10 ** (decimals - 8);
            amount = (amount / factor) * factor;
        }
        return amount;
    }
}
