import dotenv from 'dotenv'
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

  /// get the latest block timestamps for optimism ///

  const optimismTimestamp = await optimismProvider
    .getBlock('latest')
    .then((block) => {
      if (!block) throw new Error('Failed to fetch optimism block')
      return block.timestamp
    })

  /// full intent flow going from Optimism to Base ///

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

  console.log(
    `🔄  intent published on optimism at intent source address ${network_info.optimism.intentSource} going to Inbox at ${network_info.base.inbox}`,
  )
  console.log(
    `🔄  intent requested ${network_info.base.usdcAmount} Base USDC to be transferred to address ${baseWallet.address} for ${network_info.optimism.usdcRewardAmount} Optimism USDC reward`,
  )
  console.log('🔄  transaction hash: ', intentTxOptimism.hash)
  console.log('🔄  intent hash: ', intentHash)
}
}
