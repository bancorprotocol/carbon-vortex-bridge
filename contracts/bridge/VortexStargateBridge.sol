// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { SendParam, MessagingFee, OFTReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import { IStargate } from "../interfaces/IStargate.sol";
import { Upgradeable } from "../utility/Upgradeable.sol";
import { PPM_RESOLUTION } from "../utility/Utils.sol";
import { MathEx } from "../utility/MathEx.sol";

import { ICarbonVortex } from "../interfaces/ICarbonVortex.sol";
import { VortexBridgeBase } from "./VortexBridgeBase.sol";

/**
 * @dev VortexStargateBridge contract
 */
contract VortexStargateBridge is VortexBridgeBase {
    using SafeERC20 for IERC20;
    using Address for address payable;

    error InsufficientAmountReceived(uint256 amountReceived, uint256 minAmount);
    error InsufficientNativeTokenSent();

    // stargate v2 mainnet destination endpoint id
    uint32 private constant DESTINATION_ENDPOINT_ID = 30101;

    IStargate private immutable _stargate; // stargate v2 bridge pool or oft

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
        // withdraw funds from vortex
        amount = _withdrawVortex(amount);
        // if amount == 0, there is no balance in the vortex
        if (amount == 0) {
            return 0;
        }

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
     * @dev converts an address to bytes32
     */
    function _addressToBytes32(address _addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
