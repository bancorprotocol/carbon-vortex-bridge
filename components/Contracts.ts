/* eslint-disable camelcase */
import {
    VortexStargateBridge__factory,
    VortexAcrossBridge__factory,
    OptimizedTransparentUpgradeableProxy__factory
} from '../typechain-types';
import { deployOrAttach } from './ContractBuilder';
import { Signer } from 'ethers';

export * from '../typechain-types';

const getContracts = (signer?: Signer) => ({
    connect: (signer: Signer) => getContracts(signer),

    VortexStargateBridge: deployOrAttach('VortexStargateBridge', VortexStargateBridge__factory, signer),
    VortexAcrossBridge: deployOrAttach('VortexAcrossBridge', VortexAcrossBridge__factory, signer),
    OptimizedTransparentUpgradeableProxy: deployOrAttach(
        'OptimizedTransparentUpgradeableProxy',
        OptimizedTransparentUpgradeableProxy__factory,
        signer
    )
});

export type ContractsType = ReturnType<typeof getContracts>;

export default getContracts();
