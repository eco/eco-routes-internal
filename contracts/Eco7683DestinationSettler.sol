/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OnchainCrossChainOrder, ResolvedCrossChainOrder, GaslessCrossChainOrder, Output, FillInstruction} from "./types/EIP7683.sol";
import {IOriginSettler} from "./interfaces/EIP7683/IOriginSettler.sol";
import {IDestinationSettler} from "./interfaces/EIP7683/IDestinationSettler.sol";
import {Intent, Reward, Route, Call, TokenAmount} from "./types/Intent.sol";
import {OnchainCrosschainOrderData, GaslessCrosschainOrderData} from "./types/EcoEIP7683.sol";
import {IntentSource} from "./IntentSource.sol";
import {Semver} from "./libs/Semver.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "hardhat/console.sol";
abstract contract Eco7683DestinationSettler is IDestinationSettler, Semver {
    using ECDSA for bytes32;

    constructor() Semver("0.1.0") {}

    /// @notice Fills a single leg of a particular order on the destination chain
    /// @param orderId Unique order identifier for this order
    /// @param originData Data emitted on the origin to parameterize the fill
    /// @param fillerData Data provided by the filler to inform the fill or express their preferences
    function fill(
        bytes32 orderId,
        bytes calldata originData,
        bytes calldata fillerData
    ) external payable;
}
