/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./types/EIP7683.sol";
import "./interfaces/EIP7683/IOriginSettler.sol";
import "./types/Intent.sol";
import "./types/EcoEIP7683.sol";
import "./IntentSource.sol";

contract Eco7683OriginSettler is IOriginSettler {
    constructor() {

    }
    function openFor(GaslessCrossChainOrder calldata order, bytes calldata signature, bytes calldata originFillerData) external override {

    }

    function open(OnchainCrossChainOrder calldata order) external override {
        // decode with hash? im not doing anything here with orderDataType
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
}