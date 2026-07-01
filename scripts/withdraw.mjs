// Status-aware L2->L1 withdrawal driver for the Celo OP-stack Vortex bridge
// (OptimismPortal2 / OP-Succinct type-42 validity proofs).
//
// Reads the current status of a withdrawal initiated by VortexOpStackBridge.bridge() and takes the
// single next action that is valid right now:
//   waiting-to-prove     -> report (a dispute game covering the L2 block hasn't been posted yet)
//   ready-to-prove       -> proveWithdrawalTransaction on L1 (needs a funded key + L1 ETH)
//   waiting-to-finalize  -> report time remaining in the 7-day proof-maturity window
//   ready-to-finalize    -> finalizeWithdrawalTransaction on L1 (releases L1 WETH to the vault)
//   finalized            -> done
//
// Read-only without a key; pass PRIVATE_KEY=0x... to actually send the prove/finalize tx.
// The same command does the right thing at every stage, so just re-run it as the withdrawal matures.
//
// Usage:
//   node scripts/withdraw.mjs <celo-bridge-tx-hash>
//   PRIVATE_KEY=0x... node scripts/withdraw.mjs <hash>   # to send the prove/finalize tx
//
// Env (pass explicitly on the command line):
//   PRIVATE_KEY       signer key (0x-prefixed); required to send a tx
//   L1_RPC            Ethereum mainnet RPC                     (default publicnode)
//   CELO_RPC          Celo RPC for receipts/status            (default forno)
//   CELO_ARCHIVE_RPC  Celo *archive* RPC for eth_getProof     (default drpc; forno can't serve it)

import { createPublicClient, createWalletClient, http, defineChain } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { mainnet } from 'viem/chains';
import { publicActionsL1, publicActionsL2, walletActionsL1, getWithdrawals } from 'viem/op-stack';

const L1_RPC = process.env.L1_RPC || 'https://ethereum-rpc.publicnode.com';
const CELO_RPC = process.env.CELO_RPC || 'https://forno.celo.org';
// forno does NOT serve eth_getProof — default to a public archive endpoint that does
const CELO_ARCHIVE_RPC = process.env.CELO_ARCHIVE_RPC || 'https://celo.drpc.org';
const WTX = process.env.WTX || process.argv[2];

if (!WTX) {
  console.error('usage: node scripts/withdraw.mjs <celo-bridge-tx-hash>  (or set WTX=...)');
  process.exit(1);
}

// signer key must be passed explicitly via PRIVATE_KEY
const rawKey = (process.env.PRIVATE_KEY || '').trim();
const KEY = rawKey ? (rawKey.startsWith('0x') ? rawKey : `0x${rawKey}`) : undefined;

const celo = defineChain({
  id: 42220,
  name: 'Celo',
  nativeCurrency: { name: 'Celo', symbol: 'CELO', decimals: 18 },
  rpcUrls: { default: { http: [CELO_RPC] } },
  contracts: {
    disputeGameFactory: { [mainnet.id]: { address: '0xFbAC162162f4009Bb007C6DeBC36B1dAC10aF683' } },
    portal: { [mainnet.id]: { address: '0xc5c5D157928BDBD2ACf6d0777626b6C75a9EAEDC' } },
    l1StandardBridge: { [mainnet.id]: { address: '0x9C4955b92F34148dbcfDCD82e9c9eCe5CF2badfe' } },
  },
  sourceId: mainnet.id,
});

const l1 = createPublicClient({ chain: mainnet, transport: http(L1_RPC) }).extend(publicActionsL1());
const l2 = createPublicClient({ chain: celo, transport: http(CELO_RPC) }).extend(publicActionsL2());
// proof generation reads historical L2 state via eth_getProof -> use an archive endpoint
const l2archive = createPublicClient({ chain: celo, transport: http(CELO_ARCHIVE_RPC) }).extend(publicActionsL2());

const account = KEY ? privateKeyToAccount(KEY) : undefined;
const wallet = account
  ? createWalletClient({ account, chain: mainnet, transport: http(L1_RPC) }).extend(walletActionsL1())
  : undefined;

const log = (...a) => console.log(...a);

async function main() {
  const receipt = await l2.getTransactionReceipt({ hash: WTX });
  const [withdrawal] = getWithdrawals(receipt);
  log(`tx ${WTX.slice(0, 12)}…  L2 block ${receipt.blockNumber}  withdrawal ${withdrawal.withdrawalHash.slice(0, 18)}…`);
  log(account ? `signer: ${account.address}` : 'signer: (none — read-only, pass PRIVATE_KEY to send)');

  const status = await l1.getWithdrawalStatus({ receipt, targetChain: celo });
  log(`status: ${status}`);

  switch (status) {
    case 'waiting-to-prove': {
      log('→ no dispute game covers this L2 block yet. Re-run later (tens of min to a few hours).');
      return;
    }

    case 'ready-to-prove': {
      const game = await l1.getGame({ targetChain: celo, l2BlockNumber: receipt.blockNumber });
      log(`→ ready to prove against game index=${game.index} (l2Block=${game.l2BlockNumber})`);
      const proveArgs = await l2archive.buildProveWithdrawal({ account, game, withdrawal });
      if (!wallet) {
        log(`   (dry run — pass PRIVATE_KEY to send) proof nodes=${proveArgs.withdrawalProof?.length}, gameIndex=${proveArgs.l2OutputIndex}`);
        return;
      }
      const hash = await wallet.proveWithdrawal({ ...proveArgs, targetChain: celo });
      log(`   prove tx sent: ${hash}`);
      const r = await l1.waitForTransactionReceipt({ hash });
      log(`   prove ${r.status} in block ${r.blockNumber}. 7-day finalize window starts now.`);
      return;
    }

    case 'waiting-to-finalize': {
      const t = await l1.getTimeToFinalize({ withdrawalHash: withdrawal.withdrawalHash, targetChain: celo });
      const hrs = Number(t.seconds) / 3600;
      log(`→ proven, in the 7-day window. ~${hrs.toFixed(1)}h left (ready at ${new Date(Number(t.timestamp)).toISOString()}).`);
      return;
    }

    case 'ready-to-finalize': {
      if (!wallet) {
        log('→ ready to finalize. (dry run — pass PRIVATE_KEY to send the finalize tx)');
        return;
      }
      const hash = await wallet.finalizeWithdrawal({ targetChain: celo, withdrawal });
      log(`   finalize tx sent: ${hash}`);
      const r = await l1.waitForTransactionReceipt({ hash });
      log(`   finalize ${r.status} in block ${r.blockNumber}. L1 WETH released to the vault.`);
      return;
    }

    case 'finalized': {
      log('→ already finalized. WETH is in the vault.');
      return;
    }

    default:
      log(`→ unhandled status: ${status}`);
  }
}

main().catch((e) => { console.error('FATAL', e.shortMessage || e.message); process.exit(1); });
