import dotenv from 'dotenv'
import axios from 'axios'
import { networks } from '../../config/testnet/config'
import { ethers } from 'ethers'
import {
  Call,
  TokenAmount,
  Route,
  Reward,
  Intent,
  encodeRoute,
  encodeReward,
  hashIntent,
  intentFunderAddress,
  intentVaultAddress,
} from '../../utils/intent'
import {
  IntentSource,
  IntentSource__factory,
  Inbox,
  Inbox__factory,
  PolymerProver,
  PolymerProver__factory,
  TestERC20__factory,
} from '../../typechain-types'


interface ProofRequestParams {
  chainId: number
  blockNumber: number
  txIndex: number
  localLogIndex: number
}

async function main() {
  /// network information ///

  dotenv.config()
  const network_info = {
    optimism: {
      inbox: '0x1edaC0905E0E2Dd7Af821A33bB381eeD694D9419',
      prover: '0xb11D3ff286ed86611147C99FD5105Ce659bEe6b7',
      chainId: 10,
      intentSource: '0x58b9e4d5EC0636ADCdA76DF181fa8f73bF930a13',
      usdc: '0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85',
      usdcDecimals: 6,
      usdcAmount: Number(ethers.parseUnits('1.0', 6)),
      usdcRewardAmount: Number(ethers.parseUnits('1.1', 6)),
    },
    base: {
      inbox: '0x3A7cdEFE27102cB45a0B73c42f33a58e087E7987',
      prover: '0xCd0a6b46797258949949596190863EB5b5002E65',
      chainId: 8453,
      intentSource: '0x58b9e4d5EC0636ADCdA76DF181fa8f73bF930a13',
      usdc: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
      usdcDecimals: 6,
      usdcAmount: Number(ethers.parseUnits('1.0', 6)),
      usdcRewardAmount: Number(ethers.parseUnits('1.1', 6)),
    },
  }

  /// bind providers ///

  const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY
  if (!ALCHEMY_API_KEY) {
    throw new Error('ALCHEMY_API_KEY environment variable not found')
  }

  const privateKey = process.env.DEPLOYER_PRIVATE_KEY
  if (!privateKey) {
    throw new Error('DEPLOYER_PRIVATE_KEY environment variable not found')
  }

  console.log('⛓️  connected to optimism...')
  const optimismProvider = new ethers.AlchemyProvider(
    network_info.optimism.chainId,
    ALCHEMY_API_KEY,
  )

  const optimismWallet = new ethers.Wallet(privateKey, optimismProvider)

  console.log('⛓️  connected to base...')
  const baseProvider = new ethers.AlchemyProvider(
    network_info.base.chainId,
    ALCHEMY_API_KEY,
  )

  const baseWallet = new ethers.Wallet(privateKey, baseProvider)

  /// bind the contracts on Optimism mainnet (IntentSource, Inbox, PolymerProver) ///

  console.log('🏗️  binding contracts on optimism...')
  const optimismIntentSource: IntentSource = IntentSource__factory.connect(
    network_info.optimism.intentSource,
    optimismProvider,
  )

  const optimismInbox: Inbox = Inbox__factory.connect(
    network_info.optimism.inbox,
    optimismProvider,
  )

  const optimismPolymerProver: PolymerProver = PolymerProver__factory.connect(
    network_info.optimism.prover,
    optimismProvider,
  )

  /// bind the contracts on Base mainnet (IntentSource, Inbox, PolymerProver) ///

  console.log('🏗️  binding contracts on base...')
  const baseIntentSource: IntentSource = IntentSource__factory.connect(
    network_info.base.intentSource,
    baseProvider,
  )

  const baseInbox: Inbox = Inbox__factory.connect(
    network_info.base.inbox,
    baseProvider,
  )

  const basePolymerProver: PolymerProver = PolymerProver__factory.connect(
    network_info.base.prover,
    baseProvider,
  )

  /// FULL TRANSACTION FLOW 1: intent flow going from Optimism to Base ///

  /// INTENT SOURCE TRANSACTION FLOW ///

  const optimismTimestamp = await optimismProvider
    .getBlock('latest')
    .then((block) => {
      if (!block) throw new Error('Failed to fetch optimism block')
      return block.timestamp
    })

  const transferData = TestERC20__factory.createInterface().encodeFunctionData(
    'transfer',
    [baseWallet.address, network_info.base.usdcAmount],
  )

  const routeTokens: TokenAmount[] = [
    {
      token: network_info.base.usdc,
      amount: network_info.base.usdcAmount,
    },
  ]

  const routeCalls: Call[] = [
    {
      target: network_info.base.usdc,
      data: transferData,
      value: 0,
    },
  ]

  const route: Route = {
    salt: ethers.hexlify(ethers.randomBytes(32)), //unique identifier for the intent
    source: network_info.optimism.chainId, //source chainId
    destination: network_info.base.chainId, //destination chainId
    inbox: network_info.base.inbox, //destination inbox
    tokens: routeTokens, //tokens required for execution of calls on destination chain
    calls: routeCalls, //calls to execute on the destination chain
  }

  const rewardTokens: TokenAmount[] = [
    {
      token: network_info.optimism.usdc,
      amount: network_info.optimism.usdcRewardAmount,
    },
  ]

  const reward: Reward = {
    creator: optimismWallet.address,
    prover: network_info.optimism.prover,
    deadline: optimismTimestamp + 60 * 30, // 30 minutes from now
    nativeValue: BigInt(0),
    tokens: rewardTokens,
  }

  const intent: Intent = {
    route,
    reward,
  }

  const intentTxOptimism = await optimismIntentSource.publishIntent(
    intent,
    true,
  )

  const intentTxReceipt = await intentTxOptimism.wait()
  if (!intentTxReceipt) {
    throw new Error('Transaction failed: No receipt received')
  }

  const intentCreatedEvent = intentTxReceipt.logs.find(
    (log) =>
      log.topics[0] ===
      optimismIntentSource.interface.getEvent('IntentCreated').topicHash,
  )

  if (!intentCreatedEvent) {
    throw new Error('Transaction failed: IntentCreated event not found')
  }

  const intentHash = intentCreatedEvent.topics[1]
  if (!intentHash) {
    throw new Error('Transaction failed: Intent hash not found in event')
  }

  console.log(`🔄  Intent published on optimism at address ${network_info.optimism.intentSource}`)
  console.log(`    Destination Inbox at ${network_info.base.inbox}`)
  console.log(`    Intent Request:  ${network_info.base.usdcAmount}  USDC to address ${baseWallet.address}`)
  console.log(`    Reward:  ${network_info.optimism.usdcRewardAmount} USDC`)
  console.log('    transaction hash: ', intentTxOptimism.hash)
  console.log('    intent hash: ', intentHash)

  const [calcIntentHash, calcRouteHash, calcRewardHash] =
    await optimismIntentSource.getIntentHash(intent)

  if (calcIntentHash !== intentHash) {
    throw new Error('Transaction failed: Intent hash mismatch')
  }

  /// INBOX TRANSACTION FLOW ///

  const baseInboxSolve = await baseInbox.fulfillStorage(
    route,
    calcRewardHash,
    baseWallet.address,
    calcIntentHash,
  )

  const baseInboxTxReceipt = await baseInboxSolve.wait()
  if (!baseInboxTxReceipt) {
    throw new Error('Transaction failed: No receipt received')
  }

  const fulfillmentEvent = baseInboxTxReceipt.logs.find(
    (log) =>
      log.topics[0] ===
      baseInbox.interface.getEvent('Fulfillment').topicHash,
  )

  if (!fulfillmentEvent) {
    throw new Error('Transaction failed: Fulfillment event not found')
  }

  const [eventIntentHash, eventSourceChain, eventClaimant] = [
    fulfillmentEvent.topics[1],
    fulfillmentEvent.topics[2],
    fulfillmentEvent.topics[3]
  ]

  if (!eventIntentHash || !eventSourceChain || !eventClaimant) {
    throw new Error('Transaction failed: Missing event parameters')
  }

  console.log('✅ Fulfillment event emitted:')
  console.log('   Intent Hash:', eventIntentHash)
  console.log('   Source Chain:', eventSourceChain)
  console.log('   Claimant:', eventClaimant)

  /// PROVER TRANSACTION FLOW ///

  const blockNumber = baseInboxTxReceipt.blockNumber;
  if (!blockNumber) {
    throw new Error('Transaction failed: Block number not found in receipt');
  }

  const txIndex = baseInboxTxReceipt.index;
  if (!txIndex) {
    throw new Error('Transaction failed: Transaction index not found in receipt');
  }

  const localLogIndex = baseInboxTxReceipt.logs.findIndex(
    log => log.topics[0] === baseInbox.interface.getEvent('ToBeProven').topicHash
  );
  if (localLogIndex === -1) {
    throw new Error('Transaction failed: ToBeProven event not found in receipt');
  }
  
  const proofRequest = await requestProof({
    chainId: network_info.base.chainId,
    blockNumber,
    txIndex,
    localLogIndex,
  });

  console.log('🚀 Proof request sent:', proofRequest);
  console.log('🔄 Polling for proof generation...');
  
  const proof = await pollForProof(proofRequest.result);
  console.log('📜 Proof details:', proof);
}

