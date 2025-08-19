/* eslint-disable camelcase */
import {
    VortexStargateBridge__factory,
    VortexAcrossBridge__factory,
    VortexFantomBridge__factory,
    VortexLayerZeroBridge__factory,
    VortexHyperlaneBridge__factory,
    VortexWormholeBridge__factory,
    OptimizedTransparentUpgradeableProxy__factory
} from '../typechain-types';
import { deployOrAttach } from './ContractBuilder';
import { Signer } from 'ethers';

export * from '../typechain-types';

const getContracts = (signer?: Signer) => ({
    connect: (signer: Signer) => getContracts(signer),

    VortexStargateBridge: deployOrAttach('VortexStargateBridge', VortexStargateBridge__factory, signer),
    VortexAcrossBridge: deployOrAttach('VortexAcrossBridge', VortexAcrossBridge__factory, signer),
    VortexFantomBridge: deployOrAttach('VortexFantomBridge', VortexFantomBridge__factory, signer),
    VortexLayerZeroBridge: deployOrAttach('VortexLayerZeroBridge', VortexLayerZeroBridge__factory, signer),
    VortexHyperlaneBridge: deployOrAttach('VortexHyperlaneBridge', VortexHyperlaneBridge__factory, signer),
    VortexWormholeBridge: deployOrAttach('VortexWormholeBridge', VortexWormholeBridge__factory, signer),
    OptimizedTransparentUpgradeableProxy: deployOrAttach(
        'OptimizedTransparentUpgradeableProxy',
        OptimizedTransparentUpgradeableProxy__factory,
        signer
    )
});

export type ContractsType = ReturnType<typeof getContracts>;

export default getContracts();
