/* eslint-disable no-magic-numbers */

const networkIds: any = {
  mainnet: 1,
  optimism: 10,
  base: 8453,
  eco: 8921733,
  1: 'mainnet',
  10: 'optimism',
  8453: 'base',
  8921733: 'eco',
}

const actors: any = {
  deployer: '0x6cae25455BF5fCF19cE737Ad50Ee3BC481fCDdD4',
  intentCreator: '0x448729e46C442B55C43218c6DB91c4633D36dFC0',
  inboxOwner: '0xBc6c49e5CdeC14CBD10478bf56296BD63c6c3F0e',
  solver: '0x7b65Dd8dad147C5DBa896A7c062a477a11a5Ed5E',
  claimant: '0xB4e2a27ed497E2D1aD0C8fB3a47803c934457C58',
  prover: '0x923d4fDfD0Fb231FDA7A71545953Acca41123652',
  recipient: '0xC0Bc9bA69aCD4806c4c48dD6FdFC1677212503e9',
}

const provingMechanisms: any = {
  // self: 0, // Destination is Self
  // settlement: 10, // Source Chain is an L2, Destination is A L1 Settlement Chain
  settlementL3: 11, // Source Chain is an L3, Destination is a L2 Settlement Chain
  // bedrock: 20, // Source Chain is an L2, Destination Chain is an L2 using Bedrock
  // bedrockL2L3: 21, // Source Chain is an L2, Destination Chain is an L3 using Bedrock
  bedrockL3L2: 22, // Source Chain is an L3, Destination Chain is an L2 using Bedrock
  // bedrockL1Settlement: 23, // Source Chain is an L1, settlement chain for the Destination Chain which is an L2 using Bedrock
  bedrockL2Settlement: 24, // Source Chain is the L2, settlement chain for the Destination Chain which is an L3 using Bedrock
  cannon: 30, // Source Chain is an L2, Destination Chain is an L2 using Cannon
  cannonL2L3: 31, // Source Chain is an L2, Destination Chain is an L3 using Cannon
  cannonL3L2: 32, // Source Chain is an L3, Destination Chain is an L2 using Cannon
  // cannonL1Settlement: 33, // Source Chain is an L1 settlement chain for the Destination Chain which is an L2 using Cannon
  // cannonL2Settlement: 34, // Source Chain is the L2 settlement chain for the Destination Chain which is an L3 using Cannon
  hyperProver: 40, // Source Chain is an L2 Destination Chain is an L2 using HyperProver
  // 0: 'self',
  // 10: 'settlement',
  11: 'settlementL3',
  // 20: 'bedrock',
  // 21: 'bedrockL2L3',
  22: 'bedrockL3L2',
  // 23: 'bedrockL1Settlement',
  24: 'bedrockL2Settlement',
  30: 'cannon',
  31: 'cannonL2L3',
  // 32: 'cannonL3L2',
  // 33: 'cannonL1Settlement',
  // 34: 'cannonL2Settlement',
  40: 'hyperProver',
}

const provingState: any = {
  finalized: 0,
  posted: 1,
  confirmed: 2,
  0: 'finalized', // Finalized on Settlement Chain
  1: 'posted', // Posted to Settlement Chain
  2: 'confirmed', // Confirmed Locally
}

// Note intents currently being used are for USDC with a common set of actors
// the other data coming from the network
// Here we store a minimal set of addtional fieds
const intent: any = {
  rewardAmounts: [1001],
  targetAmounts: [1000],
  duration: 3600,
}

