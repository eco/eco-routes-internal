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
import { keccak256, BytesLike, ZeroAddress, AbiCoder } from 'ethers'
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
import {
  OnchainCrossChainOrderStruct,
  GaslessCrossChainOrderStruct,
} from '../typechain-types/contracts/Eco7683OriginSettler'
import {
  GaslessCrosschainOrderData,
  OnchainCrosschainOrderData,
  encodeGaslessCrosschainOrderData,
  encodeOnchainCrosschainOrderData,
} from '../utils/EcoEIP7683'
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
  let nonce: number
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
  let gaslessCrosschainOrderData: GaslessCrosschainOrderData
  let gaslessCrosschainOrder: GaslessCrossChainOrderStruct
  let finalHash: BytesLike
  let signature: string

  const name = 'Eco 7683 Origin Settler'
  const version = '1.5.0'

  const onchainCrosschainOrderTypehash: BytesLike =
    '0x70c61a52e3a0f99e3cf285eec63637cf3ddbaa3ff1bc113db9afab85d3ce6941'
  const gaslessCrosschainOrderTypehash: BytesLike =
    '0x0dc54db9269648aac2dbf0a24ec877f6604de7a39d70a932e517955973048850'
  const gaslessCrosschainOrderDataTypehash: BytesLike =
    '0x58c324802ce1459a5182655ed022248fa0d67bc8ecdc1e70c632377791453c20'

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
      name,
      '1.0.0',
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
  {
  }
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
      salt =
        '0x0000000000000000000000000000000000000000000000000000000000000001'
      nonce = 1
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
        nativeValue: rewardNativeEth,
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
        nativeValue: reward.nativeValue,
        tokens: reward.tokens,
      }

      onchainCrosschainOrder = {
        fillDeadline: expiry,
        orderDataType: onchainCrosschainOrderTypehash,
        orderData: await encodeOnchainCrosschainOrderData(
          onchainCrosschainOrderData,
        ),
      }
      gaslessCrosschainOrderData = {
        destination: chainId,
        inbox: await inbox.getAddress(),
        calls: calls,
        prover: await prover.getAddress(),
        nativeValue: reward.nativeValue,
        tokens: reward.tokens,
      }
      gaslessCrosschainOrder = {
        originSettler: await originSettler.getAddress(),
        user: creator.address,
        nonce: nonce,
        originChainId: Number(
          (await originSettler.runner?.provider?.getNetwork())?.chainId,
        ),
        openDeadline: expiry,
        fillDeadline: expiry,
        orderDataType: gaslessCrosschainOrderDataTypehash,
        orderData: await encodeGaslessCrosschainOrderData(
          gaslessCrosschainOrderData,
        ),
      }
      const abiCoder = AbiCoder.defaultAbiCoder()
      const orderDataHash = keccak256(
        await encodeGaslessCrosschainOrderData(gaslessCrosschainOrderData),
      )
      const intermediateHash = keccak256(
        abiCoder.encode(
          [
            'bytes32',
            'address',
            'address',
            'uint256',
            'uint256',
            'uint256',
            'uint256',
            'bytes32',
            'bytes32',
          ],
          [
            gaslessCrosschainOrderTypehash,
            await originSettler.getAddress(),
            creator.address,
            nonce,
            Number(
              (await originSettler.runner?.provider?.getNetwork())?.chainId,
            ),
            expiry,
            expiry,
            gaslessCrosschainOrderDataTypehash,
            orderDataHash,
          ],
        ),
      )

      finalHash = keccak256(
        ethers.solidityPacked(
          ['bytes', 'bytes32', 'bytes32'],
          ['0x1901', await originSettler.domainSeparatorV4(), intermediateHash],
        ),
      )
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
        user: creator.address,
        nonce: nonce,
        originChainId: Number(
          (await originSettler.runner?.provider?.getNetwork())?.chainId,
        ),
        openDeadline: expiry,
        fillDeadline: expiry,
        orderDataType: gaslessCrosschainOrderDataTypehash,
        orderDataHash: keccak256(
          await encodeGaslessCrosschainOrderData(gaslessCrosschainOrderData),
        ),
      }
      signature = await creator.signTypedData(domain, types, values)
    })

    it('creates via open', async () => {
      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      expect(
        await intentSource.isIntentFunded({
          route,
          reward: { ...reward, nativeValue: reward.nativeValue },
        }),
      ).to.be.false

      await tokenA
        .connect(creator)
        .approve(await originSettler.getAddress(), mintAmount)
      await tokenB
        .connect(creator)
        .approve(await originSettler.getAddress(), 2 * mintAmount)

      await expect(
        originSettler
          .connect(creator)
          .open(onchainCrosschainOrder, { value: rewardNativeEth }),
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
          reward.nativeValue,
          rewardTokens.map(Object.values),
        )
        .to.emit(originSettler, 'Open')
      expect(
        await intentSource.isIntentFunded({
          route,
          reward: { ...reward, nativeValue: reward.nativeValue },
        }),
      ).to.be.true
    })

    it('creates via openFor', async () => {
      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      expect(
        await intentSource.isIntentFunded({
          route,
          reward: { ...reward, nativeValue: reward.nativeValue },
        }),
      ).to.be.false

      await tokenA
        .connect(creator)
        .approve(await originSettler.getAddress(), mintAmount)
      await tokenB
        .connect(creator)
        .approve(await originSettler.getAddress(), 2 * mintAmount)

      await expect(
        originSettler
          .connect(otherPerson)
          .openFor(gaslessCrosschainOrder, signature, '0x', {
            value: rewardNativeEth,
          }),
      )
        .to.emit(intentSource, 'IntentCreated')
        .and.to.emit(originSettler, 'Open')

      expect(
        await intentSource.isIntentFunded({
          route,
          reward: { ...reward, nativeValue: reward.nativeValue },
        }),
      ).to.be.true
    })
  })
})
