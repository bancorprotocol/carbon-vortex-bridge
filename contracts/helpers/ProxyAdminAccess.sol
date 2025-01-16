// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/**
 * @dev contract used to load the ProxyAdmin contract
 * @dev workaround for tenderly verification issues with ethers-v5:
 * @dev https://docs.tenderly.co/contract-verification/hardhat-proxy-contracts#load-the-proxy-contracts
 */
abstract contract ProxyAdminAccess is ProxyAdmin {}
