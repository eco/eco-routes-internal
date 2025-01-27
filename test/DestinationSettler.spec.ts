import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { TestERC20, Inbox, TestMailbox, TestProver } from '../typechain-types'
import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { encodeTransfer, encodeTransferNative } from '../utils/encode'
import { keccak256, BytesLike } from 'ethers'
import {
  encodeReward,
  encodeRoute,
  hashIntent,
  Call,
  Route,
  Reward,
  Intent,
} from '../utils/intent'
import { OnchainCrossChainOrderStruct } from '../typechain-types/contracts/Eco7683OriginSettler'
import {
  OnchainCrosschainOrderData,
  encodeOnchainCrosschainOrderData,
} from '../utils/EcoEIP7683'

describe('Inbox Test', (): void => {
  let inbox: Inbox
  let erc20: TestERC20
  let owner: SignerWithAddress
  let creator: SignerWithAddress
  let solver: SignerWithAddress
  let dstAddr: SignerWithAddress
  let route: Route
  let reward: Reward
  let intent: Intent
  let rewardHash: string
  let intentHash: string
  let prover: TestProver
  let onchainCrosschainOrder: OnchainCrossChainOrderStruct
  let onchainCrosschainOrderData: OnchainCrosschainOrderData
  const salt = ethers.encodeBytes32String('0x987')
  let erc20Address: string
  const timeDelta = 1000
  const mintAmount = 1000
  const sourceChainID = 123
  const onchainCrosschainOrderDataTypehash: BytesLike =
    '0xb6bc9eb3454e4ec88a42b6355c90dc6c1d654f0d544ba0ef3161593210a01a28'

  async function deployInboxFixture(): Promise<{
    inbox: Inbox
    mailbox: TestMailbox
    prover: TestProver
    erc20: TestERC20
    owner: SignerWithAddress
    creator: SignerWithAddress
    solver: SignerWithAddress
    dstAddr: SignerWithAddress
  }> {
    const mailbox = await (
      await ethers.getContractFactory('TestMailbox')
    ).deploy(ethers.ZeroAddress)
    const [owner, creator, solver, dstAddr] = await ethers.getSigners()
    const inboxFactory = await ethers.getContractFactory('Inbox')
    const inbox = await inboxFactory.deploy(owner.address, false, [
      solver.address,
    ])
    const prover = await (
      await ethers.getContractFactory('TestProver')
    ).deploy()
    // deploy ERC20 test
    const erc20Factory = await ethers.getContractFactory('TestERC20')
    const erc20 = await erc20Factory.deploy('eco', 'eco')
    await erc20.mint(solver.address, mintAmount)

    return {
      inbox,
      mailbox,
      prover,
      erc20,
      owner,
      creator,
      solver,
      dstAddr,
    }
  }

  async function createIntentData(
    amount: number,
    timeDelta: number,
  ): Promise<{
    calls: Call[]
    route: Route
    reward: Reward
    intent: Intent
    routeHash: string
    rewardHash: string
    intentHash: string
  }> {
    erc20Address = await erc20.getAddress()
    const _calldata = await encodeTransfer(dstAddr.address, amount)
    const _timestamp = (await time.latest()) + timeDelta

    const _calls: Call[] = [
      {
        target: erc20Address,
        data: _calldata,
        value: 0,
      },
    ]
    const _route = {
      salt,
      source: sourceChainID,
      destination: Number((await owner.provider.getNetwork()).chainId),
      inbox: await inbox.getAddress(),
      calls: _calls,
    }
    const _routeHash = keccak256(encodeRoute(_route))

    const _reward = {
      creator: creator.address,
      prover: solver.address,
      deadline: _timestamp,
      nativeValue: 0n,
      tokens: [
        {
          token: erc20Address,
          amount: amount,
        },
      ],
    }

    const _rewardHash = keccak256(encodeReward(_reward))

    const _intent = {
      route: _route,
      reward: _reward,
    }

    const _intentHash = keccak256(
      ethers.solidityPacked(['bytes32', 'bytes32'], [_routeHash, _rewardHash]),
    )

    return {
      calls: _calls,
      route: _route,
      reward: _reward,
      intent: _intent,
      routeHash: _routeHash,
      rewardHash: _rewardHash,
      intentHash: _intentHash,
    }
  }
  async function createIntentDataNative(
    amount: number,
    timeDelta: number,
  ): Promise<{
    calls: Call[]
    route: Route
    reward: Reward
    intent: Intent
    routeHash: string
    rewardHash: string
    intentHash: string
  }> {
    const _calldata = await encodeTransferNative(dstAddr.address, amount)
    const _calls: Call[] = [
      {
        target: await inbox.getAddress(),
        data: _calldata,
        value: 0,
      },
    ]
    const _timestamp = (await time.latest()) + timeDelta

    const _route: Route = {
      salt,
      source: sourceChainID,
      destination: Number((await owner.provider.getNetwork()).chainId),
      inbox: await inbox.getAddress(),
      calls: _calls,
    }
    const _reward: Reward = {
      creator: solver.address,
      prover: solver.address,
      deadline: _timestamp,
      nativeValue: BigInt(amount),
      tokens: [],
    }
    const _intent: Intent = {
      route: _route,
      reward: _reward,
    }
    const {
      routeHash: _routeHash,
      rewardHash: _rewardHash,
      intentHash: _intentHash,
    } = hashIntent(_intent)
    return {
      calls: _calls,
      route: _route,
      reward: _reward,
      intent: _intent,
      routeHash: _routeHash,
      rewardHash: _rewardHash,
      intentHash: _intentHash,
    }
  }

  beforeEach(async (): Promise<void> => {
    ;({ inbox, mailbox, prover, erc20, owner, creator, solver, dstAddr } =
      await loadFixture(deployInboxFixture))
    ;({ calls, route, reward, intent, routeHash, rewardHash, intentHash } =
      await createIntentData(mintAmount, timeDelta))

    onchainCrosschainOrderData = {
      route: route,
      creator: creator.address,
      prover: await prover.getAddress(),
      nativeValue: reward.nativeValue,
      tokens: reward.tokens,
    }

    onchainCrosschainOrder = {
      fillDeadline: intent.reward.deadline,
      orderDataType: onchainCrosschainOrderDataTypehash,
      orderData: await encodeOnchainCrosschainOrderData(
        onchainCrosschainOrderData,
      ),
    }
  })

  it('successfully calls storage prover fulfill', async (): Promise<void> => {
    expect(await inbox.fulfilled(intentHash)).to.equal(ethers.ZeroAddress)
    expect(await erc20.balanceOf(solver.address)).to.equal(mintAmount)
    expect(await erc20.balanceOf(dstAddr.address)).to.equal(0)

    // transfer the tokens to the inbox so it can process the transaction
    await erc20.connect(solver).transfer(await inbox.getAddress(), mintAmount)
  })
})
