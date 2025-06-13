// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { OptimizedTransparentUpgradeableProxy } from "hardhat-deploy/solc_0.8/proxy/OptimizedTransparentUpgradeableProxy.sol";

import { VortexLayerZeroBridge } from "../contracts/bridge/VortexLayerZeroBridge.sol";
import { VortexStargateBridge } from "../contracts/bridge/VortexStargateBridge.sol";
import { VortexWormholeBridge } from "../contracts/bridge/VortexWormholeBridge.sol";
import { VortexAcrossBridge } from "../contracts/bridge/VortexAcrossBridge.sol";
import { VortexFantomBridge } from "../contracts/bridge/VortexFantomBridge.sol";

import { TestWETH } from "../contracts/helpers/TestWETH.sol";
import { TestERC20Token } from "../contracts/helpers/TestERC20Token.sol";
import { TestVortexBridgeBase } from "../contracts/helpers/TestVortexBridgeBase.sol";
import { MockCarbonVortex } from "../contracts/helpers/MockCarbonVortex.sol";
import { MockVault } from "../contracts/helpers/MockVault.sol";
import { MockStargate } from "../contracts/helpers/MockStargate.sol";
import { MockV3SpokePool } from "../contracts/helpers/MockV3SpokePool.sol";
import { MockOFTWrapper } from "../contracts/helpers/MockOFTWrapper.sol";
import { MockWormholeBridge } from "../contracts/helpers/MockWormholeBridge.sol";
import { MockLayerZeroBridge } from "../contracts/helpers/MockLayerZeroBridge.sol";
import { Utilities } from "./Utilities.t.sol";

import { ICarbonVortex } from "../contracts/interfaces/ICarbonVortex.sol";
import { IStargate } from "../contracts/interfaces/IStargate.sol";
import { IWormhole } from "../contracts/interfaces/IWormhole.sol";
import { IOFTWrapper } from "../contracts/interfaces/IOFTWrapper.sol";
import { ITokenBridge } from "../contracts/interfaces/ITokenBridge.sol";
import { IWrappedTokenBridge } from "../contracts/interfaces/IWrappedTokenBridge.sol";
import { V3SpokePoolInterface } from "../contracts/interfaces/V3SpokePoolInterface.sol";

// solhint-disable max-states-count

