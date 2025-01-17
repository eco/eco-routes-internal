import { Route, Call, TokenAmount } from "./intent"

export type OnchainCrosschainOrderData = {
    route: Route
    creator: string
    prover: string
    nativeValue: number
    tokens: TokenAmount[]
    addRewards: boolean
}

// const OnchainCrosschainOrderData = [
//     {
//         name: 'route',
//         type: 'tuple[]',
//         components: [
//           { name: 'token', type: 'address' },
//           { name: 'amount', type: 'uint256' },
//         ],
//       },
//     { name: 'Route', type: 'address' },
//     { name: 'prover', type: 'address' },
//     { name: 'deadline', type: 'uint256' },
//     { name: 'nativeValue', type: 'uint256' },
//     {
//       name: 'tokens',
//       type: 'tuple[]',
//       components: [
//         { name: 'token', type: 'address' },
//         { name: 'amount', type: 'uint256' },
//       ],
//     },
//   ]