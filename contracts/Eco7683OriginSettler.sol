/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {Intent, Reward, Route, Call, TokenAmount} from "./types/Intent.sol";
import {OnchainCrosschainOrderData, GaslessCrosschainOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";

contract Eco7683OriginSettler is IOriginSettler {
    constructor() {}

    error OriginChainIDMismatch();

    function openFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata signature,
        bytes calldata originFillerData
    ) external override {
        GaslessCrosschainOrderData memory gaslessCrosschainOrderData = abi
            .decode(order.orderData, (GaslessCrosschainOrderData));
        if (order.originChainId != block.chainid) {
            revert OriginChainIDMismatch();
        }
        // orderId is the intentHash
        bytes32 orderId = IntentSource(gaslessCrosschainOrderData.intentSource)
            .publishIntent(
                Intent(
                    Route(
                        order.nonce,
                        order.originChainId,
                        gaslessCrosschainOrderData.destination,
                        gaslessCrosschainOrderData.inbox,
                        gaslessCrosschainOrderData.calls
                    ),
                    Reward(
                        order.user,
                        gaslessCrosschainOrderData.prover,
                        order.fillDeadline,
                        gaslessCrosschainOrderData.nativeValue,
                        gaslessCrosschainOrderData.tokens
                    )
                ),
                gaslessCrosschainOrderData.addRewards
            );
    }

    function open(OnchainCrossChainOrder calldata order) external override {
        OnchainCrosschainOrderData memory onchainCrosschainOrderData = abi.decode(
            order.orderData,
            (OnchainCrosschainOrderData)
        );
        if (onchainCrosschainOrderData.route.source != block.chainid) {
            revert OriginChainIDMismatch();
        }
        // orderId is the intentHash
        bytes32 orderId = IntentSource(onchainCrosschainOrderData.intentSource)
            .publishIntent(
                Intent(
                    onchainCrosschainOrderData.route,
                    Reward(
                        onchainCrosschainOrderData.creator,
                        onchainCrosschainOrderData.prover,
                        order.fillDeadline,
                        onchainCrosschainOrderData.nativeValue,
                        onchainCrosschainOrderData.tokens
                    )
                ),
                onchainCrosschainOrderData.addRewards
            );
        emit Open(orderId, resolve(order));
    }

    function resolveFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata originFillerData
    ) external view override returns (ResolvedCrossChainOrder memory) {
        // OnchainCrosschainOrderData memory crosschainOrderData = abi.decode(
        //     order.orderData,
        //     (OnchainCrosschainOrderData)
        // );
        // return
        //     ResolvedCrossChainOrder(
        //         crosschainOrderData.creator,
        //         crosschainOrderData.sourceChainID,
        //         crosschainOrderData.openDeadline, //is this already open?
        //         order.fillDeadline,
        //         OnchainCrosschainOrderData.nonce
        //     );
    }

    function resolve(
        OnchainCrossChainOrder calldata order
    ) public view override returns (ResolvedCrossChainOrder memory) {
        // return ResolvedCrossChainOrder();
    }
}
