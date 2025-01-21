import { ethers } from 'hardhat'
import { getCreate2Address, keccak256, solidityPacked, AbiCoder } from 'ethers'

import { Route, Call, TokenAmount } from './intent'

export type OnchainCrosschainOrderData = {
  route: Route
  creator: string
  prover: string
  nativeValue: bigint
  tokens: TokenAmount[]
  addRewards: boolean
}

const OnchainCrosschainOrderDataStruct = [
  {
    name: 'route',
    type: 'tuple',
    components: [
      { name: 'salt', type: 'bytes32' },
      { name: 'source', type: 'uint256' },
      { name: 'destination', type: 'uint256' },
      { name: 'inbox', type: 'uint256' },
      {
        name: 'calls',
        type: 'tuple[]',
        components: [
          { name: 'target', type: 'address' },
          { name: 'data', type: 'bytes' },
          { name: 'value', type: 'uint256' },
        ],
      },
    ],
  },
  { name: 'creator', type: 'address' },
  { name: 'prover', type: 'address' },
  { name: 'nativeValue', type: 'uint256' },
  {
    name: 'tokens',
    type: 'tuple[]',
    components: [
      { name: 'token', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
  },
  { name: 'addRewards', type: 'bool' },
]

export async function encodeOnchainCrosschainOrderData(
  onchainCrosschainOrderData: OnchainCrosschainOrderData,
) {
  const abiCoder = AbiCoder.defaultAbiCoder()
  return abiCoder.encode(
    [
      {
        type: 'tuple',
        components: OnchainCrosschainOrderDataStruct,
      },
    ],
    [onchainCrosschainOrderData],
  )
}
