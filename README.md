# Oveview

Carbon Vortex bridge is a permissionless contract created to bridge funds from different L2-deployed CarbonVortex instances to the mainnet Carbon Vault.  

## Setup

As a first step of contributing to the repo, you should install all the required dependencies via:

```sh
pnpm install
```

You will also need to create and update the `.env` file if you’d like to interact or run the unit tests against mainnet forks (see [.env.example](./.env.example))

## Testing

Testing the protocol is possible via multiple approaches:

### Unit Tests

You can run the full test suite via:

```sh
pnpm test
```

### Deployment Tests

You can test new deployments (and the health of the network) against a mainnet fork via:

```sh
pnpm test:deploy
```

This will automatically be skipped on an already deployed and configured deployment scripts and will only test the additional changeset resulting by running any new/pending deployment scripts and perform an e2e test against the up to date state. This is especially useful to verify that any future deployments and upgrades, suggested by the DAO, work correctly and preserve the integrity of the system.

### Test Coverage

#### Latest Test Coverage Report (2025-16-01)

-   100% Statements 73/73
-   100% Branches 11/11
-   100% Functions 15/15
-   100% Lines 77/77

```
╭------------------------------------------------------------+------------------+------------------+-----------------+-----------------╮
| File                                                       | % Lines          | % Statements     | % Branches      | % Funcs         |
+======================================================================================================================================+
| contracts/bridge/CarbonVortexBridge.sol                    | 100.00% (77/77)  | 100.00% (73/73)  | 100.00% (11/11) | 100.00% (15/15) |╰------------------------------------------------------------+------------------+------------------+-----------------+-----------------╯
```

#### Instructions

In order to audit the test coverage of the full test suite, run:

```sh
pnpm coverage
```

To generate a coverage report, run:

```sh
pnpm coverage:report
```

## Deployments

The contracts have built-in support for deployments on different chains and mainnet forks, powered by the awesome [hardhat-deploy](https://github.com/wighawag/hardhat-deploy) framework (tip of the hat to @wighawag for the crazy effort him and the rest of the contributors have put into the project).

You can deploy the fully configured Carbon protocol on any network by setting up the `HARDHAT_NETWORK` environmental variable in .env and running:

```sh
pnpm deploy:prepare && pnpm deploy:network
```

The deployment artifacts are going to be in `deployments/{network_name}`.

If deploying a licensed deployment on a network, it's recommended to fork the carbon-contracts repo and push the deployment artifacts into the fork after deployment.  

You can make changes to the deployment scripts by modifying them in `deploy/scripts/network` and you can add specific network data in `data/named-accounts.ts` (Relevant to Carbon Vortex)  

If you want to verify the contracts after deployment, please set up the `VERIFY_API_KEY` environmental variable to the etherscan api key.

There’s also a special deployment mode which deploys the protocol to a tenderly fork. You should set up `TENDERLY_NETWORK_NAME` to the network name in .env and run:

```sh
pnpm deploy:fork
```

You can also deploy the protocol to a tenderly testnet. You should set up `TENDERLY_NETWORK_NAME` to the network name in .env and run:

```sh
pnpm deploy:testnet
```

## Community

-   [Twitter](https://twitter.com/carbondefixyz)
-   [Telegram](https://t.me/CarbonDeFixyz)
-   [Discord](https://discord.gg/aMVTbrmgD7)
-   [YouTube](https://www.youtube.com/c/BancorProtocol)
