/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder, Output, FillInstruction} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {Intent, Reward, Route, Call, TokenAmount} from "./types/Intent.sol";
import {OnchainCrosschainOrderData, GaslessCrosschainOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";
import {Semver} from "./libs/Semver.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "hardhat/console.sol";
contract Eco7683OriginSettler is IOriginSettler, Semver, EIP712 {
    using ECDSA for bytes32;

    error OriginChainIDMismatch();

    error BadSignature();

    bytes32 GASLESS_CROSSCHAIN_ORDER_TYPEHASH =
        keccak256(
            "GaslessCrosschainOrder(address originSettler,address user,uint256 nonce,uint32 openDeadline,uint32 fillDeadline,byte32 orderDataType,bytes orderData)"
        );

    address public immutable INTENT_SOURCE;

    constructor(
        string memory _name,
        string memory _version,
        address _intentSource
    ) EIP712(_name, _version) {
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
            false
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

    // function openPayable(
    //     OnchainCrossChainOrder calldata order
    // ) external payable {
    //     OnchainCrosschainOrderData memory onchainCrosschainOrderData = abi
    //         .decode(order.orderData, (OnchainCrosschainOrderData));
    //     if (onchainCrosschainOrderData.route.source != block.chainid) {
    //         revert OriginChainIDMismatch();
    //     }
    //     // orderId is the intentHash
    //     bytes32 orderId = IntentSource(INTENT_SOURCE).publishIntent{
    //         value: msg.value
    //     }(
    //         Intent(
    //             onchainCrosschainOrderData.route,
    //             Reward(
    //                 onchainCrosschainOrderData.creator,
    //                 onchainCrosschainOrderData.prover,
    //                 order.fillDeadline,
    //                 onchainCrosschainOrderData.nativeValue,
    //                 onchainCrosschainOrderData.tokens
    //             )
    //         ),
    //         onchainCrosschainOrderData.addRewards
    //     );
    //     emit Open(orderId, resolve(order));
    // }

    function resolveFor(
        GaslessCrossChainOrder calldata order,
        bytes calldata originFillerData // i dont think we need this
    ) public view override returns (ResolvedCrossChainOrder memory) {
        GaslessCrosschainOrderData memory gaslessCrosschainOrderData = abi
            .decode(order.orderData, (GaslessCrosschainOrderData));
        Output[] memory maxSpent = new Output[](0); //doesn't have a very useful meaning here since our protocol is not specifically built around swaps
        uint256 tokenCount = gaslessCrosschainOrderData.tokens.length;
        Output[] memory minReceived = new Output[](tokenCount); //rewards are fixed
        for (uint256 i = 0; i < tokenCount; i++) {
            minReceived[i] = Output(
                bytes32(
                    bytes20(uint160(gaslessCrosschainOrderData.tokens[i].token))
                ),
                gaslessCrosschainOrderData.tokens[i].amount,
                bytes32(bytes20(uint160(address(0)))), //filler is not known
                gaslessCrosschainOrderData.destination
            );
        }
        uint256 callCount = gaslessCrosschainOrderData.calls.length;
        FillInstruction[] memory fillInstructions = new FillInstruction[](
            callCount
        );
        for (uint256 j = 0; j < callCount; j++) {
            fillInstructions[j] = FillInstruction(
                uint64(gaslessCrosschainOrderData.destination),
                bytes32(bytes20(uint160(gaslessCrosschainOrderData.inbox))),
                abi.encode(gaslessCrosschainOrderData.calls[j])
            );
        }
        (bytes32 intentHash, , ) = IntentSource(INTENT_SOURCE).getIntentHash(
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
            )
        );
        return
            ResolvedCrossChainOrder(
                order.user,
                order.originChainId,
                order.fillDeadline, // we do not use opendeadline
                order.fillDeadline,
                intentHash,
                maxSpent,
                minReceived,
                fillInstructions
            );
    }

    function resolve(
        OnchainCrossChainOrder calldata order
    ) public view override returns (ResolvedCrossChainOrder memory) {
        OnchainCrosschainOrderData memory onchainCrosschainOrderData = abi
            .decode(order.orderData, (OnchainCrosschainOrderData));
        Output[] memory maxSpent = new Output[](0); //doesn't have a very useful meaning here since our protocol is not specifically built around swaps
        uint256 tokenCount = onchainCrosschainOrderData.tokens.length;
        Output[] memory minReceived = new Output[](tokenCount); //rewards are fixed
        for (uint256 i = 0; i < tokenCount; i++) {
            minReceived[i] = Output(
                bytes32(
                    bytes20(uint160(onchainCrosschainOrderData.tokens[i].token))
                ),
                onchainCrosschainOrderData.tokens[i].amount,
                bytes32(bytes20(uint160(address(0)))), //filler is not known
                onchainCrosschainOrderData.route.destination
            );
        }
        uint256 callCount = onchainCrosschainOrderData.route.calls.length;
        FillInstruction[] memory fillInstructions = new FillInstruction[](
            callCount
        );
        for (uint256 j = 0; j < callCount; j++) {
            fillInstructions[j] = FillInstruction(
                uint64(onchainCrosschainOrderData.route.destination),
                bytes32(
                    bytes20(uint160(onchainCrosschainOrderData.route.inbox))
                ),
                abi.encode(onchainCrosschainOrderData.route.calls[j])
            );
        }
        (bytes32 intentHash, , ) = IntentSource(INTENT_SOURCE).getIntentHash(
            Intent(
                onchainCrosschainOrderData.route,
                Reward(
                    onchainCrosschainOrderData.creator,
                    onchainCrosschainOrderData.prover,
                    order.fillDeadline,
                    onchainCrosschainOrderData.nativeValue,
                    onchainCrosschainOrderData.tokens
                )
            )
        );
        return
            ResolvedCrossChainOrder(
                onchainCrosschainOrderData.creator,
                onchainCrosschainOrderData.route.source,
                order.fillDeadline,
                order.fillDeadline,
                intentHash,
                maxSpent,
                minReceived,
                fillInstructions
            );
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
