import {
  optimism,
  optimismSepolia,
  base,
  baseSepolia,
  arbitrum,
} from '@alchemy/aa-core'
import {
  abstract,
  abstractTestnet,
  arbitrumSepolia,
  Chain,
  mainnet,
  mantle,
  mantleSepoliaTestnet,
  polygon,
  polygonAmoy,
  sepolia,
} from 'viem/chains'

// Mainnet chains
export const mainnetDep: Chain[] = [
  arbitrum,
  base,
  mantle,
  optimism,
  polygon,
  mainnet,
  abstract,
] as any

// Test chains
export const sepoliaDep: Chain[] = [
  //problamatic
  arbitrumSepolia,
  mantleSepoliaTestnet,
  abstractTestnet,
  //working 
  baseSepolia,
  optimismSepolia,
  polygonAmoy,
  sepolia,
] as any

/**
 * The chains to deploy from {@link ProtocolDeploy}
 */
// export const DeployChains = [mainnetDep].flat() as Chain[]
export const DeployChains = [sepoliaDep, mainnetDep].flat() as Chain[]