async function requestProof({
    chainId,
    blockNumber,
    txIndex,
    localLogIndex,
  }: ProofRequestParams) {
    const POLYMER_API_URL = process.env.POLYMER_API_URL;
    const POLYMER_API_KEY = process.env.POLYMER_API_KEY;
  
    if (!POLYMER_API_URL || !POLYMER_API_KEY) {
      throw new Error('POLYMER_API_URL or POLYMER_API_KEY environment variable not found');
    }
  
    const response = await axios.post(
      POLYMER_API_URL,
      {
        jsonrpc: '2.0',
        id: 1,
        method: 'log_requestProof',
        params: [chainId, blockNumber, txIndex, localLogIndex],
      },
      {
        headers: {
          Authorization: `Bearer ${POLYMER_API_KEY}`,
        },
      }
    );
  
  return response.data
}
async function pollForProof(jobId: string, maxAttempts = 30) {
  const POLYMER_API_URL = process.env.POLYMER_API_URL;
  const POLYMER_API_KEY = process.env.POLYMER_API_KEY;

  if (!POLYMER_API_URL || !POLYMER_API_KEY) {
    throw new Error('POLYMER_API_URL or POLYMER_API_KEY environment variable not found');
  }

  let attempts = 0;
  let proofResponse;

  while (attempts < maxAttempts) {
    proofResponse = await axios.post(
      POLYMER_API_URL,
      {
        jsonrpc: '2.0',
        id: 1,
        method: 'log_queryProof',
        params: [jobId],
      },
      {
        headers: {
          Authorization: `Bearer ${POLYMER_API_KEY}`,
        },
      }
    );

    if (proofResponse?.data?.result?.proof) {
      console.log('✅ Proof generated successfully!');
      return proofResponse.data;
    }

    attempts++;
    console.log(`⏳ Waiting for proof... Attempt ${attempts}/${maxAttempts}`);
    await new Promise(resolve => setTimeout(resolve, 1)); // Wait 2 seconds between attempts
  }

  throw new Error('Proof generation timed out');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });