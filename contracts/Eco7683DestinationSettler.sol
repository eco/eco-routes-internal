/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder, Output, FillInstruction} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {IDestinationSettler} from "./interfaces/EIP7683/IDestinationSettler.sol";
import {Intent, Reward, Route, Call, TokenAmount} from "./types/Intent.sol";
import {OnchainCrosschainOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";
import {Inbox} from "./Inbox.sol";
import {Semver} from "./libs/Semver.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "hardhat/console.sol";
abstract contract Eco7683DestinationSettler is IDestinationSettler, Semver {
    using ECDSA for bytes32;

    /**
     * @notice Thrown when the prover does not have a valid proofType
     */
    error BadProver();

    constructor() Semver() {}

    /// @notice Fills a single leg of a particular order on the destination chain
    /// @param orderId Unique order identifier for this order
    /// @param originData Data emitted on the origin to parameterize the fill
    /// @param fillerData Data provided by the filler to inform the fill or express their preferences
    function fill(
        bytes32 orderId,
        bytes calldata originData,
        bytes calldata fillerData
    ) external payable {
        (OnchainCrossChainOrder memory order, uint256 proofType) = abi.decode(
            originData,
            (OnchainCrossChainOrder, uint256)
        );
        OnchainCrosschainOrderData memory onchainCrosschainOrderData = abi
            .decode(order.orderData, (OnchainCrosschainOrderData));
        Intent memory intent = Intent(
            onchainCrosschainOrderData.route,
            Reward(
                onchainCrosschainOrderData.creator,
                onchainCrosschainOrderData.prover,
                order.fillDeadline,
                onchainCrosschainOrderData.nativeValue,
                onchainCrosschainOrderData.tokens
            )
        );
        bytes32 rewardHash = keccak256(abi.encode(intent.reward));
        Inbox inbox = Inbox(payable(intent.route.inbox));

        if (proofType == 0) {
            //IProver.ProofType.Storage
            address claimant = abi.decode(fillerData, (address));
            inbox.fulfillStorage(intent.route, rewardHash, claimant, orderId);
        } else if (proofType == 1) {
            //IProver.ProofType.Hyperlane
            (address claimant, bool batched, bytes memory relayerData) = abi
                .decode(fillerData, (address, bool, bytes));
            if (batched) {
                inbox.fulfillHyperBatched(
                    intent.route,
                    rewardHash,
                    claimant,
                    orderId,
                    intent.reward.prover
                );
            } else {
                (address postDispatchHook, bytes memory metadata) = abi.decode(
                    relayerData,
                    (address, bytes)
                );
                inbox.fulfillHyperInstantWithRelayer(
                    intent.route,
                    rewardHash,
                    claimant,
                    orderId,
                    onchainCrosschainOrderData.prover,
                    metadata,
                    postDispatchHook
                );
            }
        } else {
            revert BadProver();
        }
    }
}
