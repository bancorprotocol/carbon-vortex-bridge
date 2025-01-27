// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { V3SpokePoolInterface } from "../interfaces/V3SpokePoolInterface.sol";

import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { PPM_RESOLUTION } from "../utility/Utils.sol";
import { MathEx } from "../utility/MathEx.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";

/**
 * @dev VortexAcrossBridge contract
 */
contract VortexAcrossBridge is VortexBridgeBase {
    using SafeERC20 for IERC20;
    using Address for address payable;

    error UnnecessaryNativeTokenSent();

    uint256 private constant MAINNET_CHAIN_ID = 1;
    uint32 private constant MAX_DEADLINE_OFFSET = 3600; // 1 hour

    V3SpokePoolInterface private immutable _acrossPool; // across pool address
    address private immutable _weth; // WETH address on the deployed chain

    /**
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(
        ICarbonVortex vortexInit,
        V3SpokePoolInterface acrossPoolInit,
        address vaultInit,
        address wethInit
    )
        validAddress(address(vortexInit))
        validAddress(address(acrossPoolInit))
        validAddress(vaultInit)
        validAddress(wethInit)
    {
        _vortex = vortexInit;
        _acrossPool = acrossPoolInit;
        _vault = vaultInit;
        _weth = wethInit;

        _disableInitializers();
    }

    /**
     * @dev authorize the contract to receive the native token
     */
    receive() external payable {}

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
        amount = _withdrawVortex(amount);
        // if amount is 0, there is no balance in the vortex
        if (amount == 0) {
            return 0;
        }

        // this is the amount of tokens which will be received on the destination chain
        // the difference amountIn - amountOut includes the relayer, lp and gas fees
        uint256 amountOut = amount - MathEx.mulDivF(amount, _slippagePPM, PPM_RESOLUTION);

        uint256 valueToSend = 0;
        if (_withdrawToken.isNative()) {
            valueToSend += amount;
        }

        // approve token if not approved
        _setPlatformAllowance(_withdrawToken, address(_acrossPool), amount);

        // if token is native, set inputToken = WETH
        // across bridge treats weth address (if msg.value > 0) as the native token
        address tokenToBridge = _withdrawToken.isNative() ? _weth : Token.unwrap(_withdrawToken);

        // bridge the token to the mainnet vault
        _acrossPool.depositV3Now{ value: valueToSend }(
            address(this), // depositor
            _vault, // recipient
            tokenToBridge, // inputToken
            address(0), // outputToken (address(0) indicates the output token is the equivalent to the input token)
            amount,
            amountOut,
            MAINNET_CHAIN_ID, // destinationChainId
            address(0),
            MAX_DEADLINE_OFFSET, // deposit timeout limit
            0,
            ""
        );

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return amountOut;
    }
}
