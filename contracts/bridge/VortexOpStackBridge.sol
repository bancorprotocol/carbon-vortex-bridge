// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";
import { IL2StandardBridge } from "../vendor/interfaces/IL2StandardBridge.sol";

/**
 * @dev VortexOpStackBridge contract
 *
 * @dev one-way bridge for OP-stack L2s (e.g. Celo). Initiates an ERC20 withdrawal of the WETH
 * accumulated in the vortex from L2 to the mainnet vault via the canonical L2StandardBridge.
 *
 * @dev settlement on L1 is asynchronous: a permissionless prove + finalize on the L1 OptimismPortal
 * (fault proofs) is required to release the L1 token to the vault (~7-day floor).
 */
contract VortexOpStackBridge is VortexBridgeBase {
    error UnnecessaryNativeTokenSent();
    error NativeWithdrawTokenNotSupported();

    // minimum gas limit forwarded for the L1 finalizeBridgeERC20 execution (a plain ERC20 transfer)
    uint32 private constant L1_GAS_LIMIT = 200_000;

    // remote (mainnet) token released to the vault on L1 when the withdrawal is finalized (WETH)
    address private constant MAINNET_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // OP-stack L2StandardBridge predeploy
    IL2StandardBridge private immutable _l2Bridge;

    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(
        ICarbonVortex vortexInit,
        IL2StandardBridge l2BridgeInit,
        address vaultInit
    ) validAddress(address(l2BridgeInit)) VortexBridgeBase(vortexInit, vaultInit) {
        _l2Bridge = l2BridgeInit;

        _disableInitializers();
    }

    /**
     * @inheritdoc Upgradeable
     */
    function version() public pure override(Upgradeable) returns (uint16) {
        return 1;
    }

    /**
     * @notice function which bridges the target / final target tokens accumulated in the vortex to the mainnet vault
     * @notice if amount == 0, the entire available balance is bridged
     */
    function bridge(uint256 amount) external payable override nonReentrant returns (uint256) {
        // disallow sending native token with the bridge function
        if (msg.value > 0) {
            revert UnnecessaryNativeTokenSent();
        }
        // the canonical bridge only releases an ERC20 on L1; a native withdraw token is unsupported
        if (_withdrawToken.isNative()) {
            revert NativeWithdrawTokenNotSupported();
        }
        // withdraw funds from vortex
        amount = _withdrawVortex(amount);
        // if amount is 0, there is no balance in the vortex
        if (amount == 0) {
            return 0;
        }

        // approve the L2 standard bridge to pull the withdraw token
        _setPlatformAllowance(_withdrawToken, address(_l2Bridge), amount);

        // initiate the L2 -> L1 ERC20 withdrawal directly to the mainnet vault (canonical bridge is 1:1)
        _l2Bridge.bridgeERC20To(
            Token.unwrap(_withdrawToken), // localToken: the L2 (bridge-minted) WETH
            MAINNET_WETH, // remoteToken: mainnet WETH
            _vault, // recipient on L1
            amount,
            L1_GAS_LIMIT,
            ""
        );

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return amount;
    }
}
