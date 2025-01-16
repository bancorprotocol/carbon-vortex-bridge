/* eslint-disable camelcase */
import { CarbonVortexBridge__factory, TransparentUpgradeableProxyImmutable__factory } from '../typechain-types';
import { deployOrAttach } from './ContractBuilder';
import { Signer } from 'ethers';

export * from '../typechain-types';

const getContracts = (signer?: Signer) => ({
    connect: (signer: Signer) => getContracts(signer),

    CarbonVortexBridge: deployOrAttach('CarbonVortexBridge', CarbonVortexBridge__factory, signer),
    TransparentUpgradeableProxyImmutable: deployOrAttach(
        'TransparentUpgradeableProxyImmutable',
        TransparentUpgradeableProxyImmutable__factory,
        signer
    )
});

export type ContractsType = ReturnType<typeof getContracts>;

export default getContracts();