const networks: any = {
  mainnet: {
    network: networkIds[1],
    chainId: networkIds.mainnet,
    alchemyNetwork: 'mainnet',
    // The following settlement contracts are useful for event listening
    settlementContracts: {
      base: '0x56315b90c40730925ec5485cf004d835058518A0', // base L2 OUTPUT ORACLE
      optimism: '0xe5965Ab5962eDc7477C8520243A95517CD252fA9', // optimism Dispute Game Factory
    },
  },
  optimism: {
    network: networkIds[10],
    chainId: networkIds.optimism,
    alchemyNetwork: 'optimism',
    sourceChains: ['base', 'eco'],
    proverContract: {
      address: '',
      deploymentBlock: 16795390n, // '0x10046Fe'
    },
    intentSource: {
      address: '',
      deploymentBlock: 16795394n, // '0x1004702
      minimumDuration: 1000,
      counter: 0,
    },
    inbox: {
      address: '',
      deploymentBlock: 18354796n, // '0x118126c
    },
    hyperproverContractAddress: '',
    proving: {
      mechanism: provingMechanisms.cannon,
      l1BlockAddress: '0x4200000000000000000000000000000000000015',
      l2l1MessageParserAddress: '0x4200000000000000000000000000000000000016',
      outputRootVersionNumber: 0,
      l1BlockSlotNumber: 2,
      settlementChain: {
        network: 'mainnet',
        id: networkIds.mainnet,
        contract: '0xe5965Ab5962eDc7477C8520243A95517CD252fA9',
      },
    },
    usdcAddress: '0x0b2c639c533813f4aa9d7837caf62653d097ff85',
    hyperlaneMailboxAddress: '0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D',
  },
  base: {
    network: networkIds[8453],
    chainId: networkIds.base,
    alchemyNetwork: 'base',
    sourceChains: ['optimism', 'eco'],
    proverContract: {
      address: '',
      deploymentBlock: 14812482n, // '0xe20542',
    },
    intentSource: {
      address: '',
      deploymentBlock: 14812485n, // '0xe20545',
      minimumDuration: 1000,
      counter: 0,
    },
    inbox: {
      address: '',
      deploymentBlock: 14812488n, // '0xe20548',
    },
    hyperproverContractAddress: '',
    proving: {
      mechanism: provingMechanisms.bedrock,
      l1BlockAddress: '0x4200000000000000000000000000000000000015',
      l2l1MessageParserAddress: '0x4200000000000000000000000000000000000016',
      l2OutputOracleSlotNumber: 3,
      outputRootVersionNumber: 0,
      l1BlockSlotNumber: 2,
      settlementChain: {
        network: 'mainnet',
        id: networkIds.mainnet,
        // L2 Output Oracle Address
        contract: '0x56315b90c40730925ec5485cf004d835058518A0',
      },
    },
    // The following settlement contracts are useful for event listening
    settlementContracts: {
      eco: '0xf3B21c72BFd684eC459697c48f995CDeb5E5DB9d', // eco L2 Output Oracle
    },
    usdcAddress: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    hyperlaneMailboxAddress: '0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D',
  },
}

