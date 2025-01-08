/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Call, Reward} from "./Intent.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";

/// @title Eco Intent Order Data
/// @notice subtype of orderData
/// @notice contains everything which, when combined with other aspects of order data, is sufficient to publish an intent via Eco Protocol
struct IntentOrderData {
    // address of Eco IntentSource
    address intentSource;
    // creator of the intent
    address creator;
    // nonce provided by the creator
    bytes32 nonce;
    // ID of chain where the intent was created
    uint256 sourceChainID;
    // ID of chain where we want instructions executed
    uint256 destinationChainID;
    // The inbox contract on the destination chain will be the msg.sender for the instructions that are executed.
    address destinationInbox;
    // instructions to be executed on destinationChain
    Call[] calls;
    // addresses and amounts of reward tokens
    Reward[] rewards;
    // native tokens offered as reward
    uint256 nativeReward;
    // address of the prover this intent will be checked against
    address prover;
    // boolean indicating whether the creator wants to add rewards during intent creation
    bool addRewards;
}