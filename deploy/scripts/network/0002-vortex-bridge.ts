import { deploy, InstanceName, setDeploymentMetadata } from '../../../utils/Deploy';
import { DeployFunction } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';

const func: DeployFunction = async ({ getNamedAccounts }: HardhatRuntimeEnvironment) => {
    const { deployer, vortex, vault, bridge, withdrawToken } = await getNamedAccounts();

    const slippagePPM = 5000; // 0.5%

    // Deploy Vortex Stargate Bridge contract
    await deploy({
        name: InstanceName.VortexStargateBridge,
        from: deployer,
        args: [vortex, bridge, vault],
        proxy: {
            args: [withdrawToken, slippagePPM]
        }
    });

    return true;
};

export default setDeploymentMetadata(__filename, func);
