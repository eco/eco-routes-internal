/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IProver.sol";

contract testProver is IProver {
    mapping(bytes32 => address) public provenIntents;

    function addProvenIntent(bytes32 identifier, address withdrawableBy) public {
        provenIntents[identifier] = withdrawableBy;
    }

}
