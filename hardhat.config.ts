import { HardhatUserConfig } from 'hardhat/types';
import '@nomiclabs/hardhat-ethers';
import '@nomicfoundation/hardhat-verify';
import * as tenderly from '@tenderly/hardhat-tenderly';
import '@typechain/hardhat';
import 'hardhat-deploy';
import 'hardhat-dependency-compiler';
import 'dotenv/config';
import 'solidity-coverage';
import 'hardhat-storage-layout';
import '@nomicfoundation/hardhat-chai-matchers';
import 'hardhat-ignore-warnings';
import { DeploymentNetwork } from './utils/Constants';
import { NamedAccounts } from './data/named-accounts';
import chainIds from './utils/chainIds.json';
import rpcUrls from './utils/rpcUrls.json';

tenderly.setup();

interface EnvOptions {
    TENDERLY_TESTNET_PROVIDER_URL?: string;
    HARDHAT_NETWORK?: string;
    PROVIDER_URL?: string;
    NETWORK_ID?: string;
    VERIFY_API_KEY?: string;
    GAS_PRICE?: number | 'auto';
    TENDERLY_IS_FORK?: boolean;
    TENDERLY_FORK_ID?: string;
    TENDERLY_PROJECT?: string;
    TENDERLY_TEST_PROJECT?: string;
    TENDERLY_USERNAME?: string;
    TENDERLY_NETWORK_NAME?: string;
}

const {
    TENDERLY_TESTNET_PROVIDER_URL = '',
    VERIFY_API_KEY = '',
    GAS_PRICE: gasPrice = 'auto',
    TENDERLY_IS_FORK = false,
    TENDERLY_FORK_ID = '',
    TENDERLY_PROJECT = '',
    TENDERLY_TEST_PROJECT = '',
    TENDERLY_USERNAME = '',
    TENDERLY_NETWORK_NAME = DeploymentNetwork.Mainnet
}: EnvOptions = process.env as any as EnvOptions;