const routes: any = [
  // eco to base
  {
    source: {
      chainId: networkIds.eco,
      providerName: 'ecoProvider',
      contracts: {
        intentSourceContract: {
          address: networks.eco.intentSource.address,
          variableName: 'ecoIntentSourceContractIntentCreator',
        },
        proverContract: {
          address: networks.eco.proverContract.address,
          variableName: 'ecoProverContract',
        },
      },
    },
    destination: {
      chainId: networkIds.base,
      providerName: 'baseProvider',
      contracts: {
        inboxContract: {
          address: networks.base.inbox.address,
          variableName: 'baseInboxContractSolver',
        },
        provingMechanism: provingMechanisms.settlementL3,
        provingState: provingState.finalized,
      },
    },
    intent: {
      contracts: {
        rewardToken: {
          address: networks.eco.usdcAddress,
          variableName: 'ecoUSDCContractIntentCreator',
        },
        targetToken: {
          address: networks.base.usdcAddress,
          variableName: 'baseUSDCContractSolver',
        },
      },
      rewardAmounts: intent.rewardAmounts,
      targetAmounts: intent.targetAmounts,
      duration: intent.duration,
    },
  },
  // eco to optimism
  {
    source: {
      chainId: networkIds.eco,
      providerName: 'ecoProvider',
      contracts: {
        intentSourceContract: {
          address: networks.eco.intentSource.address,
          variableName: 'ecoIntentSourceContractIntentCreator',
        },
        proverContract: {
          address: networks.eco.proverContract.address,
          variableName: 'ecoProverContract',
        },
      },
    },
    destination: {
      chainId: networkIds.optimism,
      providerName: 'optimismProvider',
      contracts: {
        inboxContract: {
          address: networks.optimism.inbox.address,
          variableName: 'optimismInboxContractSolver',
        },
      },
      provingMechanism: provingMechanisms.cannonL3L2,
      provingState: provingState.finalized,
    },
    intent: {
      contracts: {
        rewardToken: {
          address: networks.eco.usdcAddress,
          variableName: 'ecoUSDCContractIntentCreator',
        },
        targetToken: {
          address: networks.optimism.usdcAddress,
          variableName: 'optimismUSDCContractSolver',
        },
      },
      rewardAmounts: intent.rewardAmounts,
      targetAmounts: intent.targetAmounts,
      duration: intent.duration,
    },
  },
  // base to optimism
  {
    source: {
      chainId: networkIds.base,
      providerName: 'baseProvider',
      contracts: {
        intentSourceContract: {
          address: networks.base.intentSource.address,
          variableName: 'baseIntentSourceContractIntentCreator',
        },
        proverContract: {
          address: networks.base.proverContract.address,
          variableName: 'baseProverContract',
        },
      },
    },
    destination: {
      chainId: networkIds.optimism,
      providerName: 'optimismProvider',
      contracts: {
        inboxContract: {
          address: networks.optimism.inbox.address,
          variableName: 'optimismInboxContractSolver',
        },
        provingMechanism: provingMechanisms.cannon,
        provingState: provingState.finalized,
      },
    },
    intent: {
      contracts: {
        rewardToken: {
          address: networks.base.usdcAddress,
          variableName: 'baseUSDCContractIntentCreator',
        },
        targetToken: {
          address: networks.optimism.usdcAddress,
          variableName: 'optimismUSDCContractSolver',
        },
      },
      rewardAmounts: intent.rewardAmounts,
      targetAmounts: intent.targetAmounts,
      duration: intent.duration,
    },
  },
  // base to eco
  {
    source: {
      chainId: networkIds.base,
      providerName: 'baseProvider',
      contracts: {
        intentSourceContract: {
          address: networks.base.intentSource.address,
          variableName: 'baseIntentSourceContractIntentCreator',
        },
        proverContract: {
          address: networks.base.proverContract.address,
          variableName: 'baseProverContract',
        },
      },
    },
    destination: {
      chainId: networkIds.eco,
      providerName: 'ecoProvider',
      contracts: {
        inboxContract: {
          address: networks.eco.inbox.address,
          variableName: 'ecoInboxContractSolver',
        },
        provingMechanism: provingMechanisms.bedrockL2SettlementL2Settlement,
        provingState: provingState.finalized,
      },
    },
    intent: {
      contracts: {
        rewardToken: {
          address: networks.base.usdcAddress,
          variableName: 'baseUSDCContractIntentCreator',
        },
        targetToken: {
          address: networks.eco.usdcAddress,
          variableName: 'ecoUSDCContractSolver',
        },
      },
      rewardAmounts: intent.rewardAmounts,
      targetAmounts: intent.targetAmounts,
      duration: intent.duration,
    },
  },
  // optimism to eco
  {
    source: {
      chainId: networkIds.optimism,
      providerName: 'optimismProvider',
      contracts: {
        intentSourceContract: {
          address: networks.optimism.intentSource.address,
          variableName: 'optimismIntentSourceContractIntentCreator',
        },
        proverContract: {
          address: networks.optimism.proverContract.address,
          variableName: 'optimismProverContract',
        },
      },
    },
    destination: {
      chainId: networkIds.eco,
      providerName: 'ecoProvider',
      contracts: {
        inboxContract: {
          address: networks.eco.inbox.address,
          variableName: 'ecoInboxContractSolver',
        },
        provingMechanism: provingMechanisms.bedrockL2L3,
        provingState: provingState.finalized,
      },
    },
    intent: {
      contracts: {
        rewardToken: {
          address: networks.optimism.usdcAddress,
          variableName: 'optimismUSDCContractIntentCreator',
        },
        targetToken: {
          address: networks.eco.usdcAddress,
          variableName: 'ecoUSDCContractSolver',
        },
      },
      rewardAmounts: intent.rewardAmounts,
      targetAmounts: intent.targetAmounts,
      duration: intent.duration,
    },
  },
  // optimism to base
  {
    source: {
      chainId: networkIds.optimism,
      providerName: 'optimismProvider',
      contracts: {
        intentSourceContract: {
          address: networks.optimism.intentSource.address,
          variableName: 'optimismIntentSourceContractIntentCreator',
        },
        proverContract: {
          address: networks.optimism.proverContract.address,
          variableName: 'optimismProverContract',
        },
      },
    },
    destination: {
      chainId: networkIds.base,
      providerName: 'baseProvider',
      contracts: {
        inboxContract: {
          address: networks.base.inbox.address,
          variableName: 'baseInboxContractSolver',
        },
        provingMechanism: provingMechanisms.bedrock,
        provingState: provingState.finalized,
      },
    },
    intent: {
      contracts: {
        rewardToken: {
          address: networks.optimism.usdcAddress,
          variableName: 'optimismUSDCContractIntentCreator',
        },
        targetToken: {
          address: networks.base.usdcAddress,
          variableName: 'baseUSDCContractSolver',
        },
      },
      rewardAmounts: intent.rewardAmounts,
      targetAmounts: intent.targetAmounts,
      duration: intent.duration,
    },
  },
]

export {
  provingMechanisms,
  provingState,
  networkIds,
  intent,
  actors,
  networks,
  routes,
}
