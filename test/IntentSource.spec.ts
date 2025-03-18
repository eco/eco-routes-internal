import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import {
  TestERC20,
  BadERC20,
  IntentSource,
  TestProver,
  Inbox,
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

describe('Intent Source Test', (): void => {
  let intentSource: IntentSource
  let prover: TestProver
  let inbox: Inbox
  let tokenA: TestERC20
  let tokenB: TestERC20
  let creator: SignerWithAddress
  let claimant: SignerWithAddress
  let otherPerson: SignerWithAddress
  const mintAmount: number = 1000
  const minBatcherReward = 12345

  let salt: BytesLike
  let chainId: number
  let routeTokens: TokenAmount[]
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

  async function deploySourceFixture(): Promise<{
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
    ).deploy(owner.address, false, minBatcherReward, [owner.address])

    // deploy ERC20 test
    const erc20Factory = await ethers.getContractFactory('TestERC20')
    const tokenA = await erc20Factory.deploy('A', 'A')
    const tokenB = await erc20Factory.deploy('B', 'B')

    return {
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

    await tokenA.connect(creator).approve(intentSource, mintAmount)
    await tokenB.connect(creator).approve(intentSource, mintAmount * 2)
  }

  beforeEach(async (): Promise<void> => {
    ;({ intentSource, prover, tokenA, tokenB, creator, claimant, otherPerson } =
      await loadFixture(deploySourceFixture))

    // fund the creator and approve it to create an intent
    await mintAndApprove()
  })

  describe('intent creation', async () => {
    beforeEach(async (): Promise<void> => {
      expiry = (await time.latest()) + 123
      chainId = 1
      routeTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]
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
          (await intentSource.runner?.provider?.getNetwork())?.chainId,
        ),
        destination: chainId,
        inbox: await inbox.getAddress(),
        tokens: routeTokens,
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
    })
    it('computes valid intent vault address', async () => {
      const predictedVaultAddress = await intentVaultAddress(
        await intentSource.getAddress(),
        { route, reward },
      )

      const contractVaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      expect(contractVaultAddress).to.eq(predictedVaultAddress)
    })

    it('fails to publish if trying to fund on wrong chain', async () => {
      route = {
        salt: salt,
        source: 12345,
        destination: chainId,
        inbox: await inbox.getAddress(),
        tokens: routeTokens,
        calls: calls,
      }

      await expect(
        intentSource.connect(creator).publishAndFund({ route, reward }, false),
      ).to.be.revertedWithCustomError(intentSource, 'WrongSourceChain')
    })

    it('creates properly with erc20 rewards', async () => {
      await intentSource
        .connect(creator)
        .publishAndFund({ route, reward }, false)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true
    })
    it('creates properly with native token rewards', async () => {
      // send too much reward
      const initialBalanceNative = await ethers.provider.getBalance(
        creator.address,
      )
      await intentSource.connect(creator).publishAndFund(
        {
          route,
          reward: { ...reward, nativeValue: rewardNativeEth },
        },
        false,
        { value: rewardNativeEth * BigInt(2) },
      )
      expect(
        await intentSource.isIntentFunded({
          route,
          reward: { ...reward, nativeValue: rewardNativeEth },
        }),
      ).to.be.true
      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward: { ...reward, nativeValue: rewardNativeEth },
      })
      // checks to see that the excess reward is refunded
      expect(await ethers.provider.getBalance(vaultAddress)).to.eq(
        rewardNativeEth,
      )

      expect(
        (await ethers.provider.getBalance(creator.address)) >
          initialBalanceNative - BigInt(2) * rewardNativeEth,
      ).to.be.true
    })
    it('increments counter and locks up tokens', async () => {
      const initialBalanceA = await tokenA.balanceOf(
        await intentSource.getAddress(),
      )
      const initialBalanceB = await tokenA.balanceOf(
        await intentSource.getAddress(),
      )
      const initialBalanceNative = await ethers.provider.getBalance(
        await intentSource.getAddress(),
      )

      const intent = {
        route,
        reward: { ...reward, nativeValue: rewardNativeEth },
      }

      await intentSource
        .connect(creator)
        .publishAndFund(intent, false, { value: rewardNativeEth })

      expect(
        await tokenA.balanceOf(await intentSource.intentVaultAddress(intent)),
      ).to.eq(Number(initialBalanceA) + rewardTokens[0].amount)
      expect(
        await tokenB.balanceOf(await intentSource.intentVaultAddress(intent)),
      ).to.eq(Number(initialBalanceB) + rewardTokens[1].amount)
      expect(
        await ethers.provider.getBalance(
          await intentSource.intentVaultAddress(intent),
        ),
      ).to.eq(initialBalanceNative + rewardNativeEth)
    })
    it('emits events', async () => {
      const intent = {
        route,
        reward: { ...reward, nativeValue: rewardNativeEth },
      }
      const { intentHash } = hashIntent(intent)

      await expect(
        intentSource
          .connect(creator)
          .publishAndFund(intent, false, { value: rewardNativeEth }),
      )
        .to.emit(intentSource, 'IntentCreated')
        .withArgs(
          intentHash,
          salt,
          Number((await intentSource.runner?.provider?.getNetwork())?.chainId),
          chainId,
          await inbox.getAddress(),
          routeTokens.map(Object.values),
          calls.map(Object.values),
          await creator.getAddress(),
          await prover.getAddress(),
          expiry,
          rewardNativeEth,
          rewardTokens.map(Object.values),
        )
    })
  })
  describe('claiming rewards', async () => {
    beforeEach(async (): Promise<void> => {
      expiry = (await time.latest()) + 123
      salt = await encodeIdentifier(
        0,
        (await ethers.provider.getNetwork()).chainId,
      )
      chainId = 1
      routeTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]
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

      route = {
        salt: salt,
        source: Number(
          (await intentSource.runner?.provider?.getNetwork())?.chainId,
        ),
        destination: chainId,
        inbox: await inbox.getAddress(),
        tokens: routeTokens,
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

      intent = { route, reward }

      await intentSource
        .connect(creator)
        .publishAndFund(intent, false, { value: rewardNativeEth })
    })
    context('before expiry, no proof', () => {
      it('cant be withdrawn', async () => {
        await expect(
          intentSource.connect(otherPerson).withdrawRewards(routeHash, reward),
        ).to.be.revertedWithCustomError(intentSource, `UnauthorizedWithdrawal`)
      })
    })
    context('before expiry, proof', () => {
      beforeEach(async (): Promise<void> => {
        await prover
          .connect(creator)
          .addProvenIntent(intentHash, await claimant.getAddress())
      })
      it('gets withdrawn to claimant', async () => {
        const initialBalanceA = await tokenA.balanceOf(
          await claimant.getAddress(),
        )
        const initialBalanceB = await tokenB.balanceOf(
          await claimant.getAddress(),
        )

        const initialBalanceNative = await ethers.provider.getBalance(
          await claimant.getAddress(),
        )

        expect(await intentSource.isIntentFunded(intent)).to.be.true

        await intentSource
          .connect(otherPerson)
          .withdrawRewards(routeHash, reward)

        expect(await intentSource.isIntentFunded(intent)).to.be.false
        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
          Number(initialBalanceA) + reward.tokens[0].amount,
        )
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(
          Number(initialBalanceB) + reward.tokens[1].amount,
        )
        expect(
          await ethers.provider.getBalance(await claimant.getAddress()),
        ).to.eq(initialBalanceNative + rewardNativeEth)
      })
      it('emits event', async () => {
        await expect(
          intentSource.connect(otherPerson).withdrawRewards(routeHash, reward),
        )
          .to.emit(intentSource, 'Withdrawal')
          .withArgs(intentHash, await claimant.getAddress())
      })
      it('does not allow repeat withdrawal', async () => {
        await intentSource
          .connect(otherPerson)
          .withdrawRewards(routeHash, reward)
        await expect(
          intentSource.connect(otherPerson).withdrawRewards(routeHash, reward),
        ).to.be.revertedWithCustomError(intentSource, 'RewardsAlreadyWithdrawn')
      })
      it('allows refund if already claimed', async () => {
        expect(
          await intentSource
            .connect(otherPerson)
            .withdrawRewards(routeHash, reward),
        )
          .to.emit(intentSource, 'Withdrawal')
          .withArgs(intentHash, await claimant.getAddress())

        await expect(
          intentSource.connect(otherPerson).refund(routeHash, reward),
        )
          .to.emit(intentSource, 'Refund')
          .withArgs(intentHash, reward.creator)
      })
    })
    context('after expiry, no proof', () => {
      beforeEach(async (): Promise<void> => {
        await time.increaseTo(expiry)
      })
      it('gets refunded to creator', async () => {
        const initialBalanceA = await tokenA.balanceOf(
          await creator.getAddress(),
        )
        const initialBalanceB = await tokenB.balanceOf(
          await creator.getAddress(),
        )
        expect(await intentSource.isIntentFunded(intent)).to.be.true

        await intentSource.connect(otherPerson).refund(routeHash, reward)

        expect(await intentSource.isIntentFunded(intent)).to.be.false
        expect(await tokenA.balanceOf(await creator.getAddress())).to.eq(
          Number(initialBalanceA) + reward.tokens[0].amount,
        )
        expect(await tokenB.balanceOf(await creator.getAddress())).to.eq(
          Number(initialBalanceB) + reward.tokens[1].amount,
        )
      })
    })
    context('after expiry, proof', () => {
      beforeEach(async (): Promise<void> => {
        await prover
          .connect(creator)
          .addProvenIntent(intentHash, await claimant.getAddress())
        await time.increaseTo(expiry)
      })
      it('gets withdrawn to claimant', async () => {
        const initialBalanceA = await tokenA.balanceOf(
          await claimant.getAddress(),
        )
        const initialBalanceB = await tokenB.balanceOf(
          await claimant.getAddress(),
        )
        expect(await intentSource.isIntentFunded(intent)).to.be.true

        await intentSource
          .connect(otherPerson)
          .withdrawRewards(routeHash, reward)

        expect(await intentSource.isIntentFunded(intent)).to.be.false
        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
          Number(initialBalanceA) + reward.tokens[0].amount,
        )
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(
          Number(initialBalanceB) + reward.tokens[1].amount,
        )
      })
    })
  })
  describe('batch withdrawal', async () => {
    describe('fails if', () => {
      beforeEach(async (): Promise<void> => {
        expiry = (await time.latest()) + 123
        salt = await encodeIdentifier(
          0,
          (await ethers.provider.getNetwork()).chainId,
        )
        chainId = 1
        routeTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]
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
        route = {
          salt: salt,
          source: Number(
            (await intentSource.runner?.provider?.getNetwork())?.chainId,
          ),
          destination: chainId,
          inbox: await inbox.getAddress(),
          tokens: routeTokens,
          calls: calls,
        }
        reward = {
          creator: creator.address,
          prover: await prover.getAddress(),
          deadline: expiry,
          nativeValue: rewardNativeEth,
          tokens: rewardTokens,
        }
        ;({ intentHash, routeHash, rewardHash } = hashIntent({ route, reward }))
        intent = { route, reward }

        await intentSource
          .connect(creator)
          .publishAndFund(intent, false, { value: rewardNativeEth })
      })
      it('bricks if called before expiry by IntentCreator', async () => {
        await expect(
          intentSource
            .connect(otherPerson)
            .batchWithdraw([routeHash], [reward]),
        ).to.be.revertedWithCustomError(intentSource, 'UnauthorizedWithdrawal')
      })
    })
    describe('single intent, complex', () => {
      beforeEach(async (): Promise<void> => {
        expiry = (await time.latest()) + 123
        salt = await encodeIdentifier(
          0,
          (await ethers.provider.getNetwork()).chainId,
        )
        chainId = 1
        routeTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]
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
        route = {
          salt: salt,
          source: Number(
            (await intentSource.runner?.provider?.getNetwork())?.chainId,
          ),
          destination: chainId,
          inbox: await inbox.getAddress(),
          tokens: routeTokens,
          calls: calls,
        }
        reward = {
          creator: creator.address,
          prover: await prover.getAddress(),
          deadline: expiry,
          nativeValue: rewardNativeEth,
          tokens: rewardTokens,
        }
        intent = { route, reward }
        ;({ intentHash, routeHash, rewardHash } = hashIntent(intent))

        await intentSource
          .connect(creator)
          .publishAndFund(intent, false, { value: rewardNativeEth })
      })
      it('before expiry to claimant', async () => {
        const initialBalanceNative = await ethers.provider.getBalance(
          await claimant.getAddress(),
        )
        expect(await intentSource.isIntentFunded(intent)).to.be.true
        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(0)
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(0)
        expect(
          await tokenA.balanceOf(await intentSource.intentVaultAddress(intent)),
        ).to.eq(mintAmount)
        expect(
          await tokenB.balanceOf(await intentSource.intentVaultAddress(intent)),
        ).to.eq(mintAmount * 2)
        expect(
          await ethers.provider.getBalance(
            await intentSource.intentVaultAddress(intent),
          ),
        ).to.eq(rewardNativeEth)

        await prover
          .connect(creator)
          .addProvenIntent(intentHash, await claimant.getAddress())
        await intentSource
          .connect(otherPerson)
          .batchWithdraw([routeHash], [reward])

        expect(await intentSource.isIntentFunded(intent)).to.be.false
        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
          mintAmount,
        )
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(
          mintAmount * 2,
        )
        expect(await tokenA.balanceOf(await intentSource.getAddress())).to.eq(0)
        expect(await tokenB.balanceOf(await intentSource.getAddress())).to.eq(0)

        expect(
          await ethers.provider.getBalance(await intentSource.getAddress()),
        ).to.eq(0)

        expect(
          await ethers.provider.getBalance(await claimant.getAddress()),
        ).to.eq(initialBalanceNative + rewardNativeEth)
      })
      it('after expiry to creator', async () => {
        await time.increaseTo(expiry)
        const initialBalanceNative = await ethers.provider.getBalance(
          await creator.getAddress(),
        )
        expect(await intentSource.isIntentFunded(intent)).to.be.true
        expect(await tokenA.balanceOf(await creator.getAddress())).to.eq(0)
        expect(await tokenB.balanceOf(await creator.getAddress())).to.eq(0)

        await prover
          .connect(otherPerson)
          .addProvenIntent(intentHash, await creator.getAddress())
        await intentSource
          .connect(otherPerson)
          .batchWithdraw([routeHash], [reward])

        expect(await intentSource.isIntentFunded(intent)).to.be.false
        expect(await tokenA.balanceOf(await creator.getAddress())).to.eq(
          mintAmount,
        )
        expect(await tokenB.balanceOf(await creator.getAddress())).to.eq(
          mintAmount * 2,
        )
        expect(
          await ethers.provider.getBalance(await creator.getAddress()),
        ).to.eq(initialBalanceNative + rewardNativeEth)
      })
    })
    describe('multiple intents, each with a single reward token', () => {
      beforeEach(async (): Promise<void> => {
        expiry = (await time.latest()) + 123
        salt = await encodeIdentifier(
          0,
          (await ethers.provider.getNetwork()).chainId,
        )
        chainId = 1
        calls = [
          {
            target: await tokenA.getAddress(),
            data: await encodeTransfer(creator.address, mintAmount),
            value: 0,
          },
        ]
      })
      it('same token', async () => {
        let tx
        let salt = route.salt
        const routeHashes: BytesLike[] = []
        const rewards: Reward[] = []
        for (let i = 0; i < 3; ++i) {
          route = {
            ...route,
            salt: (salt = keccak256(salt)),
          }
          rewards.push({
            ...reward,
            nativeValue: 0n,
            tokens: [
              { token: await tokenA.getAddress(), amount: mintAmount / 10 },
            ],
          })
          routeHashes.push(
            hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
          )

          tx = await intentSource
            .connect(creator)
            .publishAndFund({ route, reward: rewards.at(-1)! }, false)
          tx = await tx.wait()
        }
        const logs = await intentSource.queryFilter(
          intentSource.getEvent('IntentCreated'),
        )
        const hashes = logs.map((log) => log.args.hash)

        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(0)

        for (let i = 0; i < 3; ++i) {
          await prover
            .connect(creator)
            .addProvenIntent(hashes[i], await claimant.getAddress())
        }
        await intentSource
          .connect(otherPerson)
          .batchWithdraw(routeHashes, rewards)

        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
          (mintAmount / 10) * 3,
        )
      })
      it('multiple tokens', async () => {
        let tx
        let salt = route.salt
        const routeHashes: BytesLike[] = []
        const rewards: Reward[] = []
        for (let i = 0; i < 3; ++i) {
          route = {
            ...route,
            salt: (salt = keccak256(salt)),
          }
          rewards.push({
            ...reward,
            nativeValue: 0n,
            tokens: [
              { token: await tokenA.getAddress(), amount: mintAmount / 10 },
            ],
          })
          routeHashes.push(
            hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
          )

          tx = await intentSource
            .connect(creator)
            .publishAndFund({ route, reward: rewards.at(-1)! }, false)
          tx = await tx.wait()
        }
        for (let i = 0; i < 3; ++i) {
          route = {
            ...route,
            salt: (salt = keccak256(salt)),
          }
          rewards.push({
            ...reward,
            nativeValue: 0n,
            tokens: [
              {
                token: await tokenB.getAddress(),
                amount: (mintAmount * 2) / 10,
              },
            ],
          })
          routeHashes.push(
            hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
          )

          tx = await intentSource
            .connect(creator)
            .publishAndFund({ route, reward: rewards.at(-1)! }, false)
          tx = await tx.wait()
        }
        const logs = await intentSource.queryFilter(
          intentSource.getEvent('IntentCreated'),
        )
        const hashes = logs.map((log) => log.args.hash)

        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(0)
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(0)

        for (let i = 0; i < 6; ++i) {
          await prover
            .connect(creator)
            .addProvenIntent(hashes[i], await claimant.getAddress())
        }
        await intentSource
          .connect(otherPerson)
          .batchWithdraw(routeHashes, rewards)

        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
          (mintAmount / 10) * 3,
        )
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(
          ((mintAmount * 2) / 10) * 3,
        )
      })
      it('multiple tokens plus native', async () => {
        let tx
        let salt = route.salt
        const routeHashes: BytesLike[] = []
        const rewards: Reward[] = []
        for (let i = 0; i < 3; ++i) {
          route = {
            ...route,
            salt: (salt = keccak256(salt)),
          }
          rewards.push({
            ...reward,
            nativeValue: 0n,
            tokens: [
              { token: await tokenA.getAddress(), amount: mintAmount / 10 },
            ],
          })
          routeHashes.push(
            hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
          )

          tx = await intentSource.connect(creator).publishAndFund(
            {
              route,
              reward: rewards.at(-1)!,
            },
            false,
          )
          tx = await tx.wait()
        }
        for (let i = 0; i < 3; ++i) {
          route = {
            ...route,
            salt: (salt = keccak256(salt)),
          }
          rewards.push({
            ...reward,
            nativeValue: 0n,
            tokens: [
              {
                token: await tokenB.getAddress(),
                amount: (mintAmount * 2) / 10,
              },
            ],
          })
          routeHashes.push(
            hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
          )

          tx = await intentSource.connect(creator).publishAndFund(
            {
              route,
              reward: rewards.at(-1)!,
            },
            false,
          )
          tx = await tx.wait()
        }
        for (let i = 0; i < 3; ++i) {
          route = {
            ...route,
            salt: (salt = keccak256(salt)),
          }
          rewards.push({
            ...reward,
            nativeValue: rewardNativeEth,
            tokens: [],
          })
          routeHashes.push(
            hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
          )

          tx = await intentSource
            .connect(creator)
            .publishAndFund({ route, reward: rewards.at(-1)! }, false, {
              value: rewardNativeEth,
            })
          tx = await tx.wait()
        }
        const logs = await intentSource.queryFilter(
          intentSource.getEvent('IntentCreated'),
        )
        const hashes = logs.map((log) => log.args.hash)

        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(0)
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(0)

        const initialBalanceNative = await ethers.provider.getBalance(
          await claimant.getAddress(),
        )

        for (let i = 0; i < 9; ++i) {
          await prover
            .connect(creator)
            .addProvenIntent(hashes[i], await claimant.getAddress())
        }

        await intentSource
          .connect(otherPerson)
          .batchWithdraw(routeHashes, rewards)

        expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
          (mintAmount / 10) * 3,
        )
        expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(
          ((mintAmount * 2) / 10) * 3,
        )
        expect(
          await ethers.provider.getBalance(await claimant.getAddress()),
        ).to.eq(initialBalanceNative + BigInt(3) * rewardNativeEth)
      })
    })
    it('works in the case of multiple intents, each with multiple reward tokens', async () => {
      expiry = (await time.latest()) + 123
      salt = await encodeIdentifier(
        0,
        (await ethers.provider.getNetwork()).chainId,
      )
      chainId = 1
      routeTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]
      calls = [
        {
          target: await tokenA.getAddress(),
          data: await encodeTransfer(creator.address, mintAmount),
          value: 0,
        },
      ]
      route = {
        salt: salt,
        source: Number(
          (await intentSource.runner?.provider?.getNetwork())?.chainId,
        ),
        destination: chainId,
        inbox: await inbox.getAddress(),
        tokens: routeTokens,
        calls: calls,
      }
      let tx
      let routeHashes: BytesLike[] = []
      let rewards: Reward[] = []
      for (let i = 0; i < 5; ++i) {
        route = {
          ...route,
          salt: (salt = keccak256(salt)),
        }
        rewards.push({
          ...reward,
          nativeValue: 0n,
          tokens: [
            {
              token: await tokenA.getAddress(),
              amount: mintAmount / 10,
            },
          ],
        })
        routeHashes.push(
          hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
        )

        tx = await intentSource.connect(creator).publishAndFund(
          {
            route,
            reward: rewards.at(-1)!,
          },
          false,
        )
        tx = await tx.wait()
      }
      for (let i = 0; i < 5; ++i) {
        route = {
          ...route,
          salt: (salt = keccak256(salt)),
        }
        rewards.push({
          ...reward,
          tokens: [
            {
              token: await tokenA.getAddress(),
              amount: mintAmount / 10,
            },
            {
              token: await tokenB.getAddress(),
              amount: (mintAmount * 2) / 10,
            },
          ],
        })
        routeHashes.push(
          hashIntent({ route, reward: rewards.at(-1)! }).routeHash,
        )

        tx = await intentSource.connect(creator).publishAndFund(
          {
            route,
            reward: rewards.at(-1)!,
          },
          false,
          { value: rewardNativeEth },
        )
        await tx.wait()
      }
      const logs = await intentSource.queryFilter(
        intentSource.getEvent('IntentCreated'),
      )
      const hashes = logs.map((log) => log.args.hash)

      expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(0)
      expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(0)

      const initialBalanceNative = await ethers.provider.getBalance(
        await claimant.getAddress(),
      )

      for (let i = 0; i < hashes.length; ++i) {
        await prover
          .connect(creator)
          .addProvenIntent(hashes[i], await claimant.getAddress())
      }
      await intentSource
        .connect(otherPerson)
        .batchWithdraw(routeHashes, rewards)

      expect(await tokenA.balanceOf(await claimant.getAddress())).to.eq(
        mintAmount,
      )
      expect(await tokenB.balanceOf(await claimant.getAddress())).to.eq(
        mintAmount,
      )
      expect(
        await ethers.provider.getBalance(await claimant.getAddress()),
      ).to.eq(initialBalanceNative + BigInt(5) * rewardNativeEth)
    })
  })

  describe('funding intents', async () => {
    beforeEach(async (): Promise<void> => {
      // Mint tokens to funding source
      await tokenA.connect(creator).mint(creator.address, mintAmount * 2)
      await tokenB.connect(creator).mint(creator.address, mintAmount * 4)
      await tokenA
        .connect(creator)
        .mint(await intentSource.getAddress(), mintAmount)

      rewardTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]

      reward = {
        creator: creator.address,
        prover: otherPerson.address,
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }
      intent = { route, reward }
      ;({ intentHash, routeHash, rewardHash } = hashIntent(intent))
    })

    it('should compute valid intent funder address', async () => {
      const predictedAddress = await intentVaultAddress(
        await intentSource.getAddress(),
        { route, reward },
      )

      const contractAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      expect(contractAddress).to.eq(predictedAddress)
    })

    it('should fund intent with single token', async () => {
      rewardTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]

      reward = {
        creator: creator.address,
        prover: otherPerson.address,
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }

      const intentFunder = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Approve tokens
      await tokenA.connect(creator).approve(intentFunder, mintAmount)

      // Get vault address
      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Fund the intent
      await intentSource
        .connect(creator)
        .fundFor(routeHash, reward, creator.address, ZeroAddress, false)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true

      // Check vault balance
      expect(await tokenA.balanceOf(vaultAddress)).to.equal(mintAmount)
    })

    it('should fund intent with multiple tokens', async () => {
      rewardTokens = [
        { token: await tokenA.getAddress(), amount: mintAmount },
        { token: await tokenB.getAddress(), amount: mintAmount * 2 },
      ]

      reward = {
        creator: creator.address,
        prover: otherPerson.address,
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }

      const intentFunder = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Approve tokens
      await tokenA.connect(creator).approve(intentFunder, mintAmount)
      await tokenB.connect(creator).approve(intentFunder, mintAmount * 2)

      // Get vault address
      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Fund the intent
      await intentSource
        .connect(creator)
        .fundFor(routeHash, reward, creator.address, ZeroAddress, false)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true

      // Check vault balances
      expect(await tokenA.balanceOf(vaultAddress)).to.equal(mintAmount)
      expect(await tokenB.balanceOf(vaultAddress)).to.equal(mintAmount * 2)
    })

    it('should handle partial funding based on allowance', async () => {
      rewardTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]

      reward = {
        creator: creator.address,
        prover: otherPerson.address,
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }

      const intentFunder = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Approve partial amount
      await tokenA.connect(creator).approve(intentFunder, mintAmount / 2)

      // Get vault address
      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Fund the intent
      await intentSource
        .connect(creator)
        .fundFor(routeHash, reward, creator.address, ZeroAddress, true)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.false

      // Check vault balance reflects partial funding
      expect(await tokenA.balanceOf(vaultAddress)).to.equal(mintAmount / 2)
    })

    it('should emit IntentFunded event', async () => {
      const intentFunder = await intentSource.intentVaultAddress({
        route,
        reward,
      })

      // Approve tokens
      await tokenA.connect(creator).approve(intentFunder, mintAmount)

      // Fund the intent and check event
      await expect(
        intentSource
          .connect(creator)
          .fundFor(routeHash, reward, creator.address, ZeroAddress, false),
      )
        .to.emit(intentSource, 'IntentFunded')
        .withArgs(intentHash, creator.address)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true
    })
  })

  describe('edge cases and validations', async () => {
    it('should handle zero token amounts', async () => {
      rewardTokens = [{ token: await tokenA.getAddress(), amount: 0 }]

      reward = {
        creator: creator.address,
        prover: otherPerson.address,
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }

      // Create and fund intent with zero amounts
      await intentSource.connect(creator).publish({ route, reward })

      await intentSource
        .connect(creator)
        .fundFor(routeHash, reward, creator.address, ZeroAddress, false)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true

      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })
      expect(await tokenA.balanceOf(vaultAddress)).to.equal(0)
    })

    it('should handle already funded vaults', async () => {
      rewardTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]

      reward = {
        creator: creator.address,
        prover: otherPerson.address,
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }

      // Create and fund intent initially
      await intentSource
        .connect(creator)
        .publishAndFund({ route, reward }, false)

      // Try to fund again
      await tokenA.connect(creator).approve(intentSource, mintAmount)

      // Should not transfer additional tokens since vault is already funded
      await intentSource
        .connect(creator)
        .fundFor(routeHash, reward, creator.address, ZeroAddress, false)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true

      const vaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })
      expect(await tokenA.balanceOf(vaultAddress)).to.equal(mintAmount)
    })
    it('should handle overfunded vaults', async () => {
      rewardTokens = [{ token: await tokenA.getAddress(), amount: mintAmount }]

      reward = {
        creator: creator.address,
        prover: await prover.getAddress(),
        deadline: expiry,
        nativeValue: 0n,
        tokens: rewardTokens,
      }
      await intentSource
        .connect(creator)
        .publishAndFund({ route, reward }, false)

      expect(await intentSource.isIntentFunded({ route, reward })).to.be.true

      await tokenA.connect(creator).mint(creator.address, mintAmount)
      await tokenA.connect(creator).approve(intentSource, mintAmount)

      // send more tokens
      const intentVaultAddress = await intentSource.intentVaultAddress({
        route,
        reward,
      })
      await tokenA.connect(creator).transfer(intentVaultAddress, mintAmount)

      //mark as proven
      const hash = (await intentSource.getIntentHash({ route, reward }))[0]
      await prover.addProvenIntent(hash, await claimant.getAddress())

      await intentSource.connect(claimant).withdrawRewards(routeHash, reward)
    })
    it('should handle withdraws for rewards with malicious tokens', async () => {
      const initialClaimantBalance = await tokenA.balanceOf(claimant.address)

      const malicious: BadERC20 = await (
        await ethers.getContractFactory('BadERC20')
      ).deploy('malicious', 'MAL', creator.address)
      await malicious.mint(creator.address, mintAmount)
      const badRewardTokens = [
        { token: await malicious.getAddress(), amount: mintAmount },
        { token: await tokenA.getAddress(), amount: mintAmount },
      ]

      const badReward: Reward = {
        creator: creator.address,
        prover: await prover.getAddress(),
        deadline: expiry,
        nativeValue: 0n,
        tokens: badRewardTokens,
      }
      const badVaultAddress = await intentSource.intentVaultAddress({
        route,
        reward: badReward,
      })
      await malicious.connect(creator).transfer(badVaultAddress, mintAmount)
      await tokenA.connect(creator).transfer(badVaultAddress, mintAmount)
      expect(await intentSource.isIntentFunded({ route, reward: badReward })).to
        .be.true

      const badHash = (
        await intentSource.getIntentHash({ route, reward: badReward })
      )[0]
      await prover.addProvenIntent(badHash, await claimant.getAddress())

      await expect(intentSource.withdrawRewards(routeHash, badReward)).to.not.be
        .reverted

      expect(await tokenA.balanceOf(claimant.address)).to.eq(
        initialClaimantBalance + BigInt(mintAmount),
      )
    })
  })
})
