// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { PPM_RESOLUTION } from "../utility/Utils.sol";
import { MathEx } from "../utility/MathEx.sol";
import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { Utils } from "../utility/Utils.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";

/**
 * @dev VortexBridgeBase abstract contract
 */
abstract contract VortexBridgeBase is ReentrancyGuardUpgradeable, Utils, Upgradeable {
    using Address for address payable;

    error InsufficientAmountReceived(uint256 amountReceived, uint256 minAmount);
    error InsufficientNativeTokenSent();

    ICarbonVortex internal immutable _vortex; // vortex address
    address internal immutable _vault; // address to receive bridged tokens on mainnet

    Token internal _withdrawToken; // target / final target token which is withdrawn from the vortex
    uint32 internal _slippagePPM; // bridge slippage ppm

    /**
     * @dev emitted when tokens are bridged successfully
     */
    event TokensBridged(address indexed sender, Token indexed token, uint256 amount);

    /**
     * @dev emitted when the withdraw token is updated
     */
    event WithdrawTokenUpdated(Token indexed prevWithdrawToken, Token indexed newWithdrawToken);

    /**
     * @dev emitted when the slippage (in units of PPM) is updated
     */
    event SlippagePPMUpdated(uint32 prevSlippagePPM, uint32 newSlippagePPM);

    /**
     * @dev triggered when tokens have been withdrawn from the carbon vortex bridge
     */
    event FundsWithdrawn(Token indexed token, address indexed caller, address indexed target, uint256 amount);

    /**
     * @dev used to set immutable state variables
     */
    constructor(ICarbonVortex vortexInit, address vaultInit) validAddress(address(vortexInit)) validAddress(vaultInit) {
        _vortex = vortexInit;
        _vault = vaultInit;
    }

    /**
     * @dev initializes the contract
     */
    function initialize(Token withdrawTokenInit, uint32 slippagePPMInit) external virtual initializer {
        __VortexBridgeBase_init(withdrawTokenInit, slippagePPMInit);
    }

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract and its parents
     */
    function __VortexBridgeBase_init(Token withdrawTokenInit, uint32 slippagePPMInit) internal onlyInitializing {
        __Upgradeable_init();

        __VortexBridgeBase_init_unchained(withdrawTokenInit, slippagePPMInit);
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __VortexBridgeBase_init_unchained(
        Token withdrawTokenInit,
        uint32 slippagePPMInit
    ) internal onlyInitializing {
        _withdrawToken = withdrawTokenInit;
        _slippagePPM = slippagePPMInit;
    }

    /**
     * @notice function which bridges the target / final target tokens accumulated in the vortex to the mainnet vault
     * @notice if amount == 0, the entire available balance is bridged
     */
    function bridge(uint256 amount) external payable virtual returns (uint256) {}

    /**
     * @dev withdraws *amount* of _withdrawToken from the vortex to this contract
     * @dev if amount == 0, the entire available balance is withdrawn
     */
    function _withdrawVortex(uint256 amount) internal virtual returns (uint256) {
        uint256 withdrawBalance = _withdrawToken.balanceOf(address(_vortex));
        if (withdrawBalance == 0) {
            return 0;
        }
        // if amount is greater than the available balance or is 0, set amount to the available balance
        if (amount > withdrawBalance || amount == 0) {
            amount = withdrawBalance;
        }
        Token[] memory tokens = new Token[](1);
        tokens[0] = _withdrawToken;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // withdraw the token from the vortex
        _vortex.withdrawFunds(tokens, payable(address(this)), amounts);

        return amount;
    }
    /**
     * @notice returns the configured withdraw token
     */
    function withdrawToken() external view returns (Token) {
        return _withdrawToken;
    }

    /**
     * @notice sets the withdraw token
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setWithdrawToken(
        Token newWithdrawToken
    ) external virtual onlyAdmin validAddress(Token.unwrap(newWithdrawToken)) {
        _setWithdrawToken(newWithdrawToken);
    }

    /**
     * @dev sets the withdraw token
     */
    function _setWithdrawToken(Token newWithdrawToken) internal {
        Token prevWithdrawToken = _withdrawToken;
        if (prevWithdrawToken == newWithdrawToken) {
            return;
        }

        _withdrawToken = newWithdrawToken;

        emit WithdrawTokenUpdated({ prevWithdrawToken: prevWithdrawToken, newWithdrawToken: newWithdrawToken });
    }

    /**
     * @notice returns the maximum allowed bridge slippage (in units of PPM)
     */
    function slippagePPM() external view returns (uint32) {
        return _slippagePPM;
    }

    /**
     * @notice sets the maximum allowed bridge slippage (in units of PPM)
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setSlippagePPM(uint32 newSlippagePPM) external onlyAdmin validSlippage(newSlippagePPM) {
        _setSlippagePPM(newSlippagePPM);
    }

    /**
     * @dev sets the slippage (in units of PPM)
     */
    function _setSlippagePPM(uint32 newSlippagePPM) internal {
        uint32 prevSlippagePPM = _slippagePPM;
        if (prevSlippagePPM == newSlippagePPM) {
            return;
        }

        _slippagePPM = newSlippagePPM;

        emit SlippagePPMUpdated({ prevSlippagePPM: prevSlippagePPM, newSlippagePPM: newSlippagePPM });
    }

    /**
     * @notice withdraws funds held by the contract and sends them to an account
     * @notice note that this is a safety mechanism, shouldn't be necessary in normal operation
     *
     * requirements:
     *
     * - the caller is admin of the contract
     */
    function withdrawFunds(
        Token token,
        address payable target,
        uint256 amount
    ) external validAddress(target) onlyAdmin nonReentrant {
        if (amount == 0) {
            return;
        }

        // forwards all available gas in case of ETH
        token.unsafeTransfer(target, amount);

        emit FundsWithdrawn({ token: token, caller: msg.sender, target: target, amount: amount });
    }

    /**
     * @dev set platform allowance to 2 ** 256 - 1 if it's less than the input amount
     */
    function _setPlatformAllowance(Token token, address platform, uint256 inputAmount) internal {
        if (token.isNative()) {
            return;
        }
        uint256 allowance = token.toIERC20().allowance(address(this), platform);
        if (allowance < inputAmount) {
            // increase allowance to the max amount if allowance < inputAmount
            token.forceApprove(platform, type(uint256).max);
        }
    }

    function _estimateMinAmountToReceive(uint256 amount) internal view returns (uint256) {
        return amount - MathEx.mulDivF(amount, _slippagePPM, PPM_RESOLUTION);
    }

    /**
     * @dev validates that the amount received is greater than the minimum amount expected
     */
    function _validateAmountReceived(uint256 amountReceived, uint256 minAmount) internal pure {
        if (amountReceived < minAmount) {
            revert InsufficientAmountReceived({ amountReceived: amountReceived, minAmount: minAmount });
        }
    }

    /**
     * @dev validates that the native token sent is sufficient
     */
    function _validateSufficientNativeTokenSent(uint256 txValue, uint256 requiredValue) internal pure {
        if (txValue < requiredValue) {
            revert InsufficientNativeTokenSent();
        }
    }

    /**
     * @dev refund excess native token sent
     */
    function _refundExcessNativeTokenSent(address sender, uint256 txValue, uint256 requiredValue) internal {
        if (txValue > requiredValue) {
            // refund excess native token sent
            payable(sender).sendValue(txValue - requiredValue);
        }
    }
}
