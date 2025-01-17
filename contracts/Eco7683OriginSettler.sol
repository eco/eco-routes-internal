/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {Intent, Reward, Route, Call, TokenAmount} from "./types/Intent.sol";
import {OnchainCrosschainOrderData, GaslessCrosschainOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract Eco7683OriginSettler is IOriginSettler, EIP712 {
    using ECDSA for bytes32;

    error OriginChainIDMismatch();

    error BadSignature();

    bytes32 GASLESS_CROSSCHAIN_ORDER_TYPEHASH =
        keccak256(
            "GaslessCrosschainOrder(address originSettler,address user,uint256 nonce,uint32 openDeadline,uint32 fillDeadline,byte32 orderDataType,bytes orderData)"
        );

    address public immutable INTENT_SOURCE;

    constructor(
        address _intentSource,
        string memory name,
        string memory version
    ) EIP712(name, version) {
        INTENT_SOURCE = _intentSource;
    }

    function openFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata signature,
        bytes calldata originFillerData
    ) external override {
        if (!_verifyOpenFor(order, signature)) {
            revert BadSignature();
        }
        GaslessCrosschainOrderData memory gaslessCrosschainOrderData = abi
            .decode(order.orderData, (GaslessCrosschainOrderData));
        if (order.originChainId != block.chainid) {
            revert OriginChainIDMismatch();
        }
        // orderId is the intentHash
        bytes32 orderId = IntentSource(INTENT_SOURCE).publishIntent(
            Intent(
                Route(
                    bytes32(order.nonce),
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
        emit Open(orderId, resolveFor(order, originFillerData));
    }

    function open(OnchainCrossChainOrder calldata order) external override {
        OnchainCrosschainOrderData memory onchainCrosschainOrderData = abi
            .decode(order.orderData, (OnchainCrosschainOrderData));
        if (onchainCrosschainOrderData.route.source != block.chainid) {
            revert OriginChainIDMismatch();
        }
        // orderId is the intentHash
        bytes32 orderId = IntentSource(INTENT_SOURCE).publishIntent(
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
    ) public view override returns (ResolvedCrossChainOrder memory) {
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

    function _verifyOpenFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(
                GASLESS_CROSSCHAIN_ORDER_TYPEHASH,
                order.originSettler,
                order.user,
                order.nonce,
                order.openDeadline,
                order.fillDeadline,
                keccak256(order.orderData)
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        if (signer != order.user) {
            return false;
        }
    }
}
