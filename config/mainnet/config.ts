/* eslint-disable no-magic-numbers */
const provingMechanisms: any = {
  self: 0,
  bedrock: 1,
  cannon: 2,
  nitro: 3,
  hyperProver: 4,
  0: 'self',
  1: 'bedrock',
  2: 'cannon',
  3: 'nitro',
  4: 'hyperProver',
}
const networkIds: any = {
  mainnet: 1,
  optimism: 10,
  base: 8453,
  1: 'mainnet',
  10: 'optimism',
  8453: 'base',
}

const actors: any = {
  deployer: '0xD114A3502dB48Dcf71C447F08Ac9f5B6dA1b43eA',
  intentCreator: '0x448729e46C442B55C43218c6DB91c4633D36dFC0',
  inboxOwner: '0x5219398449a45FD49Daf36F6D3B32416EE66a2f5',
  solvers: [
    '0x3A322Ff8ef24592e5e50D2EB4E630cDA87Bd83A6',
    '0x7b65Dd8dad147C5DBa896A7c062a477a11a5Ed5E',
  ],
  claimant: '0xB4e2a27ed497E2D1aD0C8fB3a47803c934457C58',
  prover: '0x923d4fDfD0Fb231FDA7A71545953Acca41123652',
  recipient: '0xC0Bc9bA69aCD4806c4c48dD6FdFC1677212503e9',
}

// Note intents currently being used are for USDC with a common set of actors
// the other data coming from the network
// Here we store a minimal set of addtional fieds
const intent: any = {
  rewardAmounts: [1001],
  targetAmounts: [1000],
  duration: 3600,
  opBaseBedrock: {
    hash: '0x9fe31be4a2325655dfbd4bb54d83e8b525cfd1a05a19865fcdac7c59a1dbc981',
    fulfillTransaction:
      '0x59036b6f3138471a0b617982319a99ebb5343dc9a43760b1c7a0738e51b1ef7d',
  },
  baseOpCannon: {
    settlementBlockTag: '0x13a303b', // 20590651n
    settlementStateRoot:
      '0x2c8ae6de0f5432d5b06626b19ec08f8948fec8c200a141bfc802dd56c310c668',
    // faultDisputeGame: '0x4D664dd0f78673034b29E4A51177333D1131Ac44',
    faultDisputeGame: {
      address: '0x212B650A940B2C9c924De8AA2c225a06Fca2E3f7',
      creationBlock: '0x139d029', // 20566057n
      resolvedBlock: '0x13a3205', // 20591109n
      gameIndex: 1709,
    },
    hash: '0xfc0b72b6365e7313594d08d4aadf8132b05e9a125318d1a76e7bbf411b3a8611',
    fulfillTransaction:
      '0xb07002c38aa8df7ff282c382057faecea8eaa40d11c6b5ac3b89f32a84c40adb',
  },
}

const networks: any = {
  mainnet: {
    network: 'mainnet',
    chainId: networkIds.mainnet,
    // The following settlement contracts are useful for event listening
    settlementContracts: {
      base: '0x56315b90c40730925ec5485cf004d835058518A0', // base L2 OUTPUT ORACLE
      optimism: '0xe5965Ab5962eDc7477C8520243A95517CD252fA9', // optimism Dispute Game Factory
    },
  },
  optimism: {
    network: 'optimism',
    chainId: networkIds.optimism,
    intentSourceAddress: '0x8b0A7aEeC5D243d0a21b52Edcd943270c006a590',
    proverContractAddress: '0xFB35271eC603A55e0322f77F0C1F3f02804d9156',
    inboxAddress: '0xBAD17e5280eF02c82f6aa26eE3d5E77458e53538',
    intentSource: {
      minimumDuration: 0,
      counter: 0,
    },
    proving: {
      mechanism: provingMechanisms.cannon,
      l1BlockAddress: '0x4200000000000000000000000000000000000015',
      l2l1MessageParserAddress: '0x4200000000000000000000000000000000000016',
      outputRootVersionNumber: 0,
      settlementChain: {
        network: 'mainnet',
        id: networkIds.mainnet,
        contract: '0xe5965Ab5962eDc7477C8520243A95517CD252fA9',
      },
    },
    usdcAddress: '0x0b2c639c533813f4aa9d7837caf62653d097ff85',
  },
  base: {
    network: 'base',
    chainId: networkIds.base,
    intentSourceAddress: '0x8b0A7aEeC5D243d0a21b52Edcd943270c006a590',
    proverContractAddress: '0xFB35271eC603A55e0322f77F0C1F3f02804d9156',
    inboxAddress: '0xBAD17e5280eF02c82f6aa26eE3d5E77458e53538',
    intentSource: {
      minimumDuration: 0,
      counter: 0,
    },
    proving: {
      mechanism: provingMechanisms.bedrock,
      l1BlockAddress: '0x4200000000000000000000000000000000000015',
      l2l1MessageParserAddress: '0x4200000000000000000000000000000000000016',
      l2OutputOracleSlotNumber: 3,
      outputRootVersionNumber: 0,
      settlementChain: {
        network: 'mainnet',
        id: networkIds.mainnet,
        // L2 Output Oracle Address
        contract: '0x56315b90c40730925ec5485cf004d835058518A0',
      },
    },
    usdcAddress: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
  },
}

export { provingMechanisms, networkIds, intent, actors, networks }
