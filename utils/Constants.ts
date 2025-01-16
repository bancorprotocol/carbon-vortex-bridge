import { toPPM, toWei } from './Types';
import Decimal from 'decimal.js';
import { ethers } from 'ethers';

const {
    constants: { AddressZero, MaxUint256 }
} = ethers;

export enum MainnetNetwork {
    Arbitrum = 'arbitrum',
    Astar = 'astar',
    Aurora = 'aurora',
    Avalanche = 'avalanche',
    Base = 'base',
    BSC = 'bsc',
    Blast = 'blast',
    Canto = 'canto',
    Celo = 'celo',
    Cronos = 'cronos',
    Fantom = 'fantom',
    Fusion = 'fusion',
    Gnosis = 'gnosis',
    Hedera = 'hedera',
    Kava = 'kava',
    Klaytn = 'klaytn',
    Linea = 'linea',
    Mainnet = 'mainnet',
    Manta = 'manta',
    Mantle = 'mantle',
    Metis = 'metis',
    Mode = 'mode',
    Moonbeam = 'moonbeam',
    Optimism = 'optimism',
    Polygon = 'polygon',
    PulseChain = 'pulsechain',
    Rootstock = 'rootstock',
    Scroll = 'scroll',
    Telos = 'telos',
    ZkSync = 'zksync',
    Sei = 'sei',
    Iota = 'iota'
}

export enum TestnetNetwork {
    Hardhat = 'hardhat',
    Sepolia = 'sepolia',
    Tenderly = 'tenderly',
    TenderlyTestnet = 'tenderly-testnet'
}

export const DeploymentNetwork = {
    ...MainnetNetwork,
    ...TestnetNetwork
};

export const MAX_UINT256 = MaxUint256;
export const ZERO_BYTES = '0x';
export const ZERO_BYTES32 = '0x0000000000000000000000000000000000000000000000000000000000000000';
export const ZERO_ADDRESS = AddressZero;
export const ZERO_FRACTION = { n: 0, d: 1 };
export const PPM_RESOLUTION = 1_000_000;
export const ARB_CONTRACT_ADDRESS = '0x2bdCC0de6bE1f7D2ee689a0342D76F52E8EFABa3';
export const DEFAULT_DECIMALS = 18;
export const NATIVE_TOKEN_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
export const MIN_BNT_BURN = toWei(30);

export const PROXY_CONTRACT = 'TransparentUpgradeableProxyImmutable';
export const INITIALIZE = 'initialize';
export const POST_UPGRADE = 'postUpgrade';

export enum TradingStatusUpdateReason {
    Default = 0,
    Admin = 1,
    MinLiquidity = 2,
    InvalidState = 3
}

export enum RewardsDistributionType {
    Flat = 0,
    ExpDecay = 1
}

export enum ExchangeId {
    BancorV2 = 1,
    BancorV3 = 2,
    UniswapV2 = 3,
    UniswapV3 = 4,
    Sushiswap = 5,
    Carbon = 6,
    Balancer = 7,
    CarbonPOL = 8
}

export const EXP2_INPUT_TOO_HIGH = new Decimal(16).div(new Decimal(2).ln());

export const LIQUIDITY_GROWTH_FACTOR = 2;
export const BOOTSTRAPPING_LIQUIDITY_BUFFER_FACTOR = 2;
export const DEFAULT_TRADING_FEE_PPM = toPPM(0.2);
export const DEFAULT_NETWORK_FEE_PPM = toPPM(20);
export const DEFAULT_FLASH_LOAN_FEE_PPM = toPPM(0);
export const RATE_MAX_DEVIATION_PPM = toPPM(1);
export const RATE_RESET_BLOCK_THRESHOLD = 100;
export const EMA_AVERAGE_RATE_WEIGHT = 4;
export const EMA_SPOT_RATE_WEIGHT = 1;

export const DEFAULT_AUTO_PROCESS_REWARDS_COUNT = 3;
export const AUTO_PROCESS_MAX_PROGRAMS_FACTOR = 2;
export const SUPPLY_BURN_TERMINATION_THRESHOLD_PPM = toPPM(50);

export enum PoolType {
    Standard = 1
}
