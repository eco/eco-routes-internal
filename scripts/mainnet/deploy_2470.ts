import { ethers, network } from 'hardhat'
import {
  SingletonFactory__factory,
  SingletonFactory,
} from '../../typechain-types'
import { networks, actors } from '../../config/mainnet/config'

const singletonAddress = '0xce0042b868300000d44a59004da54a005ffdcf9f'
const networkName = network.name
console.log('Deploying to Network: ', network.name)
let counter: number
let minimumDuration: number
switch (networkName) {
  case 'base':
    counter = networks.base.intentSource.counter
    minimumDuration = networks.base.intentSource.minimumDuration
    break
  case 'optimism':
    counter = networks.optimism.intentSource.counter
    minimumDuration = networks.optimism.intentSource.minimumDuration
    break
  default:
    counter = 0
    minimumDuration = 0
    break
}
console.log('Counter: ', counter)

console.log('Deploying to Network: ', network.name)

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log('Deploying contracts with the account:', deployer.address)
  console.log(`**************************************************`)
  const singletonFactory: SingletonFactory = SingletonFactory__factory.connect(
    singletonAddress,
    deployer,
  )
  const baseChainConfiguration = {
    chainId: networks.base.chainId, // chainId
    chainConfiguration: {
      provingMechanism: networks.base.proving.mechanism, // provingMechanism
      settlementChainId: networks.base.proving.settlementChain.id, // settlementChainId
      settlementContract: networks.base.proving.settlementChain.contract, // settlementContract e.g DisputGameFactory or L2OutputOracle.
      blockhashOracle: networks.base.proving.l1BlockAddress, // blockhashOracle
      outputRootVersionNumber: networks.base.proving.outputRootVersionNumber, // outputRootVersionNumber
    },
  }

  const optimismChainConfiguration = {
    chainId: networks.optimism.chainId, // chainId
    chainConfiguration: {
      provingMechanism: networks.optimism.proving.mechanism, // provingMechanism
      settlementChainId: networks.optimism.proving.settlementChain.id, // settlementChainId
      settlementContract: networks.optimism.proving.settlementChain.contract, // settlementContract e.g DisputGameFactory or L2OutputOracle.     blockhashOracle: networks.optimism.proving.l1BlockAddress,
      blockhashOracle: networks.optimism.proving.l1BlockAddress, // blockhashOracle
      outputRootVersionNumber:
        networks.optimism.proving.outputRootVersionNumber, // outputRootVersionNumber
    },
  }

  let bytecode
  const proverFactory = await ethers.getContractFactory('Prover')
  bytecode = await proverFactory.getDeployTransaction([
    baseChainConfiguration,
    optimismChainConfiguration,
  ])
  await singletonFactory.deploy(
    bytecode.data,
    ethers.sha256(ethers.toUtf8Bytes('zevthegod')),
    { gasLimit: 4_000_000 },
  )
  console.log('prover implementation deployed')

  const intentSourceFactory = await ethers.getContractFactory('IntentSource')
  bytecode = await intentSourceFactory.getDeployTransaction(
    minimumDuration,
    counter,
  )
  await singletonFactory.deploy(
    bytecode.data,
    ethers.sha256(ethers.toUtf8Bytes('zevthegod')),
    { gasLimit: 4_000_000 },
  )
  console.log('intentSource deployed')

  const inboxFactory = await ethers.getContractFactory('Inbox')

  bytecode = await inboxFactory.getDeployTransaction(
    actors.inboxOwner,
    false,
    actors.solvers,
  )

  await singletonFactory.deploy(
    bytecode.data,
    ethers.sha256(ethers.toUtf8Bytes('zevthegod')),
    { gasLimit: 4_000_000 },
  )
  console.log('Inbox deployed')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
