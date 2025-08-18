import { DeploymentNetwork, NATIVE_TOKEN_ADDRESS, ZERO_ADDRESS } from '../utils/Constants';
import chainIds from '../utils/chainIds.json';

interface EnvOptions {
    TENDERLY_NETWORK_NAME?: string;
}

const { TENDERLY_NETWORK_NAME = 'mainnet' }: EnvOptions = process.env as any as EnvOptions;

const TENDERLY_NETWORK_ID = chainIds[TENDERLY_NETWORK_NAME as keyof typeof chainIds];

const mainnet = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Mainnet]) {
        return {
            [DeploymentNetwork.Mainnet]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Mainnet]: address
    };
};

const base = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Base]) {
        return {
            [DeploymentNetwork.Base]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Base]: address
    };
};

const arbitrum = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Arbitrum]) {
        return {
            [DeploymentNetwork.Arbitrum]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Arbitrum]: address
    };
};

const sepolia = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Sepolia]) {
        return {
            [DeploymentNetwork.Sepolia]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Sepolia]: address
    };
};

const fantom = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Fantom]) {
        return {
            [DeploymentNetwork.Fantom]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Fantom]: address
    };
};

const mantle = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Mantle]) {
        return {
            [DeploymentNetwork.Mantle]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Mantle]: address
    };
};

const linea = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Linea]) {
        return {
            [DeploymentNetwork.Linea]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Linea]: address
    };
};

const blast = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Blast]) {
        return {
            [DeploymentNetwork.Blast]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Blast]: address
    };
};

const celo = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Celo]) {
        return {
            [DeploymentNetwork.Celo]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Celo]: address
    };
};

const sei = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Sei]) {
        return {
            [DeploymentNetwork.Sei]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Sei]: address
    };
};

const telos = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Telos]) {
        return {
            [DeploymentNetwork.Telos]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Telos]: address
    };
};

const iota = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Iota]) {
        return {
            [DeploymentNetwork.Iota]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Iota]: address
    };
};

const coti = (address: string) => {
    if (TENDERLY_NETWORK_ID === chainIds[DeploymentNetwork.Coti]) {
        return {
            [DeploymentNetwork.Coti]: address,
            [DeploymentNetwork.Tenderly]: address,
            [DeploymentNetwork.TenderlyTestnet]: address
        };
    }
    return {
        [DeploymentNetwork.Coti]: address
    };
};

const TestNamedAccounts = {
    ethWhale: {
        ...mainnet('0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf'),
        ...base('0xF977814e90dA44bFA03b6295A0616a897441aceC'),
        ...arbitrum('0xF977814e90dA44bFA03b6295A0616a897441aceC')
    },
    daiWhale: {
        ...mainnet('0xb527a981e1d415AF696936B3174f2d7aC8D11369'),
        ...base('0xe9b14a1Be94E70900EDdF1E22A4cB8c56aC9e10a'),
        ...arbitrum('0xd85E038593d7A098614721EaE955EC2022B9B91B')
    },
    usdcWhale: {
        ...mainnet('0x55FE002aefF02F77364de339a1292923A15844B8'),
        ...base('0x20FE51A9229EEf2cF8Ad9E89d91CAb9312cF3b7A'),
        ...arbitrum('0x489ee077994B6658eAfA855C308275EAd8097C4A')
    },
    wbtcWhale: {
        ...mainnet('0x6daB3bCbFb336b29d06B9C793AEF7eaA57888922'),
        ...arbitrum('0x489ee077994B6658eAfA855C308275EAd8097C4A')
    },
    linkWhale: {
        ...mainnet('0xc6bed363b30DF7F35b601a5547fE56cd31Ec63DA'),
        ...arbitrum('0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530')
    },
    bntWhale: {
        ...mainnet('0x221A0e3C9AcEa6B3f1CC9DfC7063509c89bE7BC3')
    }
};

const TokenNamedAccounts = {
    dai: {
        ...mainnet('0x6B175474E89094C44Da98b954EedeAC495271d0F'),
        ...base('0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb'),
        ...arbitrum('0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1'),
        ...fantom('0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E')
    },
    link: {
        ...mainnet('0x514910771AF9Ca656af840dff83E8264EcF986CA'),
        ...base(ZERO_ADDRESS),
        ...arbitrum('0xf97f4df75117a78c1A5a0DBb814Af92458539FB4'),
        ...fantom('0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E')
    },
    weth: {
        ...mainnet('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'),
        ...base('0x4200000000000000000000000000000000000006'),
        ...blast('0x4300000000000000000000000000000000000004'), // weth
        ...arbitrum('0x82aF49447D8a07e3bd95BD0d56f35241523fBab1'),
        ...fantom('0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83'), // wftm,
        ...mantle('0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8'), // wmnt
        ...linea('0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f'),
        ...coti('0x639aCc80569c5FC83c6FBf2319A6Cc38bBfe26d1') // weth
    },
    usdc: {
        ...mainnet('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'),
        ...base('0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'),
        ...arbitrum('0xaf88d065e77c8cC2239327C5EDb3A432268e5831'),
        ...fantom('0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'),
        ...mantle('0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9')
    },
    wbtc: {
        ...mainnet('0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599'),
        ...base(ZERO_ADDRESS),
        ...arbitrum('0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f'),
        ...fantom(ZERO_ADDRESS),
        ...mantle(ZERO_ADDRESS)
    },
    bnt: {
        ...mainnet('0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C'),
        ...base(ZERO_ADDRESS),
        ...arbitrum(ZERO_ADDRESS),
        ...fantom(ZERO_ADDRESS),
        ...mantle(ZERO_ADDRESS)
    }
};