contract Fixture is Test {
    Utilities internal utils;
    VortexStargateBridge internal vortexBridge;
    VortexAcrossBridge internal vortexAcrossBridge;
    VortexFantomBridge internal vortexFantomBridge;
    VortexWormholeBridge internal vortexWormholeBridge;
    VortexLayerZeroBridge internal vortexLayerZeroBridge;
    TestVortexBridgeBase internal vortexBridgeBase;
    TestWETH internal weth;
    TestERC20Token internal token0;
    TestERC20Token internal token1;
    MockVault internal vault;
    MockCarbonVortex internal vortex;
    MockStargate internal stargate;
    MockV3SpokePool internal acrossPool;
    MockOFTWrapper internal oftWrapper;
    MockLayerZeroBridge internal layerZeroBridge;
    MockWormholeBridge internal wormholeBridge;
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
            new OptimizedTransparentUpgradeableProxy(address(vortexBridge), payable(address(proxyAdmin)), selector)
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
            new OptimizedTransparentUpgradeableProxy(
                address(vortexAcrossBridge),
                payable(address(proxyAdmin)),
                selector
            )
        );
        vortexAcrossBridge = VortexAcrossBridge(payable(vortexBridgeProxy));

        vm.stopPrank();
    }

    /**
     * @dev setup vortex fantom bridge
     */
    function setupVortexFantomBridge() internal {
        baseSetup();
        // deploy VortexFantomBridge
        vortexFantomBridge = new VortexFantomBridge(
            ICarbonVortex(address(vortex)),
            IOFTWrapper(address(oftWrapper)),
            address(vault)
        );

        bytes memory selector = abi.encodeWithSelector(vortexFantomBridge.initialize.selector, address(weth), 5000);

        // deploy proxy
        address vortexBridgeProxy = address(
            new OptimizedTransparentUpgradeableProxy(
                address(vortexFantomBridge),
                payable(address(proxyAdmin)),
                selector
            )
        );
        vortexFantomBridge = VortexFantomBridge(payable(vortexBridgeProxy));

        vm.stopPrank();
    }

    /**
     * @dev setup vortex layerzero bridge
     */
    function setupVortexLayerZeroBridge() internal {
        baseSetup();
        // deploy VortexLayerZeroBridge
        vortexLayerZeroBridge = new VortexLayerZeroBridge(
            ICarbonVortex(address(vortex)),
            IWrappedTokenBridge(address(layerZeroBridge)),
            address(vault)
        );

        bytes memory selector = abi.encodeWithSelector(vortexLayerZeroBridge.initialize.selector, address(weth), 5000);

        // deploy proxy
        address vortexBridgeProxy = address(
            new OptimizedTransparentUpgradeableProxy(
                address(vortexLayerZeroBridge),
                payable(address(proxyAdmin)),
                selector
            )
        );
        vortexLayerZeroBridge = VortexLayerZeroBridge(payable(vortexBridgeProxy));

        vm.stopPrank();
    }

    /**
     * @dev setup vortex wormhole bridge
     */
    function setupVortexWormholeBridge() internal {
        baseSetup();
        // deploy VortexWormholeBridge
        vortexWormholeBridge = new VortexWormholeBridge(
            ICarbonVortex(address(vortex)),
            ITokenBridge(address(wormholeBridge)),
            IWormhole(address(wormholeBridge)),
            address(vault)
        );

        bytes memory selector = abi.encodeWithSelector(vortexWormholeBridge.initialize.selector, address(weth), 5000);

        // deploy proxy
        address vortexBridgeProxy = address(
            new OptimizedTransparentUpgradeableProxy(
                address(vortexWormholeBridge),
                payable(address(proxyAdmin)),
                selector
            )
        );
        vortexWormholeBridge = VortexWormholeBridge(payable(vortexBridgeProxy));

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
            new OptimizedTransparentUpgradeableProxy(address(vortexBridgeBase), payable(address(proxyAdmin)), selector)
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
        proxyAdmin = new ProxyAdmin();
        // deploy MockCarbonVortex
        vortex = new MockCarbonVortex();
        // deploy MockVault
        vault = new MockVault();
        // deploy MockStargate with weth as bridge token
        stargate = new MockStargate(address(weth), 5000);
        // Deploy MockV3SpokePool with weth as bridge token
        acrossPool = new MockV3SpokePool(address(weth), 5000);
        // Deploy MockOFTWrapper with weth as bridge token
        oftWrapper = new MockOFTWrapper(address(weth), 5000);
        // Deploy MockLayerZeroBridge with weth as bridge token
        layerZeroBridge = new MockLayerZeroBridge(address(weth), 5000);
        // Deploy MockWormholeBridge with weth as bridge token
        wormholeBridge = new MockWormholeBridge(address(weth));

        // deploy test tokens
        token0 = new TestERC20Token("TKN1", "TKN1", 1_000_000_000 ether);
        token1 = new TestERC20Token("TKN2", "TKN2", 1_000_000_000 ether);

        vm.deal(admin, MAX_SOURCE_AMOUNT * 10);
        weth.deposit{ value: MAX_SOURCE_AMOUNT * 10 }();

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

        // send some tokens and eth to oft wrapper
        token0.transfer(address(oftWrapper), MAX_SOURCE_AMOUNT);
        token1.transfer(address(oftWrapper), MAX_SOURCE_AMOUNT);
        weth.transfer(address(oftWrapper), MAX_SOURCE_AMOUNT);
        vm.deal(address(oftWrapper), MAX_SOURCE_AMOUNT);

        // send some tokens and eth to layerZero bridge
        token0.transfer(address(layerZeroBridge), MAX_SOURCE_AMOUNT);
        token1.transfer(address(layerZeroBridge), MAX_SOURCE_AMOUNT);
        weth.transfer(address(layerZeroBridge), MAX_SOURCE_AMOUNT);
        vm.deal(address(layerZeroBridge), MAX_SOURCE_AMOUNT);

        // send some tokens and eth to wormhole bridge
        token0.transfer(address(wormholeBridge), MAX_SOURCE_AMOUNT);
        token1.transfer(address(wormholeBridge), MAX_SOURCE_AMOUNT);
        weth.transfer(address(wormholeBridge), MAX_SOURCE_AMOUNT);
        vm.deal(address(wormholeBridge), MAX_SOURCE_AMOUNT);
    }
}
