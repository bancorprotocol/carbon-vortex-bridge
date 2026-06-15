import Logger from '../utils/Logger';
import fs from 'fs';
import path from 'path';
import { run } from 'hardhat';

interface DeploymentArtifact {
    address: string;
    args?: unknown[];
}

// Verifies every contract deployed on the current network (HARDHAT_NETWORK) via `hardhat verify`.
const main = async () => {
    const networkName = process.env.HARDHAT_NETWORK;
    if (!networkName) {
        throw new Error('HARDHAT_NETWORK env variable is not set');
    }

    const deploymentsDir = path.join(__dirname, '..', 'deployments', networkName);
    if (!fs.existsSync(deploymentsDir)) {
        throw new Error(`No deployments found for network "${networkName}"`);
    }

    // collect every deployed contract deduped by address (the main + _Proxy artifacts share the
    // proxy address; _Implementation carries the real source + its constructor args)
    const byAddress = new Map<string, DeploymentArtifact>();
    for (const file of fs.readdirSync(deploymentsDir)) {
        if (!file.endsWith('.json') || file.startsWith('.')) {
            continue;
        }
        const artifact: DeploymentArtifact = JSON.parse(fs.readFileSync(path.join(deploymentsDir, file), 'utf-8'));
        if (!artifact.address) {
            continue;
        }
        const key = artifact.address.toLowerCase();
        if (!byAddress.has(key)) {
            byAddress.set(key, artifact);
        }
    }

    for (const artifact of byAddress.values()) {
        const constructorArguments = artifact.args ?? [];
        Logger.log(`Verifying ${artifact.address} (${constructorArguments.length} constructor args)...`);
        try {
            await run('verify:verify', { address: artifact.address, constructorArguments });
            Logger.log(`✓ verified ${artifact.address}`);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            if (/already verified/i.test(message)) {
                Logger.log(`• already verified ${artifact.address}`);
            } else {
                Logger.error(`✗ failed to verify ${artifact.address}: ${message}`);
            }
        }
    }
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        Logger.error(error);
        process.exit(1);
    });