const BancorNamedAccounts = {
    vault: {
        ...getAddress(mainnet, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(base, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(blast, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(celo, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(fantom, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(mantle, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(linea, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(sei, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(telos, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(iota, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4'),
        ...getAddress(coti, '0x60917e542aDdd13bfd1a7f81cD654758052dAdC4')
    },
    vortex: {
        ...getAddress(mainnet, '0xD053Dcd7037AF7204cecE544Ea9F227824d79801'),
        ...getAddress(base, '0xA4682A2A5Fe02feFF8Bd200240A41AD0E6EaF8d5'),
        ...getAddress(blast, '0x0f54099D787e26c90c487625B4dE819eC5A9BDAA'),
        ...getAddress(celo, '0xa15E3295465439A361dBcac79C1DBCE6Cd01E562'),
        ...getAddress(fantom, '0x4A0c4eF72e0BA9d6A2d34dAD6E794378d9Ad4130'),
        ...getAddress(mantle, '0x59f21012B2E9BA67ce6a7605E74F945D0D4C84EA'),
        ...getAddress(linea, '0x5bCA3389786385a35bca14C2D0582adC6cb2482e'),
        ...getAddress(sei, '0x5715203B16F15d7349Cb1E3537365E9664EAf933'),
        ...getAddress(telos, '0x5E994Ac7d65d81f51a76e0bB5a236C6fDA8dBF9A'),
        ...getAddress(iota, '0xe4816658ad10bF215053C533cceAe3f59e1f1087'),
        ...getAddress(coti, '0x20216f3056BF98E245562940E6c9c65aD9B31271'),
    },
    withdrawToken: {
        ...getAddress(base, NATIVE_TOKEN_ADDRESS),
        ...getAddress(blast, '0x4300000000000000000000000000000000000004'),
        ...getAddress(celo, '0x66803FB87aBd4aaC3cbB3fAd7C3aa01f6F3FB207'),
        ...getAddress(fantom, '0x695921034f0387eAc4e11620EE91b1b15A6A09fE'),
        ...getAddress(mantle, '0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111'),
        ...getAddress(linea, NATIVE_TOKEN_ADDRESS),
        ...getAddress(sei, '0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8'),
        ...getAddress(telos, '0xA0fB8cd450c8Fd3a11901876cD5f17eB47C6bc50'),
        ...getAddress(iota, '0x160345fC359604fC6e70E3c5fAcbdE5F7A9342d8'),
        ...getAddress(coti, '0x639aCc80569c5FC83c6FBf2319A6Cc38bBfe26d1')
    }
};

const BridgeNamedAccounts = {
    bridge: {
        ...getAddress(base, '0xdc181Bd607330aeeBEF6ea62e03e5e1Fb4B6F7C7'),
        ...getAddress(blast, '0x2D509190Ed0172ba588407D4c2df918F955Cc6E1'),
        ...getAddress(celo, '0x796Dff6D74F3E27060B71255Fe517BFb23C93eed'),
        ...getAddress(fantom, '0x86355f02119bdbc28ed6a4d5e0ca327ca7730fff'),
        ...getAddress(mantle, '0x4c1d3Fc3fC3c177c3b633427c2F769276c547463'),
        ...getAddress(linea, '0x81F6138153d473E8c5EcebD3DC8Cd4903506B075'),
        ...getAddress(sei, '0x5c386D85b1B82FD9Db681b9176C8a4248bb6345B'),
        ...getAddress(telos, '0x9c5ebCbE531aA81bD82013aBF97401f5C6111d76'),
        ...getAddress(iota, '0x9c2dc7377717603eB92b2655c5f2E7997a4945BD'),
        ...getAddress(coti, '0x639aCc80569c5FC83c6FBf2319A6Cc38bBfe26d1')
    },
    wormhole: {
        ...getAddress(celo, '0xa321448d90d4e5b0A732867c18eA198e75CAC48E')
    }
};

function getAddress(func: (arg: string) => object | undefined, arg: string): object {
    const result = func(arg);
    return result || {};
}

export const NamedAccounts = {
    deployer: {
        ...mainnet('ledger://0x5bEBA4D3533a963Dedb270a95ae5f7752fA0Fe22'),
        ...getAddress(base, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(blast, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(celo, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(fantom, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(mantle, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(linea, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(sei, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(telos, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        ...getAddress(iota, '0xe01EA58F6DA98488E4C92fD9b3E49607639C5370'),
        default: 0
    },

    ...TokenNamedAccounts,
    ...TestNamedAccounts,
    ...BancorNamedAccounts,
    ...BridgeNamedAccounts
};
