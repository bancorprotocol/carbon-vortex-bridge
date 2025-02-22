// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import { PPM_RESOLUTION, MAX_SLIPPAGE_PPM } from "./Constants.sol";

error AccessDenied();
error InvalidAddress();
error InvalidFee();
error InvalidSlippage();
error ZeroValue();

/**
 * @dev common utilities
 */
abstract contract Utils {
    // allows execution by the caller only
    modifier only(address caller) {
        _only(caller);

        _;
    }

    function _only(address caller) internal view {
        if (msg.sender != caller) {
            revert AccessDenied();
        }
    }

    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 value) {
        _greaterThanZero(value);

        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 value) internal pure {
        if (value == 0) {
            revert ZeroValue();
        }
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address addr) {
        _validAddress(addr);

        _;
    }

    // error message binary size optimization
    function _validAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert InvalidAddress();
        }
    }

    // ensures that the fee is valid
    modifier validFee(uint32 fee) {
        _validFee(fee);

        _;
    }

    // error message binary size optimization
    function _validFee(uint32 fee) internal pure {
        if (fee > PPM_RESOLUTION) {
            revert InvalidFee();
        }
    }

    // ensures that the slippage is valid
    modifier validSlippage(uint32 slippage) {
        _validSlippage(slippage);

        _;
    }

    // error message binary size optimization
    function _validSlippage(uint32 slippage) internal pure {
        if (slippage > MAX_SLIPPAGE_PPM) {
            revert InvalidSlippage();
        }
    }
}
