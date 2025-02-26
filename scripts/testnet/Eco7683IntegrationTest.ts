import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { run } from 'hardhat'
import {
  TestERC20,
  IntentSource,
  TestProver,
  Inbox,
  Eco7683OriginSettler,
  Eco7683DestinationSettler,
  ERC20,
} from '../../typechain-types'
import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import {
  keccak256,
  BytesLike,
  Wallet,
  JsonRpcProvider,
  ethers,
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
import {
  encodeReward,
  encodeRoute,
  Call,
  TokenAmount,
  Intent,
  Route,
  Reward,
} from '../../utils/intent'
import {
  OnchainCrossChainOrderStruct,
  GaslessCrossChainOrderStruct,
  ResolvedCrossChainOrderStruct,
} from '../../typechain-types/contracts/Eco7683OriginSettler'
import {
  OnchainCrosschainOrder,
  GaslessCrosschainOrder,
  GaslessCrosschainOrderData,
  OnchainCrosschainOrderData,
  encodeGaslessCrosschainOrderData,
  encodeOnchainCrosschainOrderData,
  createGaslessCrosschainOrder,
  createOnchainCrosschainOrder,
} from '../../utils/EcoERC7683'
import * as fs from 'fs'
import { erc20 } from '../../typechain-types/@openzeppelin/contracts/token'
export const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY || ''

const intentSourceAddress = '0x205D00EF12B5457C03A565966A3bBf404dd493fa' // op-sepolia
const hyperProverAddress = '0xA32e0B3620D9946c6ee1be6c3C6Ceb5fe3E27174' // op-sepolia
const inboxAddress = '0x99bc55Df1eb02dB64fF20fE457c996b2D53bFf7E' // base-sepolia
const originSettlerAddress = '0xafF66f826C72116622915804f1d85B711dF16553' // op-sepolia

const opUSDCAddress = '0x5fd84259d66Cd46123540766Be93DFE6D43130D7' // op-sepolia
const baseUSDCAddress = '0x5dEaC602762362FE5f135FA5904351916053cF70' // base-sepolia

const usdcAmount = 5
const nativeValue = 12345

let intentSource: IntentSource
let originSettler: Eco7683OriginSettler
let destinationSettler: Inbox
let opUSDC: ERC20
let baseUSDC: ERC20
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

const onchainCrosschainOrderDataTypehash: BytesLike =
  '0x5dd63cf8abd3430c6387c87b7d2af2290ba415b12c3f6fbc10af65f9aee8ec38'
const gaslessCrosschainOrderDataTypehash: BytesLike =
  '0x834338e3ed54385a3fac8309f6f326a71fc399ffb7d77d7366c1e1b7c9feac6f'

async function deployOriginSettler() {
  deployer = deployerSource
  originSettler = await (
    await ethers.getContractFactory('Eco7683OriginSettler')
  )
    .connect(deployer)
    .deploy('Eco7683OriginSettler', '123', intentSourceAddress)
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
  originSettler = await ethers.getContractAt(
    'Eco7683OriginSettler',
    originSettlerAddress,
  )

  opUSDC = await ethers.getContractAt('ERC20', opUSDCAddress)
  baseUSDC = await ethers.getContractAt('ERC20', baseUSDCAddress)

  await opUSDC.connect(intentCreator).approve(originSettlerAddress, usdcAmount)
}

async function createIntent(): Promise<Intent> {
  const route: Route = {
    salt: keccak256('abc'),
    source: networks.optimismSepolia.chainId,
    destination: networks.baseSepolia.chainId,
    inbox: inboxAddress,
    tokens: [
      {
        token: sourceUSDC,
        amount: usdcAmount,
      },
    ],
    calls: [
      {
        target: USDCAddress,
        data: await encodeTransfer(intentCreator.address, 5),
        value: 0,
      },
      {
        target: intentCreator.address,
        data: '0x',
        value: 12345,
      },
    ],
  }
  const reward: Reward = {
    creator: intentCreator.address,
    prover: hyperProverAddress,
    deadline: (await time.latest()) + 10000,
    nativeValue: 12345n,
    tokens: [
      {
        token: USDCAddress,
        amount: 5,
      },
    ],
  }
  return {
    route,
    reward,
  }
}

async function testOpen() {
  await setup()
  const { route, reward } = await createIntent()
  const onchainCrosschain: OnchainCrosschainOrder =
    await createOnchainCrosschainOrder(intent)

  await originSettler.connect(intentCreator).open(onchainCrosschainOrder)

  expect(await intentSource.isIntentFunded(intent)).to.equal(true)
}

async function testOpenFor() {
  await setup()
  const { route, reward } = await createIntent()
  const gaslessCrosschainOrderData = {
    destination: networks.baseSepolia.chainId,
    inbox: await destinationSettler.getAddress(),
    routeTokens: route.tokens,
    calls: route.calls,
    prover: reward.prover,
    nativeValue: reward.nativeValue,
    rewardTokens: reward.tokens,
  }
  const gaslessCrosschainOrder = {
    originSettler: await originSettler.getAddress(),
    user: reward.creator,
    nonce: route.salt,
    originChainId: Number(
      (await originSettler.runner?.provider?.getNetwork())?.chainId,
    ),
    openDeadline: reward.deadline,
    fillDeadline: reward.deadline,
    orderDataType: gaslessCrosschainOrderDataTypehash,
    orderData: await encodeGaslessCrosschainOrderData(
      gaslessCrosschainOrderData,
    ),
  }
  const domainPieces = await originSettler.eip712Domain()
  const domain = {
    name: domainPieces[1],
    version: domainPieces[2],
    chainId: domainPieces[3],
    verifyingContract: domainPieces[4],
  }

  const types = {
    GaslessCrossChainOrder: [
      { name: 'originSettler', type: 'address' },
      { name: 'user', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'originChainId', type: 'uint256' },
      { name: 'openDeadline', type: 'uint32' },
      { name: 'fillDeadline', type: 'uint32' },
      { name: 'orderDataType', type: 'bytes32' },
      { name: 'orderDataHash', type: 'bytes32' },
    ],
  }

  const values = {
    originSettler: await originSettler.getAddress(),
    user: gaslessCrosschainOrder.user,
    nonce: gaslessCrosschainOrder.nonce,
    originChainId: Number(
      (await originSettler.runner?.provider?.getNetwork())?.chainId,
    ),
    openDeadline: gaslessCrosschainOrder.openDeadline,
    fillDeadline: gaslessCrosschainOrder.fillDeadline,
    orderDataType: gaslessCrosschainOrderDataTypehash,
    orderDataHash: keccak256(
      await encodeGaslessCrosschainOrderData(gaslessCrosschainOrderData),
    ),
  }
  const signature = await intentCreator.signTypedData(domain, types, values)

  await originSettler
    .connect(solverSource)
    .openFor(gaslessCrosschainOrder, signature, '0x')

  expect(await intentSource.isIntentFunded(intent)).to.equal(true)
}

async function main() {}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenPool is Ownable {
    // Mapping of allowed tokens
    mapping(address => bool) public allowedTokens;
    
    // Mapping of user balances per token
    mapping(address => mapping(address => uint256)) public balances;

    event TokenAllowed(address indexed token, bool allowed);
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);

    constructor(address[] memory _initialTokens) {
        // Initialize with a predefined list of tokens
        for (uint256 i = 0; i < _initialTokens.length; i++) {
            allowedTokens[_initialTokens[i]] = true;
            emit TokenAllowed(_initialTokens[i], true);
        }
    }

    // Owner can update allowed tokens
    function setAllowedToken(address token, bool allowed) external onlyOwner {
        allowedTokens[token] = allowed;
        emit TokenAllowed(token, allowed);
    }

    // Deposit function
    function deposit(address token, uint256 amount) external {
        require(allowedTokens[token], "Token not allowed");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens from sender to this contract
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update user balance
        balances[msg.sender][token] += amount;

        emit Deposited(msg.sender, token, amount);
    }

    // Withdraw function
    function withdraw(address token, uint256 amount) external {
        require(balances[msg.sender][token] >= amount, "Insufficient balance");

        // Deduct from user balance
        balances[msg.sender][token] -= amount;

        // Transfer tokens back to user
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");

        emit Withdrawn(msg.sender, token, amount);
    }

    // Check balance of a user for a specific token
    function getBalance(address user, address token) external view returns (uint256) {
        return balances[user][token];
    }
}
