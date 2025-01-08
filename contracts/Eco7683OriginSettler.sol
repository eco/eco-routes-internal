/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {Intent} from "./types/Intent.sol";
import {IntentOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";

contract Eco7683OriginSettler is IOriginSettler {
    constructor() {

    }
    function openFor(GaslessCrossChainOrder calldata order, bytes calldata signature, bytes calldata originFillerData) external override {

    }

    function open(OnchainCrossChainOrder calldata order) external override {
        // decode with hash? im not doing anything here with orderDataType
        // require that orderDataType matches the EIP712 typehash for IntentOrderData
        IntentOrderData memory intentOrderData = abi.decode(order.orderData, (IntentOrderData));
        address intentSource = intentOrderData.intentSource;
        IntentSource(intentSource).publishIntent(
            Intent(
                intentOrderData.creator,
                intentOrderData.nonce,
                intentOrderData.sourceChainID,
                intentOrderData.destinationChainID,
                intentOrderData.destinationInbox,
                intentOrderData.calls,
                intentOrderData.rewards,
                intentOrderData.nativeReward,
                order.fillDeadline,
                intentOrderData.prover
            ),
            intentOrderData.addRewards
        );
    }

    function resolveFor(GaslessCrossChainOrder calldata order, bytes calldata originFillerData) external view override returns (ResolvedCrossChainOrder memory) {
        IntentOrderData memory intentOrderData = abi.decode(order.orderData, (IntentOrderData));

        return ResolvedCrossChainOrder(
            intentOrderData.creator, 
            intentOrderData.sourceChainID, 
            intentOrderData.openDeadline, //is this already open?
            order.fillDeadline,
            IntentOrderData.nonce);
    }

    function resolve(OnchainCrossChainOrder calldata order) external view override returns (ResolvedCrossChainOrder memory) {

        return ResolvedCrossChainOrder();
    }
}