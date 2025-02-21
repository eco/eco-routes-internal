import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { run } from 'hardhat'
import {
  TestERC20,
  IntentSource,
  TestProver,
  Inbox,
  Eco7683OriginSettler,
  Eco7683DestinationSettler
} from '../../typechain-types'
import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { keccak256, BytesLike, Wallet, JsonRpcProvider, ethers } from 'ethers'
import { encodeTransfer } from '../../utils/encode'
import {
    AlchemyProvider,
    AbiCoder,
    BigNumberish,
    toQuantity,
    zeroPadValue,
    Signer,
  } from 'ethers'
  import { encodeTransfer } from '../../utils/encode'
  import { networks, intent, actors } from '../../config/testnet/config'
  import { s } from '../../config/testnet/setup'
  export const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY || ''
import {
  encodeReward,
  encodeRoute,
  Call,
  TokenAmount,
  Route,
  Reward,
} from '../../utils/intent'
import {
  OnchainCrossChainOrderStruct,
  GaslessCrossChainOrderStruct,
  ResolvedCrossChainOrderStruct,
} from '../../typechain-types/contracts/Eco7683OriginSettler'
import {
  GaslessCrosschainOrderData,
  OnchainCrosschainOrderData,
  encodeGaslessCrosschainOrderData,
  encodeOnchainCrosschainOrderData,
} from '../../utils/EcoERC7683'
import * as fs from 'fs'

const intentSourceAddress = '0x205D00EF12B5457C03A565966A3bBf404dd493fa' //op-sepolia
const hyperProverAddress = '0xA32e0B3620D9946c6ee1be6c3C6Ceb5fe3E27174' //op-sepolia
const inboxAddress = '0x99bc55Df1eb02dB64fF20fE457c996b2D53bFf7E' //base-sepolia
const originSettlerAddress = '0xafF66f826C72116622915804f1d85B711dF16553' //op-sepolia

const USDCAddress = '0x5fd84259d66Cd46123540766Be93DFE6D43130D7' //op-sepolia
const USDTAddress = '0x323e78f944A9a1FcF3a10efcC5319DBb0bB6e673' //base-sepolia

let intentSource: IntentSource
let originSettler: Eco7683OriginSettler
let destinationSettler: Inbox

const intentCreatorPK = process.env.INTENT_CREATOR_PRIVATE_KEY || ''
const solverPK = process.env.SOLVER_PRIVATE_KEY || ''
const deployerPK = process.env.DEPLOYER_PRIVATE_KEY || ''


const sourceChainProvider = new AlchemyProvider(
  networks.optimismSepolia.network,
  ALCHEMY_API_KEY,
)

const destinationChainProvider = new AlchemyProvider(
    networks.baseSepolia.network,
    ALCHEMY_API_KEY,
  )

let deployer: Wallet
let solver: Wallet

const intentCreator = new Wallet(intentCreatorPK, sourceChainProvider)
const solverSource = new Wallet(solverPK, sourceChainProvider)
const deployerSource = new Wallet(deployerPK, sourceChainProvider)

const solverDestination = new Wallet(solverPK, destinationChainProvider)
const deployerDestination = new Wallet(deployerPK, destinationChainProvider)

async function deployOriginSettler() {
    deployer = deployerSource
    originSettler = await (await ethers.getContractFactory('Eco7683OriginSettler')).connect(deployer).deploy('Eco7683OriginSettler', '123', intentSourceAddress)
    await originSettler.deploymentTransaction()!.wait()
    const originSettlerAddress = await originSettler.getAddress()
    console.log(`Origin Settler deployed at ${originSettlerAddress}`)

    // await run("verify:verify", {
    //     address: originSettlerAddress,
    //     contract: "contracts/ERC7683/Eco7683OriginSettler.sol:Eco7683OriginSettler",
    //   constructorArguments: ['Eco7683OriginSettler', '123', intentSourceAddress],
    // })
}

async function setup() {
    intentSource = await ethers.getContractAt('IntentSource', intentSourceAddress)
    intentSource.connect(intentCreator)
    destinationSettler = await ethers.getContractAt('Inbox', inboxAddress)
}

async function createIntent() {
    const route: Route = {
        salt: keccak256('abc'),
        source: networks.optimismSepolia.chainId,
        destination: networks.baseSepolia.chainId,
        inbox: inboxAddress,
        tokens: [{
            token: USDTAddress,
            amount: 456,
        }],
        calls: [{
            target: USDTAddress,
            data: await encodeTransfer(intentCreator.address, 456),
            value: 0,
        }]
    }
    const reward: Reward = {
        creator: intentCreator.address,
        prover: hyperProverAddress,
        deadline: await time.latest() + 1000,   
        nativeValue: 1000n,
        tokens: [{
            token: USDCAddress,
            amount: 123,
        }]
    }

}

async function testOpen() {
    await setup()
}

async function testOpenFor() {
    await setup()
}

async function main() {
    deployOriginSettler()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
  })
