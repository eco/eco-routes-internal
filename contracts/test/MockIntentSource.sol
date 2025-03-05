// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Intent, Route, Reward, Call} from "../types/Intent.sol";

/**
 * @title MockIntentSource
 * @notice Mock contract for testing IntentSource's pushWithdraw and batchPushWithdraw functionality
 */
contract MockIntentSource {
    // Events to log input parameters
    event PushWithdrawCalled(bytes32 intentHash, bytes32 routeHash, Reward reward, address claimant);
    event BatchPushWithdrawCalled(bytes32[] intentHashes, bytes32[] routeHashes, Reward[] rewards, address[] claimants);
    
    // Errors
    error UnauthorizedProver(address caller);
    error ArrayLengthMismatch();

    /**
     * @notice Mock implementation of pushWithdraw that emits input parameters
     * @param intentHash Hash of the intent
     * @param routeHash Hash of the intent's route component
     * @param reward Reward structure containing prover address and reward details
     * @param claimant Address that will receive the rewards
     */
    function pushWithdraw(bytes32 intentHash, bytes32 routeHash, Reward calldata reward, address claimant) public {
        if (reward.prover != msg.sender) {
            revert UnauthorizedProver(msg.sender);
        }
        
        emit PushWithdrawCalled(intentHash, routeHash, reward, claimant);
    }

    /**
     * @notice Mock implementation of batchPushWithdraw that emits input parameters
     * @param intentHashes Array of intent hashes
     * @param routeHashes Array of route hashes for the intents
     * @param rewards Array of reward structures for the intents
     * @param claimants Array of addresses to receive the rewards
     */
    function batchPushWithdraw(
        bytes32[] calldata intentHashes, 
        bytes32[] calldata routeHashes, 
        Reward[] calldata rewards, 
        address[] calldata claimants
    ) external {
        uint256 length = intentHashes.length;

        if (length != routeHashes.length || length != rewards.length || length != claimants.length) {
            revert ArrayLengthMismatch();
        }

        emit BatchPushWithdrawCalled(intentHashes, routeHashes, rewards, claimants);

        for (uint256 i = 0; i < length; ++i) {
            pushWithdraw(intentHashes[i], routeHashes[i], rewards[i], claimants[i]);
        }
    }
}
