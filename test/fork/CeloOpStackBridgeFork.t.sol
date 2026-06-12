// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { OptimizedTransparentUpgradeableProxy } from "hardhat-deploy/solc_0.8/proxy/OptimizedTransparentUpgradeableProxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICarbonVortex } from "../../contracts/interfaces/ICarbonVortex.sol";
import { IL2StandardBridge } from "../../contracts/vendor/interfaces/IL2StandardBridge.sol";
import { VortexOpStackBridge } from "../../contracts/bridge/VortexOpStackBridge.sol";

interface IAccessControlLike {
    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);
}

/**
 * @dev Celo (L2) mainnet-fork test for the L2 side of the OP-stack withdrawal.
 *      Seeds the live Vortex with 1 native-bridge WETH and calls bridge() through a newly
 *      deployed VortexOpStackBridge wired to the REAL L2StandardBridge predeploy. Verifies the
 *      withdrawal is actually initiated on-chain: the L2 WETH (an OptimismMintableERC20) is burned
 *      and a `MessagePassed` event is emitted (the message a keeper later proves+finalizes on L1).
 *
 *      Run: CELO_RPC_URL=<rpc> forge test --match-contract CeloOpStackBridgeForkTest -vv
 */
contract CeloOpStackBridgeForkTest is Test {
    // live Celo (L2) addresses
    address internal constant VORTEX = 0xD9D89e8A0dfE549e5B424D5b511cB3b84A764857;
    address internal constant VAULT = 0x60917e542aDdd13bfd1a7f81cD654758052dAdC4; // recipient on L1
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
    address internal constant L2_WETH = 0xD221812de1BD094f35587EE8E174B07B6167D9Af; // withdrawToken (OptimismMintableERC20)
    address internal constant DEPLOYER = 0xe01EA58F6DA98488E4C92fD9b3E49607639C5370; // holds ROLE_ADMIN on the Vortex

    bytes32 internal constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    uint256 internal constant SEED_AMOUNT = 1e18; // 1 WETH
    string internal constant CELO_RPC_DEFAULT_URL = string("https://forno.celo.org");

    VortexOpStackBridge internal bridge;

    function setUp() public {
        // network-dependent fork test — opt in with FOUNDRY_FORK_TESTS=true
        if (!vm.envOr("FOUNDRY_FORK_TESTS", false)) {
            vm.skip(true);
            return;
        }

        vm.createSelectFork(vm.envOr("CELO_RPC_URL", CELO_RPC_DEFAULT_URL));

        // deploy the bridge behind a transparent proxy
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        VortexOpStackBridge impl = new VortexOpStackBridge(
            ICarbonVortex(VORTEX),
            IL2StandardBridge(L2_STANDARD_BRIDGE),
            VAULT
        );
        bytes memory initData = abi.encodeWithSelector(impl.initialize.selector, L2_WETH, uint32(0));
        OptimizedTransparentUpgradeableProxy proxy = new OptimizedTransparentUpgradeableProxy(
            address(impl),
            payable(address(proxyAdmin)),
            initData
        );
        bridge = VortexOpStackBridge(payable(address(proxy)));

        // grant the new bridge ROLE_ADMIN on the Vortex
        vm.prank(DEPLOYER);
        IAccessControlLike(VORTEX).grantRole(ROLE_ADMIN, address(bridge));
        assertTrue(IAccessControlLike(VORTEX).hasRole(ROLE_ADMIN, address(bridge)), "grant failed");
    }

    /// @dev seed the Vortex with 1 WETH and bridge it; verify the L2 withdrawal is initiated (burn + MessagePassed)
    function testBridgeInitiatesL2Withdrawal() public {
        deal(L2_WETH, VORTEX, SEED_AMOUNT);
        assertEq(IERC20(L2_WETH).balanceOf(VORTEX), SEED_AMOUNT, "deal failed to fund vortex");

        uint256 supplyBefore = IERC20(L2_WETH).totalSupply();

        vm.recordLogs();
        uint256 bridged = bridge.bridge(0);

        uint256 vortexAfter = IERC20(L2_WETH).balanceOf(VORTEX);
        uint256 bridgeAfter = IERC20(L2_WETH).balanceOf(address(bridge));
        uint256 supplyAfter = IERC20(L2_WETH).totalSupply();

        // the bridge withdrew the full balance (1:1)
        assertEq(bridged, SEED_AMOUNT, "should bridge full vortex balance");
        // Vortex drained, nothing stuck in the bridge
        assertEq(vortexAfter, 0, "vortex not drained");
        assertEq(bridgeAfter, 0, "funds stranded in bridge");
        // bridgeERC20To burns the OptimismMintableERC20 on withdrawal -> total supply drops by the amount
        assertEq(supplyBefore - supplyAfter, SEED_AMOUNT, "L2 WETH not burned (withdrawal not initiated)");
        // the canonical withdrawal message was queued (what the keeper later proves on L1)
        assertTrue(_sawMessagePassed(), "no MessagePassed event (withdrawal not initiated)");
    }

    /// @dev scans recorded logs for the L2ToL1MessagePasser MessagePassed event
    function _sawMessagePassed() internal returns (bool) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 sig = keccak256("MessagePassed(uint256,address,address,uint256,uint256,bytes,bytes32)");
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == sig) return true;
        }
        return false;
    }
}
