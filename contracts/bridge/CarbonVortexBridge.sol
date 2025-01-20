// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

import { SendParam, MessagingFee, OFTReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import { IStargate } from "../interfaces/IStargate.sol";
import { Token } from "../token/Token.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { Utils, PPM_RESOLUTION } from "../utility/Utils.sol";
import { MathEx } from "../utility/MathEx.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";

/**
 * @dev CarbonVortexBridge contract
 */
contract CarbonVortexBridge is ReentrancyGuardTransient, Utils, Upgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    error InsufficientAmountReceived(uint256 amountReceived, uint256 minAmount);
    error InsufficientNativeTokenSent();

    // stargate v2 mainnet destination endpoint id
    uint32 private constant DESTINATION_ENDPOINT_ID = 30101;

    ICarbonVortex private immutable _vortex; // vortex address
    address private immutable _vault; // address to receive bridged tokens on mainnet
    IStargate private immutable _stargate; // stargate v2 bridge pool or oft

    Token private _withdrawToken; // target / final target token which is withdrawn from the vortex

    uint32 private _slippagePPM; // bridge slippage ppm

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
     * @dev used to set immutable state variables and disable initialization of the implementation
     */
    constructor(
        ICarbonVortex vortexInit,
        IStargate stargateInit,
        address vaultInit
    ) validAddress(address(vortexInit)) validAddress(address(stargateInit)) validAddress(vaultInit) {
        _vortex = vortexInit;
        _stargate = stargateInit;
        _vault = vaultInit;

        _disableInitializers();
    }

    /**
     * @dev initializes the contract
     */
    function initialize(Token withdrawTokenInit, uint32 slippagePPMInit) external initializer {
        __CarbonVortexBridge_init(withdrawTokenInit, slippagePPMInit);
    }

    // solhint-disable func-name-mixedcase

    /**
     * @dev initializes the contract and its parents
     */
    function __CarbonVortexBridge_init(Token withdrawTokenInit, uint32 slippagePPMInit) internal onlyInitializing {
        __Upgradeable_init();

        __CarbonVortexBridge_init_unchained(withdrawTokenInit, slippagePPMInit);
    }

    /**
     * @dev performs contract-specific initialization
     */
    function __CarbonVortexBridge_init_unchained(
        Token withdrawTokenInit,
        uint32 slippagePPMInit
    ) internal onlyInitializing {
        _withdrawToken = withdrawTokenInit;
        _slippagePPM = slippagePPMInit;
    }

    // solhint-enable func-name-mixedcase

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
    function bridge(uint256 amount) external payable nonReentrant returns (uint256) {
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

        // min amount to receive
        uint256 minAmount = amount - MathEx.mulDivF(amount, _slippagePPM, PPM_RESOLUTION);

        // generate oft send param message
        SendParam memory sendParam = SendParam({
            dstEid: DESTINATION_ENDPOINT_ID, // mainnet destination endpoint id
            to: _addressToBytes32(_vault), // vault address on mainnet
            amountLD: amount, // amount to send
            minAmountLD: minAmount, // min amount to send
            extraOptions: bytes(""),
            composeMsg: bytes(""),
            oftCmd: bytes("") // taxi mode (direct transfer)
        });

        // get amount received quote
        (, , OFTReceipt memory receipt) = _stargate.quoteOFT(sendParam);
        uint256 amountReceived = receipt.amountReceivedLD;

        // validate sufficient amount received
        if (amountReceived < minAmount) {
            revert InsufficientAmountReceived(amountReceived, minAmount);
        }

        // get the messaging fee for the bridge transaction
        MessagingFee memory messagingFee = _stargate.quoteSend(sendParam, false);
        // calculate the value to send with the tx
        uint256 valueToSend = messagingFee.nativeFee;

        // validate sufficient native token sent
        if (msg.value < valueToSend) {
            revert InsufficientNativeTokenSent();
        }

        // add the amount to send to the bridge if the token is native
        if (_stargate.token() == address(0x0)) {
            valueToSend += sendParam.amountLD;
        }

        // approve token if not approved
        _setPlatformAllowance(_withdrawToken, address(_stargate), sendParam.amountLD);

        // bridge the token to the mainnet vault
        (, receipt, ) = _stargate.sendToken{ value: valueToSend }(sendParam, messagingFee, msg.sender);

        // refund user if excess native token sent
        if (msg.value > messagingFee.nativeFee) {
            payable(msg.sender).sendValue(msg.value - messagingFee.nativeFee);
        }

        emit TokensBridged(msg.sender, _withdrawToken, amount);

        return receipt.amountReceivedLD;
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
    function setWithdrawToken(Token newWithdrawToken) external onlyAdmin validAddress(Token.unwrap(newWithdrawToken)) {
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
    function _setPlatformAllowance(Token token, address platform, uint256 inputAmount) private {
        if (token.isNative()) {
            return;
        }
        uint256 allowance = token.toIERC20().allowance(address(this), platform);
        if (allowance < inputAmount) {
            // increase allowance to the max amount if allowance < inputAmount
            token.forceApprove(platform, type(uint256).max);
        }
    }

    /**
     * @dev converts an address to bytes32
     */
    function _addressToBytes32(address _addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
