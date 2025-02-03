import { deploy, DeployedContracts, InstanceName, setDeploymentMetadata } from '../../../utils/Deploy';
import { DeployFunction } from 'hardhat-deploy/types';
import { ethers } from 'hardhat/internal/lib/hardhat-lib';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { Roles } from '../../../utils/Roles';

const func: DeployFunction = async ({ getNamedAccounts }: HardhatRuntimeEnvironment) => {
    const { deployer, vortex, vault, bridge, withdrawToken, weth } = await getNamedAccounts();

    const slippagePPM = 5000; // 0.5%

    // Deploy Vortex Across Bridge contract
    await deploy({
        name: InstanceName.VortexAcrossBridge,
        from: deployer,
        args: [vortex, bridge, vault, weth],
        proxy: {
            args: [withdrawToken, slippagePPM]
        }
    });

    const vortexAcrossBridge = await DeployedContracts.VortexAcrossBridge.deployed();

    // grant admin permission to the bridge so it can withdraw funds
    const adminSigner = await ethers.getSigner(deployer);
    const vortexInstance = await ethers.getContractAt('VortexAcrossBridge', vortex);
    await vortexInstance.connect(adminSigner).grantRole(Roles.Upgradeable.ROLE_ADMIN, vortexAcrossBridge.address);

    return true;
};

export default setDeploymentMetadata(__filename, func);
