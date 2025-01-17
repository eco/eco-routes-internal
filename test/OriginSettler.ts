import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import {
  TestERC20,
  IntentSource,
  TestProver,
  Inbox,
  Eco7683OriginSettler,
} from '../typechain-types'
import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { keccak256, BytesLike, ZeroAddress } from 'ethers'
import { encodeIdentifier, encodeTransfer } from '../utils/encode'
import {
  encodeReward,
  encodeRoute,
  hashIntent,
  intentVaultAddress,
  Call,
  TokenAmount,
  Route,
  Reward,
  Intent,
} from '../utils/intent'
import { OnchainCrossChainOrderStruct } from '../typechain-types/contracts/Eco7683OriginSettler'
import { OnchainCrosschainOrderData } from '../utils/EcoEIP7683'
import exp from 'constants'

describe('Origin Settler Test', (): void => {
  let originSettler: Eco7683OriginSettler
  let intentSource: IntentSource
  let prover: TestProver
  let inbox: Inbox
  let tokenA: TestERC20
  let tokenB: TestERC20
  let creator: SignerWithAddress
  let claimant: SignerWithAddress
  let otherPerson: SignerWithAddress
  const mintAmount: number = 1000

  let salt: BytesLike
  let chainId: number
  let calls: Call[]
  let expiry: number
  const rewardNativeEth: bigint = ethers.parseEther('2')
  let rewardTokens: TokenAmount[]
  let route: Route
  let reward: Reward
  let intent: Intent
  let routeHash: BytesLike
  let rewardHash: BytesLike
  let intentHash: BytesLike
  let onchainCrosschainOrder: OnchainCrossChainOrderStruct
  let onchainCrosschainOrderData: OnchainCrosschainOrderData

  const onchainCrosschainOrderTypehash: BytesLike = "19a2c716a34145b8ff3a5a548a03718f6b228a3c87a94a9314a627d1746ea6d9"
  const gaslessCrosschainOrderTypehash: BytesLike = "44e582ef7cc7484b33a2721670194e16869b333e96968b6eaab920fc1f1960c3"

  async function deploySourceFixture(): Promise<{
    originSettler: Eco7683OriginSettler
    intentSource: IntentSource
    prover: TestProver
    tokenA: TestERC20
    tokenB: TestERC20
    creator: SignerWithAddress
    claimant: SignerWithAddress
    otherPerson: SignerWithAddress
  }> {
    const [creator, owner, claimant, otherPerson] = await ethers.getSigners()
    // deploy prover
    prover = await (await ethers.getContractFactory('TestProver')).deploy()

    const intentSourceFactory = await ethers.getContractFactory('IntentSource')
    const intentSource = await intentSourceFactory.deploy()
    inbox = await (
      await ethers.getContractFactory('Inbox')
    ).deploy(owner.address, false, [owner.address])

    const originSettlerFactory = await ethers.getContractFactory(
      'Eco7683OriginSettler',
    )
    const originSettler = await originSettlerFactory.deploy(
      await intentSource.getAddress(),
    )

    // deploy ERC20 test
    const erc20Factory = await ethers.getContractFactory('TestERC20')
    const tokenA = await erc20Factory.deploy('A', 'A')
    const tokenB = await erc20Factory.deploy('B', 'B')

    return {
      originSettler,
      intentSource,
      prover,
      tokenA,
      tokenB,
      creator,
      claimant,
      otherPerson,
    }
  }

  async function mintAndApprove() {
    await tokenA.connect(creator).mint(creator.address, mintAmount)
    await tokenB.connect(creator).mint(creator.address, mintAmount * 2)

    await tokenA.connect(creator).approve(originSettler, mintAmount)
    await tokenB.connect(creator).approve(originSettler, mintAmount * 2)
  }

  beforeEach(async (): Promise<void> => {
    ;({
      originSettler,
      intentSource,
      prover,
      tokenA,
      tokenB,
      creator,
      claimant,
      otherPerson,
    } = await loadFixture(deploySourceFixture))

    // fund the creator and approve it to create an intent
    await mintAndApprove()
  })

  it('constructs', async () => {
    expect(await originSettler.INTENT_SOURCE()).to.be.eq(
      await intentSource.getAddress(),
    )
  })

  describe('intent creation', async () => {
    beforeEach(async (): Promise<void> => {
      expiry = (await time.latest()) + 123
      chainId = 1
      calls = [
        {
          target: await tokenA.getAddress(),
          data: await encodeTransfer(creator.address, mintAmount),
          value: 0,
        },
      ]
      rewardTokens = [
        { token: await tokenA.getAddress(), amount: mintAmount },
        { token: await tokenB.getAddress(), amount: mintAmount * 2 },
      ]
      salt = await encodeIdentifier(
        0,
        (await ethers.provider.getNetwork()).chainId,
      )
      route = {
        salt: salt,
        source: Number(
          (await originSettler.runner?.provider?.getNetwork())?.chainId,
        ),
        destination: chainId,
        inbox: await inbox.getAddress(),
        calls: calls,
      }
      reward = {
        creator: creator.address,
        prover: await prover.getAddress(),
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }
      routeHash = keccak256(encodeRoute(route))
      rewardHash = keccak256(encodeReward(reward))
      intentHash = keccak256(
        ethers.solidityPacked(['bytes32', 'bytes32'], [routeHash, rewardHash]),
      )

      onchainCrosschainOrderData = {
        route: route,
        creator: creator.address,
        prover: await prover.getAddress(),
        nativeValue: rewardNativeEth,
        tokens: rewardTokens,
        addRewards: true,
      }

      onchainCrosschainOrder = {
        fillDeadline: expiry,
        orderDataType: onchainCrosschainOrderTypehash,
        orderData: onchainCrosschainOrderData
      }
    })

    it('creates via open', async () => {
      await intentSource
        .connect(creator)
        .publishIntent(
          { route, reward: { ...reward, nativeValue: rewardNativeEth } },
          true,
          { value: rewardNativeEth },
        )
      expect(
        await intentSource.validateIntent({
          route,
          reward: { ...reward, nativeValue: rewardNativeEth },
        }),
      ).to.be.true
    })
    it('emits open event', async () => {
      const intent = {
        route,
        reward: { ...reward, nativeValue: rewardNativeEth },
      }
      const { intentHash } = hashIntent(intent)

      await expect(
        intentSource
          .connect(creator)
          .publishIntent(intent, true, { value: rewardNativeEth }),
      )
        .to.emit(intentSource, 'IntentCreated')
        .withArgs(
          intentHash,
          salt,
          Number((await intentSource.runner?.provider?.getNetwork())?.chainId),
          chainId,
          await inbox.getAddress(),
          calls.map(Object.values),
          await creator.getAddress(),
          await prover.getAddress(),
          expiry,
          rewardNativeEth,
          rewardTokens.map(Object.values),
        )
    })
  })
})
