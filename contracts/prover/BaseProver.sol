// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IProver} from "../interfaces/IProver.sol";

abstract contract BaseProver is IProver {
    mapping(bytes32 => address) public provenIntents;

    function getIntentClaimant(
        bytes32 intentHash
    ) external view override returns (address) {
        return provenIntents[intentHash];
    }
}