const config: HardhatUserConfig = {
    networks: {
        [DeploymentNetwork.Hardhat]: {
            accounts: {
                count: 20,
                accountsBalance: '10000000000000000000000000000000000000000000000'
            },
            allowUnlimitedContractSize: true,
            saveDeployments: false,
            live: false
        },
        [DeploymentNetwork.Mainnet]: {
            chainId: chainIds[DeploymentNetwork.Mainnet],
            url: rpcUrls[DeploymentNetwork.Mainnet],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Mainnet}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Optimism]: {
            chainId: chainIds[DeploymentNetwork.Optimism],
            url: rpcUrls[DeploymentNetwork.Optimism],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Optimism}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Cronos]: {
            chainId: chainIds[DeploymentNetwork.Cronos],
            url: rpcUrls[DeploymentNetwork.Cronos],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Cronos}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Rootstock]: {
            chainId: chainIds[DeploymentNetwork.Rootstock],
            url: rpcUrls[DeploymentNetwork.Rootstock],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Rootstock}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Telos]: {
            chainId: chainIds[DeploymentNetwork.Telos],
            url: rpcUrls[DeploymentNetwork.Telos],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Telos}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.BSC]: {
            chainId: chainIds[DeploymentNetwork.BSC],
            url: rpcUrls[DeploymentNetwork.BSC],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.BSC}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Gnosis]: {
            chainId: chainIds[DeploymentNetwork.Gnosis],
            url: rpcUrls[DeploymentNetwork.Gnosis],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Gnosis}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Polygon]: {
            chainId: chainIds[DeploymentNetwork.Polygon],
            url: rpcUrls[DeploymentNetwork.Polygon],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Polygon}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Fantom]: {
            chainId: chainIds[DeploymentNetwork.Fantom],
            url: rpcUrls[DeploymentNetwork.Fantom],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Fantom}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Hedera]: {
            chainId: chainIds[DeploymentNetwork.Hedera],
            url: rpcUrls[DeploymentNetwork.Hedera],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Hedera}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.ZkSync]: {
            chainId: chainIds[DeploymentNetwork.ZkSync],
            url: rpcUrls[DeploymentNetwork.ZkSync],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.ZkSync}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.PulseChain]: {
            chainId: chainIds[DeploymentNetwork.PulseChain],
            url: rpcUrls[DeploymentNetwork.PulseChain],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.PulseChain}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Astar]: {
            chainId: chainIds[DeploymentNetwork.Astar],
            url: rpcUrls[DeploymentNetwork.Astar],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Astar}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Metis]: {
            chainId: chainIds[DeploymentNetwork.Metis],
            url: rpcUrls[DeploymentNetwork.Metis],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Metis}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Moonbeam]: {
            chainId: chainIds[DeploymentNetwork.Moonbeam],
            url: rpcUrls[DeploymentNetwork.Moonbeam],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Moonbeam}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Kava]: {
            chainId: chainIds[DeploymentNetwork.Kava],
            url: rpcUrls[DeploymentNetwork.Kava],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Kava}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Mantle]: {
            chainId: chainIds[DeploymentNetwork.Mantle],
            url: rpcUrls[DeploymentNetwork.Mantle],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Mantle}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Canto]: {
            chainId: chainIds[DeploymentNetwork.Canto],
            url: rpcUrls[DeploymentNetwork.Canto],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Canto}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Klaytn]: {
            chainId: chainIds[DeploymentNetwork.Klaytn],
            url: rpcUrls[DeploymentNetwork.Klaytn],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Klaytn}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Base]: {
            chainId: chainIds[DeploymentNetwork.Base],
            url: rpcUrls[DeploymentNetwork.Base],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Base}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Fusion]: {
            chainId: chainIds[DeploymentNetwork.Fusion],
            url: rpcUrls[DeploymentNetwork.Fusion],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Fusion}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Mode]: {
            chainId: chainIds[DeploymentNetwork.Mode],
            url: rpcUrls[DeploymentNetwork.Mode],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Mode}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Arbitrum]: {
            chainId: chainIds[DeploymentNetwork.Arbitrum],
            url: rpcUrls[DeploymentNetwork.Arbitrum],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Arbitrum}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Celo]: {
            chainId: chainIds[DeploymentNetwork.Celo],
            url: rpcUrls[DeploymentNetwork.Celo],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Celo}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Avalanche]: {
            chainId: chainIds[DeploymentNetwork.Avalanche],
            url: rpcUrls[DeploymentNetwork.Avalanche],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Avalanche}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Linea]: {
            chainId: chainIds[DeploymentNetwork.Linea],
            url: rpcUrls[DeploymentNetwork.Linea],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Linea}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Scroll]: {
            chainId: chainIds[DeploymentNetwork.Scroll],
            url: rpcUrls[DeploymentNetwork.Scroll],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Scroll}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Aurora]: {
            chainId: chainIds[DeploymentNetwork.Aurora],
            url: rpcUrls[DeploymentNetwork.Aurora],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Aurora}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Sei]: {
            chainId: chainIds[DeploymentNetwork.Sei],
            url: rpcUrls[DeploymentNetwork.Sei],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Sei}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            },
            httpHeaders: { 
                'x-apikey': process.env.SEI_RPC_API_KEY || ''
            }
        },
        [DeploymentNetwork.Blast]: {
            chainId: chainIds[DeploymentNetwork.Blast],
            url: rpcUrls[DeploymentNetwork.Blast],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Blast}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Iota]: {
            chainId: chainIds[DeploymentNetwork.Iota],
            url: rpcUrls[DeploymentNetwork.Iota],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Iota}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Coti]: {
            chainId: chainIds[DeploymentNetwork.Coti],
            url: rpcUrls[DeploymentNetwork.Coti],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Coti}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Tac]: {
            chainId: chainIds[DeploymentNetwork.Tac],
            url: rpcUrls[DeploymentNetwork.Tac],
            gasPrice,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Tac}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Sepolia]: {
            chainId: chainIds[DeploymentNetwork.Sepolia],
            url: rpcUrls[DeploymentNetwork.Sepolia],
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${DeploymentNetwork.Sepolia}`],
            verify: {
                etherscan: {
                    apiKey: VERIFY_API_KEY
                }
            }
        },
        [DeploymentNetwork.Tenderly]: {
            chainId: Number(chainIds[TENDERLY_NETWORK_NAME as keyof typeof chainIds]),
            url: TENDERLY_IS_FORK ? `https://rpc.tenderly.co/fork/${TENDERLY_FORK_ID}` : TENDERLY_TESTNET_PROVIDER_URL,
            autoImpersonate: true,
            saveDeployments: true,
            live: true,
            deploy: [`deploy/scripts/${TENDERLY_NETWORK_NAME}`]
        }
    },

    etherscan: {
        apiKey: VERIFY_API_KEY,
        customChains: [
            {
              network: DeploymentNetwork.Blast,
              chainId: chainIds[DeploymentNetwork.Blast],
              urls: {
                apiURL: "https://api.blastscan.io/api",
                browserURL: "https://blastscan.io"
              }
            },
            {
              network: DeploymentNetwork.Celo,
              chainId: chainIds[DeploymentNetwork.Celo],
              urls: {
                apiURL: "https://api.celoscan.io/api",
                browserURL: "https://celoscan.io"
              }
            },
            {
              network: DeploymentNetwork.Mantle,
              chainId: chainIds[DeploymentNetwork.Mantle],
              urls: {
                apiURL: "https://api.mantlescan.xyz/api",
                browserURL: "https://mantlescan.xyz"
              }
            },
            {
              network: DeploymentNetwork.Linea,
              chainId: chainIds[DeploymentNetwork.Linea],
              urls: {
                apiURL: "https://api.lineascan.build/api",
                browserURL: "https:///lineascan.build"
              }
            },
            {
              network: DeploymentNetwork.Sei,
              chainId: chainIds[DeploymentNetwork.Sei],
              urls: {
                apiURL: "https://seitrace.com/pacific-1/api",
                browserURL: "https://seitrace.com/?chain=pacific-1"
              }
            },
            {
              network: DeploymentNetwork.Iota,
              chainId: chainIds[DeploymentNetwork.Iota],
              urls: {
                apiURL: "https://explorer.evm.iota.org/api",
                browserURL: "https://explorer.evm.iota.org"
              }
            },
            {
              network: DeploymentNetwork.Coti,
              chainId: chainIds[DeploymentNetwork.Coti],
              urls: {
                apiURL: "https://mainnet.cotiscan.io/api",
                browserURL: "https://mainnet.cotiscan.io"
              }
            },
            {
              network: DeploymentNetwork.Tac,
              chainId: chainIds[DeploymentNetwork.Tac],
              urls: {
                apiURL: "https://explorer.tac.build/api",
                browserURL: "https://explorer.tac.build"
              }
            }
          ]
    },

    solidity: {
        compilers: [
            {
                version: '0.8.19',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100_000
                    },
                    metadata: {
                        bytecodeHash: 'none'
                    }
                }
            }
        ]
    },
    paths: {
        deploy: ['deploy/scripts']
    },
    tenderly: {
        forkNetwork: chainIds[TENDERLY_NETWORK_NAME as keyof typeof chainIds].toString(),
        project: TENDERLY_PROJECT || TENDERLY_TEST_PROJECT,
        username: TENDERLY_USERNAME
    },
    dependencyCompiler: {
        paths: [
            '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol',
            'hardhat-deploy/solc_0.8/proxy/OptimizedTransparentUpgradeableProxy.sol'
        ]
    },
    namedAccounts: NamedAccounts,
    external: {
        contracts: [
            {
                artifacts: 'node_modules/@bancor/contracts-solidity/artifacts'
            },
            {
                artifacts: 'node_modules/@bancor/token-governance/artifacts'
            }
        ],
        deployments: {
            [DeploymentNetwork.Mainnet]: [`deployments/${DeploymentNetwork.Mainnet}`],
            [DeploymentNetwork.Base]: [`deployments/${DeploymentNetwork.Base}`],
            [DeploymentNetwork.Arbitrum]: [`deployments/${DeploymentNetwork.Arbitrum}`],
            [DeploymentNetwork.Sepolia]: [`deployments/${DeploymentNetwork.Sepolia}`],
            [DeploymentNetwork.Tenderly]: [`deployments/${DeploymentNetwork.Tenderly}`],
            [DeploymentNetwork.TenderlyTestnet]: [`deployments/${DeploymentNetwork.TenderlyTestnet}`]
        }
    },
    warnings: {
            '*': {
            'transient-storage': 'off'
        },
    }
};

export default config;
