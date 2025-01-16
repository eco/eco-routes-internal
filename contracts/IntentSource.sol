/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IIntentSource} from "./interfaces/IIntentSource.sol";
import {BaseProver} from "./prover/BaseProver.sol";
import {Intent, Reward, Route} from "./types/Intent.sol";
import {Semver} from "./libs/Semver.sol";

import {IntentVault} from "./IntentVault.sol";

/**
 * @notice Source chain contract for the Eco Protocol's intent system
 * @dev Used to create intents and withdraw associated rewards. Works in conjunction with
 * an inbox contract on the destination chain. Verifies intent fulfillment through
 * a prover contract on the source chain
 */
contract IntentSource is IIntentSource, Semver {
    using SafeERC20 for IERC20;

    mapping(bytes32 intentHash => ClaimState) public claims;

    address public vaultRefundToken;

    constructor() {}

    /**
     * @notice Retrieves claim state for a given intent hash
     * @param intentHash Hash of the intent to query
     * @return ClaimState struct containing claim information
     */
    function getClaim(
        bytes32 intentHash
    ) external view returns (ClaimState memory) {
        return claims[intentHash];
    }

    /**
     * @notice Gets the token used for vault refunds
     * @return Address of the vault refund token
     */
    function getVaultRefundToken() external view returns (address) {
        return vaultRefundToken;
    }

    /**
     * @notice Calculates the hash of an intent and its components
     * @param intent The intent to hash
     * @return intentHash Combined hash of route and reward
     * @return routeHash Hash of the route component
     * @return rewardHash Hash of the reward component
     */
    function getIntentHash(
        Intent calldata intent
    )
        public
        pure
        returns (bytes32 intentHash, bytes32 routeHash, bytes32 rewardHash)
    {
        routeHash = keccak256(abi.encode(intent.route));
        rewardHash = keccak256(abi.encode(intent.reward));
        intentHash = keccak256(abi.encodePacked(routeHash, rewardHash));
    }

    /**
     * @notice Calculates the deterministic address of the intent vault
     * @param intent Intent to calculate vault address for
     * @return Address of the intent vault
     */
    function intentVaultAddress(
        Intent calldata intent
    ) public view returns (address) {
        (bytes32 intentHash, bytes32 routeHash, ) = getIntentHash(intent);
        return _getIntentVaultAddress(intentHash, routeHash, intent.reward);
    }

    /**
     * @notice Creates an intent to execute instructions on a supported chain in exchange for assets
     * @dev If source chain proof isn't completed by expiry, rewards aren't redeemable regardless of execution.
     * Solver must manage timing considerations (e.g., L1 data posting delays)
     * @param intent The intent struct containing all parameters
     * @param fundReward Whether to fund the reward or not
     * @return intentHash The hash of the created intent
     */
    function publishIntent(
        Intent calldata intent,
        bool fundReward
    ) external payable returns (bytes32 intentHash) {
        Route calldata route = intent.route;
        Reward calldata reward = intent.reward;

        uint256 rewardsLength = reward.tokens.length;
        bytes32 routeHash;

        (intentHash, routeHash, ) = getIntentHash(intent);

        if (claims[intentHash].status != uint8(ClaimStatus.NotClaimed)) {
            revert IntentAlreadyExists(intentHash);
        }

        address vault = _getIntentVaultAddress(intentHash, routeHash, reward);

        if (fundReward) {
            if (_validateIntent(intent, vault)) {
                revert IntentAlreadyFunded();
            }

            if (reward.nativeValue > 0) {
                if (msg.value < reward.nativeValue) {
                    revert InsufficientNativeReward();
                }

                payable(vault).transfer(reward.nativeValue);

                if (msg.value > reward.nativeValue) {
                    payable(msg.sender).transfer(
                        msg.value - reward.nativeValue
                    );
                }
            }

            for (uint256 i = 0; i < rewardsLength; i++) {
                address token = reward.tokens[i].token;
                uint256 amount = reward.tokens[i].amount;

                IERC20(token).safeTransferFrom(msg.sender, vault, amount);
            }
        } else if (block.chainid == intent.route.source) {
            if (!_validateIntent(intent, vault)) {
                revert InvalidIntent();
            }
        }

        emit IntentCreated(
            intentHash,
            route.salt,
            route.source,
            route.destination,
            route.inbox,
            route.calls,
            reward.creator,
            reward.prover,
            reward.deadline,
            reward.nativeValue,
            reward.tokens
        );
    }

    /**
     * @notice Checks if an intent is properly funded
     * @param intent Intent to validate
     * @return True if intent is properly funded, false otherwise
     */
    function validateIntent(
        Intent calldata intent
    ) external view returns (bool) {
        (bytes32 intentHash, bytes32 routeHash, ) = getIntentHash(intent);
        address vault = _getIntentVaultAddress(
            intentHash,
            routeHash,
            intent.reward
        );

        return _validateIntent(intent, vault);
    }

    /**
     * @notice Withdraws rewards associated with an intent to its claimant
     * @param routeHash Hash of the intent's route
     * @param reward Reward structure of the intent
     */
    function withdrawRewards(bytes32 routeHash, Reward calldata reward) public {
        bytes32 rewardHash = keccak256(abi.encode(reward));
        bytes32 intentHash = keccak256(abi.encodePacked(routeHash, rewardHash));

        address claimant = BaseProver(reward.prover).provenIntents(intentHash);

        // Claim the rewards if the intent has not been claimed
        if (
            claimant != address(0) && claims[intentHash].claimant == address(0)
        ) {
            claims[intentHash].claimant = claimant;

            emit Withdrawal(intentHash, claimant);

            new IntentVault{salt: routeHash}(intentHash, reward);

            claims[intentHash].status = uint8(ClaimStatus.Claimed);

            return;
        }

        if (claimant != address(0)) {
            revert NothingToWithdraw(intentHash);
        }

        // Check if the intent has expired
        if (claimant == address(0) && block.timestamp < reward.deadline) {
            revert UnauthorizedWithdrawal(intentHash);
        }

        emit Withdrawal(intentHash, reward.creator);

        // Refund the rewards for expired intent
        new IntentVault{salt: routeHash}(intentHash, reward);
    }

    /**
     * @notice Batch withdraws multiple intents with the same claimant
     * @param routeHashes Array of route hashes for the intents
     * @param rewards Array of reward structures for the intents
     */
    function batchWithdraw(
        bytes32[] calldata routeHashes,
        Reward[] calldata rewards
    ) external {
        uint256 length = routeHashes.length;

        if (length != rewards.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < length; i++) {
            withdrawRewards(routeHashes[i], rewards[i]);
        }
    }

    /**
     * @notice Refunds rewards to the intent creator
     * @param routeHash Hash of the intent's route
     * @param reward Reward structure of the intent
     * @param token Optional token address for handling incorrect vault transfers
     */
    function refundIntent(
        bytes32 routeHash,
        Reward calldata reward,
        address token
    ) external {
        bytes32 rewardHash = keccak256(abi.encode(reward));
        bytes32 intentHash = keccak256(abi.encodePacked(routeHash, rewardHash));

        if (
            claims[intentHash].status == uint8(ClaimStatus.NotClaimed) &&
            block.timestamp < reward.deadline
        ) {
            revert UnauthorizedWithdrawal(intentHash);
        }

        if (token != address(0)) {
            vaultRefundToken = token;
        }

        emit Withdrawal(intentHash, reward.creator);

        new IntentVault{salt: routeHash}(intentHash, reward);

        if (token != address(0)) {
            vaultRefundToken = address(0);
        }
    }

    /**
     * @notice Validates that an intent's vault holds sufficient rewards
     * @dev Checks both native token and ERC20 token balances
     * @param intent Intent to validate
     * @param vault Address of the intent's vault
     * @return True if vault has sufficient funds, false otherwise
     */
    function _validateIntent(
        Intent calldata intent,
        address vault
    ) internal view returns (bool) {
        Reward calldata reward = intent.reward;
        uint256 rewardsLength = reward.tokens.length;

        if (vault.balance < reward.nativeValue) return false;

        for (uint256 i = 0; i < rewardsLength; i++) {
            address token = reward.tokens[i].token;
            uint256 amount = reward.tokens[i].amount;
            uint256 balance = IERC20(token).balanceOf(vault);

            if (balance < amount) return false;
        }

        return true;
    }

    /**
     * @notice Calculates the deterministic address of an intent vault using CREATE2
     * @dev Follows EIP-1014 for address calculation
     * @param intentHash Hash of the full intent
     * @param routeHash Hash of the route component
     * @param reward Reward structure
     * @return The calculated vault address
     */
    function _getIntentVaultAddress(
        bytes32 intentHash,
        bytes32 routeHash,
        Reward calldata reward
    ) internal view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.9/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                address(this),
                                routeHash,
                                keccak256(
                                    abi.encodePacked(
                                        type(IntentVault).creationCode,
                                        abi.encode(intentHash, reward)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}
