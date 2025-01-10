/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {Intent, Reward, Route, Call, TokenAmount} from "./types/Intent.sol";
import {CrosschainOrderData, GaslessCrosschainOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";

contract Eco7683OriginSettler is IOriginSettler {
    constructor() {}
    function openFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata signature,
        bytes calldata originFillerData
    ) external override {
        GaslessCrosschainOrderData memory gaslessCrosschainOrderData = abi
            .decode(order.orderData, (GaslessCrosschainOrderData));
    }

    function open(OnchainCrossChainOrder calldata order) external override {
        CrosschainOrderData memory crosschainOrderData = abi.decode(
            order.orderData,
            (CrosschainOrderData)
        );
        // orderId is the intentHash
        bytes32 orderId = IntentSource(crosschainOrderData.intentSource)
            .publishIntent(
                Intent(
                    crosschainOrderData.route,
                    Reward(
                        crosschainOrderData.creator,
                        crosschainOrderData.prover,
                        order.fillDeadline,
                        crosschainOrderData.nativeValue,
                        crosschainOrderData.tokens
                    )
                ),
                crosschainOrderData.addRewards
            );
        emit Open(orderId, resolve(order));
    }

    function resolveFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata originFillerData
    ) external view override returns (ResolvedCrossChainOrder memory) {
        // CrosschainOrderData memory crosschainOrderData = abi.decode(
        //     order.orderData,
        //     (CrosschainOrderData)
        // );
        // return
        //     ResolvedCrossChainOrder(
        //         crosschainOrderData.creator,
        //         crosschainOrderData.sourceChainID,
        //         crosschainOrderData.openDeadline, //is this already open?
        //         order.fillDeadline,
        //         CrosschainOrderData.nonce
        //     );
    }

    function resolve(
        OnchainCrossChainOrder calldata order
    ) public view override returns (ResolvedCrossChainOrder memory) {
        // return ResolvedCrossChainOrder();
    }
}
