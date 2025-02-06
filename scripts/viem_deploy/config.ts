import { Hex } from 'viem'

export const ViemDeployConfig: Record<
  number,
  { hyperlaneMailboxAddress: Hex }
> = {
  10: { hyperlaneMailboxAddress: '0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D' },
  8453: {
    hyperlaneMailboxAddress: '0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D',
  }, // base
  8921733: {
    hyperlaneMailboxAddress: '0x4B216a3012DD7a2fD4bd3D05908b98C668c63a8d',
  }, // helix
  42161: {
    hyperlaneMailboxAddress: '0x979Ca5202784112f4738403dBec5D0F3B9daabB9',
  }, // arbitrum
  5000: {
    hyperlaneMailboxAddress: '0x398633D19f4371e1DB5a8EFE90468eB70B1176AA',
  }, // mantle
  137: {
    hyperlaneMailboxAddress: '0x5d934f4e2f797775e53561bB72aca21ba36B96BB',
  }, // polygon
  // abstract?
}
