// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {ISemver} from "../interfaces/ISemver.sol";

abstract contract Semver is ISemver {
    function version() external pure returns (string memory) {
        return "1.6.12-e84c91d";
    }
}
