import { AbiCoder } from 'ethers'

import { Route, Call, TokenAmount, Intent } from './intent'

const onchainCrosschainOrderDataTypehash =
  '0x5dd63cf8abd3430c6387c87b7d2af2290ba415b12c3f6fbc10af65f9aee8ec38'
const gaslessCrosschainOrderDataTypehash =
  '0x834338e3ed54385a3fac8309f6f326a71fc399ffb7d77d7366c1e1b7c9feac6f'

export type OnchainCrosschainOrderData = {
  route: Route
  creator: string
  prover: string
  nativeValue: bigint
  tokens: TokenAmount[]
}

export type GaslessCrosschainOrderData = {
  destination: number
  inbox: string
  routeTokens: TokenAmount[]
  calls: Call[]
  prover: string
  nativeValue: bigint
  rewardTokens: TokenAmount[]
}

export type OnchainCrosschainOrder = {
  fillDeadline: number
  orderDataType: string
  orderData: OnchainCrosschainOrderData
}

export type GaslessCrosschainOrder = {
  originSettler: string
  user: string
  nonce: string
  originChainId: number
  openDeadline: number
  fillDeadline: number
  orderDataType: string
  orderData: GaslessCrosschainOrderData
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
        name: 'tokens',
        type: 'tuple[]',
        components: [
          { name: 'token', type: 'address' },
          { name: 'amount', type: 'uint256' },
        ],
      },
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
]

const GaslessCrosschainOrderDataStruct = [
  { name: 'destination', type: 'uint256' },
  { name: 'inbox', type: 'address' },
  {
    name: 'routeTokens',
    type: 'tuple[]',
    components: [
      { name: 'token', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
  },
  {
    name: 'calls',
    type: 'tuple[]',
    components: [
      { name: 'target', type: 'address' },
      { name: 'data', type: 'bytes' },
      { name: 'value', type: 'uint256' },
    ],
  },
  { name: 'prover', type: 'address' },
  { name: 'nativeValue', type: 'uint256' },
  {
    name: 'rewardTokens',
    type: 'tuple[]',
    components: [
      { name: 'token', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
  },
]

const OnchainCrosschainOrderStruct = [
  { name: 'fillDeadline', type: 'uint32' },
  { name: 'orderDataType', type: 'bytes32' },
  { name: 'orderData', type: 'bytes' },
]

const GaslessCrosschainOrderStruct = [
    { name: 'originSettler', type: 'address'},
    { name: 'user', type: 'address'},
    { name: 'nonce', type: 'uint256'},
    { name: 'originChainId', type: 'uint256'},
    { name: 'openDeadline', type: 'uint32' },
    { name: 'fillDeadline', type: 'uint32' },
    { name: 'orderDataType', type: 'bytes32' },
    { name: 'orderData', type: 'bytes' },
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

export async function encodeGaslessCrosschainOrderData(
  gaslessCrosschainOrderData: GaslessCrosschainOrderData,
) {
  const abiCoder = AbiCoder.defaultAbiCoder()
  return abiCoder.encode(
    [
      {
        type: 'tuple',
        components: GaslessCrosschainOrderDataStruct,
      },
    ],
    [gaslessCrosschainOrderData],
  )
}

export async function encodeOnchainCrosschainOrder(
  onchainCrosschainOrder: OnchainCrosschainOrder,
) {
  const abiCoder = AbiCoder.defaultAbiCoder()
  return abiCoder.encode(
    [
      {
        type: 'tuple',
        components: OnchainCrosschainOrderStruct,
      },
    ],
    [onchainCrosschainOrder],
  )
}

export async function createOnchainCrosschainOrder(
  intent: Intent,
): Promise<OnchainCrosschainOrder> {
  const onchainCrosschainOrderData = {
    route: intent.route,
    creator: intent.reward.creator,
    prover: intent.reward.prover,
    nativeValue: intent.reward.nativeValue,
    tokens: intent.reward.tokens,
  }
  const onchainCrosschainOrder: OnchainCrosschainOrder = {
    fillDeadline: intent.reward.deadline,
    orderDataType: onchainCrosschainOrderDataTypehash,
    orderData: onchainCrosschainOrderData,
  }
  return onchainCrosschainOrder
}

export async function createGaslessCrosschainOrder(
  intent: Intent,
  originSettler: string,
): Promise<GaslessCrosschainOrderStruct> {
  const gaslessCrosschainOrderData = {
    destination: intent.route.destination,
    inbox: intent.route.inbox,
    routeTokens: intent.route.tokens,
    calls: intent.route.calls,
    prover: intent.reward.prover,
    nativeValue: intent.reward.nativeValue,
    rewardTokens: intent.reward.tokens,
  }
  const gaslessCrosschainOrder: GaslessCrosschainOrder = {
    originSettler: originSettler,
    user: intent.reward.creator,
    nonce: intent.route.salt,
    originChainId: intent.route.source,
    openDeadline: intent.reward.deadline,
    fillDeadline: intent.reward.deadline,
    orderDataType: gaslessCrosschainOrderDataTypehash,
    orderData: gaslessCrosschainOrderData,
  }
  return gaslessCrosschainOrder
}
