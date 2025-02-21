import { SignerWithAddress } from '@nomicfoundation/hardhat-ethers/signers'
import {
  time,
  loadFixture,
} from '@nomicfoundation/hardhat-toolbox/network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import {
  PolymerProver,
  Inbox,
  TestERC20,
  TestCrossL2ProverV2,
} from '../typechain-types'
import { encodeTransfer } from '../utils/encode'
import { hashIntent, TokenAmount } from '../utils/intent'

describe('PolymerProver Test', (): void => {
  let polymerProver: PolymerProver
  let inbox: Inbox
  let testCrossL2ProverV2: TestCrossL2ProverV2
  let owner: SignerWithAddress
  let solver: SignerWithAddress
  let claimant: SignerWithAddress
  let claimant2: SignerWithAddress
  let claimant3: SignerWithAddress
  let chainIds: number[] = [10, 42161];
  let emptyTopics: string = "0x0000000000000000000000000000000000000000000000000000000000000000";
  let emptyData: string = "0x";

  async function deployPolymerProverFixture(): Promise<{
    polymerProver: PolymerProver
    inbox: Inbox
    testCrossL2ProverV2: TestCrossL2ProverV2
    owner: SignerWithAddress
    solver: SignerWithAddress
    claimant: SignerWithAddress
    claimant2: SignerWithAddress
    claimant3: SignerWithAddress
  }> {
    const [owner, solver, claimant, claimant2, claimant3] = await ethers.getSigners()

    const inbox = await (
      await ethers.getContractFactory('Inbox')
    ).deploy(await owner.getAddress(), true, [])

    const testCrossL2ProverV2 = await (
      await ethers.getContractFactory('TestCrossL2ProverV2')
    ).deploy(chainIds[0], await inbox.getAddress(), emptyTopics, emptyData)

    const polymerProver = await (
      await ethers.getContractFactory('PolymerProver')
    ).deploy(await testCrossL2ProverV2.getAddress(), await inbox.getAddress(), chainIds)

    return {
      polymerProver,
      inbox,
      testCrossL2ProverV2,
      owner,
      solver,
      claimant,
      claimant2,
      claimant3
    }
  }

  beforeEach(async (): Promise<void> => {
    ({ polymerProver, inbox, testCrossL2ProverV2, owner, solver, claimant, claimant2, claimant3 } = await loadFixture(deployPolymerProverFixture));
  })
  
  describe('Single emit', (): void => {
    let topics: string[];
    let data: string;
    let expectedHash: string;
    let eventSignature: string;
    let badEventSignature: string;

    beforeEach(async (): Promise<void> => {
        eventSignature = ethers.id('ToBeProven(bytes32,uint256,address)');
        badEventSignature = ethers.id('BadEventSignature(bytes32,uint256,address)');
        expectedHash = '0x' + '11'.repeat(32);
        data = '0x';
        topics = [
            eventSignature, 
            expectedHash, 
            ethers.zeroPadValue(ethers.toBeHex(chainIds[0]), 32), 
            ethers.zeroPadValue(claimant.address, 32)
        ];
  
    })

    it('should validate a single emit', async (): Promise<void> => {
      const topicsPacked = ethers.solidityPacked(
        ["bytes32", "bytes32", "bytes32", "bytes32"],
        topics
      );
      const inboxAddress = await inbox.getAddress();

      // set values for mock prover
      await testCrossL2ProverV2.setAll(
        chainIds[0], 
        inboxAddress,
        topicsPacked, 
        data
      );

      // set values for mock proof index 
      // start at 1 because we have already set the first index in constructor
      const proofIndex = 1;
      const proof = ethers.zeroPadValue(ethers.toBeHex(proofIndex), 32);
      
      // get values from mock prover and ensure they are correct
      const [chainId_returned, emittingContract_returned, topics_returned, data_returned] = 
        await testCrossL2ProverV2.validateEvent(proof);

      expect(chainId_returned).to.equal(chainIds[0]);
      expect(emittingContract_returned).to.equal(inboxAddress);
      expect(topics_returned).to.equal(topicsPacked);
      expect(data_returned).to.equal(data);

      await expect(polymerProver.validate(proof))
        .to.emit(polymerProver, 'IntentProven')
        .withArgs(expectedHash, claimant.address);
    })

  
    it('should emit IntentAlreadyProven if the proof is already proven', async (): Promise<void> => {
      const topicsPacked = ethers.solidityPacked(
        ["bytes32", "bytes32", "bytes32", "bytes32"],
        topics
      );
      const inboxAddress = await inbox.getAddress();

      // set values for mock prover
      await testCrossL2ProverV2.setAll(
        chainIds[0], 
        inboxAddress,
        topicsPacked, 
        data
      );

      // set values for mock proof index 
      // start at 1 because we have already set the first index in constructor
      const proofIndex = 1;
      const proof = ethers.zeroPadValue(ethers.toBeHex(proofIndex), 32);
      
      // get values from mock prover and ensure they are correct
      const [chainId_returned, emittingContract_returned, topics_returned, data_returned] = 
        await testCrossL2ProverV2.validateEvent(proof);

      expect(chainId_returned).to.equal(chainIds[0]);
      expect(emittingContract_returned).to.equal(inboxAddress);
      expect(topics_returned).to.equal(topicsPacked);
      expect(data_returned).to.equal(data);

      await expect(polymerProver.validate(proof))
        .to.emit(polymerProver, 'IntentProven')
        .withArgs(expectedHash, claimant.address);

      await expect(polymerProver.validate(proof))
        .to.emit(polymerProver, 'IntentAlreadyProven')
        .withArgs(expectedHash);
    })

    it('should revert if inbox contract is not the emitting contract', async (): Promise<void> => {
      const topicsPacked = ethers.solidityPacked(
        ["bytes32", "bytes32", "bytes32", "bytes32"],
        topics
      );

      // set values for mock prover
      await testCrossL2ProverV2.setAll(
        chainIds[0], 
        claimant.address,
        topicsPacked, 
        data
      );

      // set values for mock proof index 
      // start at 1 because we have already set the first index in constructor
      const proofIndex = 1;
      const proof = ethers.zeroPadValue(ethers.toBeHex(proofIndex), 32);
      
      // get values from mock prover and ensure they are correct
      const [chainId_returned, emittingContract_returned, topics_returned, data_returned] = 
        await testCrossL2ProverV2.validateEvent(proof);

      expect(chainId_returned).to.equal(chainIds[0]);
      expect(emittingContract_returned).to.equal(claimant.address);
      expect(topics_returned).to.equal(topicsPacked);
      expect(data_returned).to.equal(data);

      await expect(polymerProver.validate(proof))
        .to.be.revertedWithCustomError(polymerProver, 'InvalidEmittingContract');
    })

    it('should revert if chainId is not supported', async (): Promise<void> => {
      const topicsPacked = ethers.solidityPacked(
        ["bytes32", "bytes32", "bytes32", "bytes32"],
        topics
      );
      const inboxAddress = await inbox.getAddress();

      const badChainId = 1234;

      // set values for mock prover
      await testCrossL2ProverV2.setAll(
        badChainId, 
        inboxAddress,
        topicsPacked, 
        data
      );

      // set values for mock proof index 
      // start at 1 because we have already set the first index in constructor
      const proofIndex = 1;
      const proof = ethers.zeroPadValue(ethers.toBeHex(proofIndex), 32);
      
      // get values from mock prover and ensure they are correct
      const [chainId_returned, emittingContract_returned, topics_returned, data_returned] = 
        await testCrossL2ProverV2.validateEvent(proof);

      expect(chainId_returned).to.equal(badChainId);
      expect(emittingContract_returned).to.equal(inboxAddress);
      expect(topics_returned).to.equal(topicsPacked);
      expect(data_returned).to.equal(data);

      await expect(polymerProver.validate(proof))
        .to.be.revertedWithCustomError(polymerProver, 'UnsupportedChainId');
    })

    it('should revert if topics length is not 4', async (): Promise<void> => {
      topics = [
        eventSignature, 
        expectedHash, 
        ethers.zeroPadValue(ethers.toBeHex(chainIds[0]), 32)
    ];

      
      const topicsPacked = ethers.solidityPacked(
        ["bytes32", "bytes32", "bytes32"],
        topics
      );
      const inboxAddress = await inbox.getAddress();

      // set values for mock prover
      await testCrossL2ProverV2.setAll(
        chainIds[0], 
        inboxAddress,
        topicsPacked, 
        data
      );

      // set values for mock proof index 
      // start at 1 because we have already set the first index in constructor
      const proofIndex = 1;
      const proof = ethers.zeroPadValue(ethers.toBeHex(proofIndex), 32);
      
      // get values from mock prover and ensure they are correct
      const [chainId_returned, emittingContract_returned, topics_returned, data_returned] = 
        await testCrossL2ProverV2.validateEvent(proof);

      expect(chainId_returned).to.equal(chainIds[0]);
      expect(emittingContract_returned).to.equal(inboxAddress);
      expect(topics_returned).to.equal(topicsPacked);
      expect(data_returned).to.equal(data);

      await expect(polymerProver.validate(proof))
        .to.be.revertedWithCustomError(polymerProver, 'InvalidTopicsLength');
    })

    it('should revert if event signature is not correct', async (): Promise<void> => {
      topics = [
        badEventSignature, 
        expectedHash, 
        ethers.zeroPadValue(ethers.toBeHex(chainIds[0]), 32),
        ethers.zeroPadValue(claimant.address, 32)
    ];

      const topicsPacked = ethers.solidityPacked(
        ["bytes32", "bytes32", "bytes32", "bytes32"],
        topics
      );
      const inboxAddress = await inbox.getAddress();

      // set values for mock prover
      await testCrossL2ProverV2.setAll(
        chainIds[0], 
        inboxAddress,
        topicsPacked, 
        data
      );

      // set values for mock proof index 
      // start at 1 because we have already set the first index in constructor
      const proofIndex = 1;
      const proof = ethers.zeroPadValue(ethers.toBeHex(proofIndex), 32);
      
      // get values from mock prover and ensure they are correct
      const [chainId_returned, emittingContract_returned, topics_returned, data_returned] = 
        await testCrossL2ProverV2.validateEvent(proof);

      expect(chainId_returned).to.equal(chainIds[0]);
      expect(emittingContract_returned).to.equal(inboxAddress);
      expect(topics_returned).to.equal(topicsPacked);
      expect(data_returned).to.equal(data);

      await expect(polymerProver.validate(proof))
        .to.be.revertedWithCustomError(polymerProver, 'InvalidEventSignature');
    })
  })
})
