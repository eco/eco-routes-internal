/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TokenAmount, Route, Call} from "./Intent.sol";
/**
 * @title EcoEIP7683
 * @dev EIP7683 orderData subtypes designed for Eco Protocol
 */

/**
 * @notice contains everything which, when combined with other aspects of GaslessCrossChainOrder
 * is sufficient to publish an intent via Eco Protocol
 * @dev the orderData field of GaslessCrossChainOrder should be decoded as GaslessCrosschainOrderData
 */
struct OnchainCrosschainOrderData {
    // Route data
    Route route;
    // creator of the intent
    address creator;
    // address of the prover this intent will be checked against
    address prover;
    // native tokens offered as reward
    uint256 nativeValue;
    // addresses and amounts of reward tokens
    TokenAmount[] tokens;
}
/**
 * @notice contains everything which, when combined with other aspects of GaslessCrossChainOrder
 * is sufficient to publish an intent via Eco Protocol
 * @dev the orderData field of GaslessCrossChainOrder should be decoded as GaslessCrosschainOrderData
 */
struct GaslessCrosschainOrderData {
    // ID of chain where the intent was created
    uint256 destination;
    // The inbox contract on the destination chain will be the msg.sender
    address inbox;
    // instructions
    Call[] calls;
    // address of the prover this intent will be checked against
    address prover;
    // native tokens offered as reward
    uint256 nativeValue;
    // addresses and amounts of reward tokens
    TokenAmount[] tokens;
}

//EIP712 typehashes
bytes32 constant ONCHAIN_CROSSCHAIN_ORDER_DATA_TYPEHASH = keccak256(
    "EcoOnchainGaslessCrosschainOrderData(Route route,address creator,address prover,uint256 nativeValue,TokenAmount[] tokens)Route(uint256 source,uint256 destination,address inbox,Call[] calls)TokenAmount(address token,uint256 amount)Call(address target,bytes data,uint256 value)"
);
bytes32 constant GASLESS_CROSSCHAIN_ORDER_DATA_TYPEHASH = keccak256(
    "EcoGaslessCrosschainOrderData(uint256 destination,address inbox,Call[] calls,address prover,uint256 nativeValue,TokenAmount[] tokens)TokenAmount(address token,uint256 amount)Call(address target,bytes data,uint256 value)"
);
