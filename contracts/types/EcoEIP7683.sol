/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TokenAmount, Route, Call} from "./Intent.sol";

/// @title Eco Intent Order Data
/// @notice subtype of orderData
/// @notice contains everything which, when combined with other aspects of order data, is sufficient to publish an intent via Eco Protocol
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
    // boolean indicating whether the creator wants to add rewards during intent creation
    bool addRewards;
}

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
    // boolean indicating whether the creator wants to add rewards during intent creation
    bool addRewards;
}

abstract contract EcoEIP7683 {
    bytes32 public constant ONCHAIN_CROSSCHAIN_ORDER_DATA_TYPEHASH =
        keccak256(
            "EcoOnchainGaslessCrosschainOrderData(Route route,address creator,address prover,uint256 nativeValue,TokenAmount[] tokens,bool addRewards)Route(uint256 source,uint256 destination,address inbox,Call[] calls)TokenAmount(address token,uint256 amount)Call(address target,bytes data,uint256 value)"
        );
    bytes32 public constant GASLESS_CROSSCHAIN_ORDER_DATA_TYPEHASH =
        keccak256(
            "EcoGaslessCrosschainOrderData(uint256 destination,address inbox,Call[] calls,address prover,uint256 nativeValue,TokenAmount[] tokens,bool addRewards)TokenAmount(address token,uint256 amount)Call(address target,bytes data,uint256 value)"
        );
}
