# Deploy the Carbon Vortex Bridge on a network

1. Fill in the .env `HARDHAT_NETWORK` to the network you want to deploy on. Optionally, if you want to verify the contracts on etherscan-supported chains, add `VERIFY_API_KEY`.  
2. Prepare the deployment by calling on the command line `pnpm deploy:prepare` (this command also installs the npm packages)  
3. In the command line, input `pnpm deploy:network`  
4. Your deployment should be ready - see the artifacts in `deployments/${network}`  

# Add a new network to the Carbon Vortex Bridge

1. Add the chain id for the network - in `utils/chainIds.json` - add `"network": "chainId"`  
2. Add the rpc url for the network - in `utils/rpcUrls.json` - add `"network": "rpcUrl"`  
3. Add the network name in the `DeploymentNetwork` enum - in `utils/Constants.ts` - add `"Network": "network"`
4. Add the network in `hardhat.config` - copy-paste one of the networks in the config (like mainnet), and change the Network name

# In case of RPC issues

Replace the rpc url of the network you're using in `utils/rpcUrls.json` with a different one - can use an rpc url from `https://chainlist.org/`

# Supported chains for deployment:

- **Ethereum Mainnet**: 1  
- **Base**: 8453  
- **Blast**: 81457  
- **Celo**: 42220  
- **Fantom**: 250  
- **Mantle**: 5000  
- **Linea**: 59144  
- **Sei**: 1329  
- **Telos**: 40  
- **IOTA**: 8822  
- **Optimism**: 10  
- **Cronos**: 25  
- **Rootstock (RSK)**: 30  
- **Binance Smart Chain (BSC)**: 56  
- **Gnosis (formerly xDai)**: 100  
- **Polygon (formerly Matic)**: 137  
- **Manta**: 169  
- **Hedera**: 295  
- **zkSync**: 324  
- **PulseChain**: 369  
- **Astar**: 592  
- **Metis**: 1088  
- **Moonbeam**: 1284  
- **Kava**: 2222  
- **Canto**: 7700  
- **Klaytn**: 8217  
- **Fusion**: 32659  
- **Mode**: 34443  
- **Arbitrum**: 42161  
- **Avalanche**: 43114  
- **Scroll**: 534352  
- **Sepolia**: 11155111  
- **Aurora**: 1313161554  