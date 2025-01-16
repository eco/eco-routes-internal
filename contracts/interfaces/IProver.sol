// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ISemver} from "./ISemver.sol";

interface IProver is ISemver {
    // The types of proof that provers can be
    enum ProofType {
        Storage,
        Hyperlane
    }

    /**
     * @notice emitted when an intent has been successfully proven
     * @param _hash  the hash of the intent
     * @param _claimant the address that can claim this intent's rewards
     */
    event IntentProven(bytes32 indexed _hash, address indexed _claimant);

    // returns the proof type of the prover
    function getProofType() external pure returns (ProofType);

    function getIntentClaimant(
        bytes32 intentHash
    ) external view returns (address);
}
