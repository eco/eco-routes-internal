/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TokenAmount, Route, Call} from "./Intent.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/// @title Eco Intent Order Data
/// @notice subtype of orderData
/// @notice contains everything which, when combined with other aspects of order data, is sufficient to publish an intent via Eco Protocol
struct OnchainCrosschainOrderData {
    // address of Eco IntentSource
    address intentSource;
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
    // address of Eco IntentSource
    address intentSource;
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
