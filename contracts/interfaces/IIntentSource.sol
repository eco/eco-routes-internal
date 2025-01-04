/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Call, TokenReward, Reward, Intent} from "../types/Intent.sol";
import "./ISemver.sol";
/**
 * This contract is the source chain portion of the Eco Protocol's intent system.
 *
 * It can be used to create intents as well as withdraw the associated rewards.
 * Its counterpart is the inbox contract that lives on the destination chain.
 * This contract makes a call to the prover contract (on the source chain) in order to verify intent fulfillment.
 */
interface IIntentSource is ISemver {
    /**
     * @notice thrown on a call to withdraw() by someone who is not entitled to the rewards for a
     * given intent.
     * @param _hash the hash of the intent, also the key to the intents mapping
     */
    error UnauthorizedWithdrawal(bytes32 _hash);

    /**
     * @notice thrown on a call to withdraw() for an intent whose rewards have already been withdrawn.
     * @param _hash the hash of the intent on which withdraw was attempted
     */
    error NothingToWithdraw(bytes32 _hash);

    /**
     * @notice thrown on a call to createIntent where _expiry is less than MINIMUM_DURATION
     * seconds later than the block timestamp at time of call
     */
    error ExpiryTooSoon();

    /**
     * @notice thrown on a call to createIntent where _targets and _data have different lengths, or when one of their lengths is zero.
     */
    error CalldataMismatch();

    /**
     * @notice thrown on a call to createIntent where _rewardTokens and _rewardAmounts have different lengths, or when one of their lengths is zero.
     */
    error RewardsMismatch();

    /**
     * @notice thrown on a call to createIntent where no reward is specified in erc20 or native tokens.
     */
    error NoRewards();

    /**
     * @notice thrown on a call to batchWithdraw where an intent's claimant does not match the input claimant address
     * @param _hash the hash of the intent on which withdraw was attempted
     */
    error BadClaimant(bytes32 _hash);

    /**
     * @notice thrown on transfer failure
     * @param _token the token
     * @param _to the recipient
     * @param _amount the amount
     */
    error TransferFailed(address _token, address _to, uint256 _amount);

    /**
     * @notice emitted on a successful call to createIntent
     * @param hash the hash of the intent, also the key to the intents mapping
     * @param nonce the nonce provided by the creator
     * @param destination the destination chain
     * @param inbox the inbox contract on the destination chain
     * @param calls the instructions
     * @param creator the address that created the intent
     * @param prover the prover contract address for the intent
     * @param expiryTime the time by which the storage proof must have been created in order for the solver to redeem rewards.
     * @param nativeValue the amount of native tokens offered as reward
     * @param tokens the reward tokens and amounts
     */
    event IntentCreated(
        bytes32 indexed hash,
        bytes32 nonce,
        uint256 destination,
        address inbox,
        Call[] calls,
        address indexed creator,
        address indexed prover,
        uint256 expiryTime,
        uint256 nativeValue,
        TokenReward[] tokens
    );

    /**
     * @notice emitted on successful call to withdraw
     * @param _hash the hash of the intent on which withdraw was attempted
     * @param _recipient the address that received the rewards for this intent
     */
    event Withdrawal(bytes32 _hash, address indexed _recipient);

    function getVaultClaimant() external view returns (address);

    function getVaultRefundToken() external view returns (address);

    /**
     * @notice Creates an intent to execute instructions on a contract on a supported chain in exchange for a bundle of assets.
     * @dev If a proof ON THE SOURCE CHAIN is not completed by the expiry time, the reward funds will not be redeemable by the solver, REGARDLESS OF WHETHER THE INSTRUCTIONS WERE EXECUTED.
     * The onus of that time management (i.e. how long it takes for data to post to L1, etc.) is on the intent solver.
     * @param intent The intent struct with all the intent params
     */
    function publishIntent(Intent calldata intent, bool addRewards) external payable;

    /**
     * @notice Validates an intent by checking that the intent's rewards are  valid.
     * @param intent the intent to validate
     */
    function validateIntent(
        Intent calldata intent
    ) external view returns (bool);

    /**
     * @notice allows withdrawal of reward funds locked up for a given intent
     * @param routeHash the hash of the route of the intent
        * @param reward the reward struct of the intent
     */
    function withdrawRewards(bytes32 routeHash, Reward calldata reward) external;

    /**
     * @notice allows withdrawal of reward funds locked up for a given intent
     * @param routeHashes the hashes of the routes of the intents
     * @param rewards the rewards struct of the intents
     */
    function batchWithdraw(bytes32[] calldata routeHashes, Reward[] calldata rewards) external;
}
