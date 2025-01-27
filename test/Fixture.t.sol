// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import { VortexStargateBridge } from "../contracts/bridge/VortexStargateBridge.sol";
import { VortexAcrossBridge } from "../contracts/bridge/VortexAcrossBridge.sol";

import { TestWETH } from "../contracts/helpers/TestWETH.sol";
import { TestERC20Token } from "../contracts/helpers/TestERC20Token.sol";
import { TestVortexBridgeBase } from "../contracts/helpers/TestVortexBridgeBase.sol";
import { MockCarbonVortex } from "../contracts/helpers/MockCarbonVortex.sol";
import { MockVault } from "../contracts/helpers/MockVault.sol";
import { MockStargate } from "../contracts/helpers/MockStargate.sol";
import { MockV3SpokePool } from "../contracts/helpers/MockV3SpokePool.sol";
import { TransparentUpgradeableProxyImmutable } from "../contracts/utility/TransparentUpgradeableProxyImmutable.sol";
import { Utilities } from "./Utilities.t.sol";

import { ICarbonVortex } from "../contracts/interfaces/ICarbonVortex.sol";
import { IStargate } from "../contracts/interfaces/IStargate.sol";
import { V3SpokePoolInterface } from "../contracts/interfaces/V3SpokePoolInterface.sol";

contract Fixture is Test {
    Utilities internal utils;
    VortexStargateBridge internal vortexBridge;
    VortexAcrossBridge internal vortexAcrossBridge;
    TestVortexBridgeBase internal vortexBridgeBase;
    TestWETH internal weth;
    TestERC20Token internal token0;
    TestERC20Token internal token1;
    MockVault internal vault;
    MockCarbonVortex internal vortex;
    MockStargate internal stargate;
    MockV3SpokePool internal acrossPool;
    ProxyAdmin internal proxyAdmin;

    address payable[] internal users;
    address payable internal admin;
    address payable internal user1;

    uint256 internal constant MAX_SOURCE_AMOUNT = 100_000_000 ether;
    uint256 internal constant AMOUNT = 1000 ether;

    /**
     * @dev setup vortex stargate bridge
     */
    function setupVortexStargateBridge() internal {
        baseSetup();
        // deploy VortexStargateBridge
        vortexBridge = new VortexStargateBridge(
            ICarbonVortex(address(vortex)),
            IStargate(address(stargate)),
            address(vault)
        );

        bytes memory selector = abi.encodeWithSelector(vortexBridge.initialize.selector, address(weth), 5000);

        // deploy proxy
        address vortexBridgeProxy = address(
            new TransparentUpgradeableProxyImmutable(address(vortexBridge), payable(address(proxyAdmin)), selector)
        );
        vortexBridge = VortexStargateBridge(payable(vortexBridgeProxy));

        vm.stopPrank();
    }

    /**
     * @dev setup vortex across bridge
     */
    function setupVortexAcrossBridge() internal {
        baseSetup();
        // deploy VortexAcrossBridge
        vortexAcrossBridge = new VortexAcrossBridge(
            ICarbonVortex(address(vortex)),
            V3SpokePoolInterface(address(acrossPool)),
            address(vault),
            address(weth)
        );

        bytes memory selector = abi.encodeWithSelector(vortexAcrossBridge.initialize.selector, address(weth), 5000);

        // deploy proxy
        address vortexBridgeProxy = address(
            new TransparentUpgradeableProxyImmutable(
                address(vortexAcrossBridge),
                payable(address(proxyAdmin)),
                selector
            )
        );
        vortexAcrossBridge = VortexAcrossBridge(payable(vortexBridgeProxy));

        vm.stopPrank();
    }

    /**
     * @dev setup vortex bridge base contract (only for testing)
     */
    function setupVortexBridgeBase() internal {
        baseSetup();
        // deploy VortexBridgeBase
        vortexBridgeBase = new TestVortexBridgeBase(ICarbonVortex(address(vortex)), address(vault));

        bytes memory selector = abi.encodeWithSelector(vortexBridgeBase.initialize.selector, address(weth), 5000);

        // deploy proxy
        address vortexBridgeProxy = address(
            new TransparentUpgradeableProxyImmutable(address(vortexBridgeBase), payable(address(proxyAdmin)), selector)
        );
        vortexBridgeBase = TestVortexBridgeBase(payable(vortexBridgeProxy));

        vm.stopPrank();
    }

    /**
     * @dev base setup
     */
    function baseSetup() internal {
        utils = new Utilities();
        // create 4 users
        users = utils.createUsers();
        admin = users[0];
        user1 = users[1];

        // deploy contracts from admin
        vm.startPrank(admin);

        // deploy WETH
        weth = new TestWETH();
        // deploy proxy admin
        proxyAdmin = new ProxyAdmin(admin);
        // deploy MockCarbonVortex
        vortex = new MockCarbonVortex();
        // deploy MockVault
        vault = new MockVault();
        // deploy MockStargate with weth as bridge token
        stargate = new MockStargate(address(weth), 5000);
        // Deploy MockV3SpokePool with weth as bridge token
        acrossPool = new MockV3SpokePool(address(weth), 5000);

        // deploy test tokens
        token0 = new TestERC20Token("TKN1", "TKN1", 1_000_000_000 ether);
        token1 = new TestERC20Token("TKN2", "TKN2", 1_000_000_000 ether);

        vm.deal(admin, MAX_SOURCE_AMOUNT * 10);
        weth.deposit{ value: MAX_SOURCE_AMOUNT * 3 }();

        // send some tokens and eth to vortex
        token0.transfer(address(vortex), MAX_SOURCE_AMOUNT);
        token1.transfer(address(vortex), MAX_SOURCE_AMOUNT);
        weth.transfer(address(vortex), MAX_SOURCE_AMOUNT);
        vm.deal(address(vortex), MAX_SOURCE_AMOUNT);

        // send some tokens and eth to stargate
        token0.transfer(address(stargate), MAX_SOURCE_AMOUNT);
        token1.transfer(address(stargate), MAX_SOURCE_AMOUNT);
        weth.transfer(address(stargate), MAX_SOURCE_AMOUNT);
        vm.deal(address(stargate), MAX_SOURCE_AMOUNT);

        // send some tokens and eth to across pool
        token0.transfer(address(acrossPool), MAX_SOURCE_AMOUNT);
        token1.transfer(address(acrossPool), MAX_SOURCE_AMOUNT);
        weth.transfer(address(acrossPool), MAX_SOURCE_AMOUNT);
        vm.deal(address(acrossPool), MAX_SOURCE_AMOUNT);
    }
}
