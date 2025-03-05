pragma solidity ^0.8.26;

import {BaseProver} from "./BaseProver.sol";
import {Semver} from "../libs/Semver.sol";
import {ICrossL2ProverV2} from "../interfaces/ICrossL2ProverV2.sol";
import {IIntentSource} from "../interfaces/IIntentSource.sol";
import {Reward, TokenAmount} from "../types/Intent.sol";

/**
 * @title PolymerProver
 * @notice Prover implementation using Polymer's cross-chain messaging system
 * @dev Processes proof messages from Polymer's CrossL2ProverV2 and records proven intents
 */
contract PolymerProver is BaseProver, Semver {
    /**
     * @notice Constant indicating this contract uses Polymer for proving
     */
    ProofType public constant PROOF_TYPE = ProofType.Polymer;

    /**
     * @notice Emitted when attempting to prove an already-proven intent
     * @dev Event instead of error to allow batch processing to continue
     * @param _intentHash Hash of the already proven intent
     */
    event IntentAlreadyProven(bytes32 _intentHash);

    // write custom errors
    error InvalidEventSignature();
    error UnsupportedChainId();
    error InvalidEmittingContract();
    error InvalidTopicsLength();
    error SizeMismatch();

    struct ProverReward {
        address creator;
        uint256 deadline;
        uint256 nativeValue;
        TokenAmount[] tokens;
    }
    /**
     * @notice Address of local Polymer CrossL2ProverV2 contract
     * @dev Immutable contract reference used to validate cross-chain proofs
     */
    ICrossL2ProverV2 public immutable CROSS_L2_PROVER_V2;

    /**
     * @notice Address of local Inbox contract
     * @dev Immutable reference to verify proof origin
     */
    address public immutable INBOX;

    /**
     * @notice Address of local IntentSource contract
     * @dev Immutable reference to verify proof origin
     */
    address public immutable INTENT_SOURCE;

    /**
     * @notice Mapping of supported source chain IDs
     * @dev Chain IDs that this prover accepts proofs from
     */
    mapping(uint32 => bool) public supportedChainIds;

    /**
     * @notice Keccak256 hash of the event signature for intent proofs
     * @dev Used to validate proof event topics
     */
    bytes32 public constant PROOF_SELECTOR =
        keccak256("ToBeProven(bytes32,uint256,address)");

    bytes32 public constant BATCH_PROOF_SELECTOR =
        keccak256("BatchToBeProven(uint256,bytes)");

    /**
     * @notice Initializes the PolymerProver contract
     * @dev Sets up core contract references and supported chain IDs
     * @param _crossL2ProverV2 Address of the Polymer CrossL2ProverV2 contract
     * @param _inbox Address of the Inbox contract that emits proof events
     * @param _supportedChainIds Array of chain IDs that this prover will accept proofs from
     */
    constructor(
        address _crossL2ProverV2,
        address _inbox,
        uint32[] memory _supportedChainIds
    ) {
        CROSS_L2_PROVER_V2 = ICrossL2ProverV2(_crossL2ProverV2);
        INBOX = _inbox;
        for (uint32 i = 0; i < _supportedChainIds.length; i++) {
            supportedChainIds[_supportedChainIds[i]] = true;
        }
    }

    /**
     * @notice Validates a single proof
     * @dev External function called to validate single event proof
     * @param proof The proof data for CROSS_L2_PROVER_V2 to validate
     */
    function validate(bytes calldata proof) external {
        (bytes32 intentHash, address claimant) = _validateProof(proof);
        processIntent(intentHash, claimant);
    }

    function validateAndClaim(bytes calldata proof, bytes32 routeHash, ProverReward calldata proverReward) external {
        (bytes32 intentHash, address claimant) = _validateProof(proof);

        Reward memory reward = _toReward(proverReward);

        validateIntentHash(routeHash, reward, intentHash);
        IIntentSource(INTENT_SOURCE).pushWithdraw(intentHash, routeHash, reward, claimant);
    }

    /**
     * @notice Validates multiple proofs in a batch
     * @dev Processes each proof sequentially
     * @param proofs Array of proof data for CROSS_L2_PROVER_V2 to validate
     */
    function validateBatch(bytes[] calldata proofs) external {
        for (uint256 i = 0; i < proofs.length; i++) {
            (bytes32 intentHash, address claimant) = _validateProof(proofs[i]);
            processIntent(intentHash, claimant);
        }
    }

    function validateBatchAndClaim(bytes[] calldata proofs, bytes32[] calldata routeHashes, ProverReward[] calldata proverRewards) external {
        bytes32[] memory intentHashes = new bytes32[](proofs.length);
        address[] memory claimants = new address[](proofs.length);
        Reward[] memory rewards = new Reward[](proverRewards.length);

        for (uint256 i = 0; i < proofs.length; i++) {
            (bytes32 intentHash, address claimant) = _validateProof(proofs[i]);
            intentHashes[i] = intentHash;
            claimants[i] = claimant;
            rewards[i] = _toReward(proverRewards[i]);
            validateIntentHash(routeHashes[i], rewards[i], intentHashes[i]);
        }
        
        IIntentSource(INTENT_SOURCE).batchPushWithdraw(intentHashes, routeHashes, rewards, claimants);
    }

    /**
     * @notice Validates that a calculated intent hash matches the expected intent hash
     * @dev Calculates the intent hash from route hash and reward, then compares with expected hash
     * @param routeHash The route hash component of the intent
     * @param reward The reward structure to encode
     * @param expectedIntentHash The expected intent hash to compare against
     */
    function validateIntentHash(bytes32 routeHash, Reward memory reward, bytes32 expectedIntentHash) internal pure {
        bytes32 calculatedRewardHash = keccak256(abi.encode(reward));
        bytes32 calculatedIntentHash = keccak256(abi.encodePacked(routeHash, calculatedRewardHash));
        if (calculatedIntentHash != expectedIntentHash) revert("Intent hash mismatch");
    }

    /**
     * @notice Converts a proverReward struct to a Reward struct
     * @dev Sets the prover field to this contract's address
     * @param _proverReward The proverReward struct to convert
     * @return reward The converted Reward struct
     */
    function _toReward(ProverReward memory _proverReward) internal view returns (Reward memory) {
        return Reward(
            _proverReward.creator,
            address(this),
            _proverReward.deadline,
            _proverReward.nativeValue,
            _proverReward.tokens
        );
    }

    /**
     * @notice Core proof validation logic
     * @dev Internal method to validate proof using CrossL2ProverV2 and records proven intents
     * @param proof The proof data to validate
     */
    function _validateProof(bytes calldata proof) internal returns (bytes32 intentHash, address claimant) {
        (
            uint32 chainId,
            address emittingContract,
            bytes memory topics,
            bytes memory data
        ) = CROSS_L2_PROVER_V2.validateEvent(proof);

        // revert checks (might not need chainId check)
        checkInboxContract(emittingContract);
        checkSupportedChainId(chainId);
        checkTopicLength(topics, 128);

        bytes32[] memory topicsArray = new bytes32[](4);

        // Use assembly for efficient memory operations when splitting topics per example
        assembly {
            let topicsPtr := add(topics, 32)
            for {
                let i := 0
            } lt(i, 4) {
                i := add(i, 1)
            } {
                mstore(
                    add(add(topicsArray, 32), mul(i, 32)),
                    mload(add(topicsPtr, mul(i, 32)))
                )
            }
        }

        checkTopicSignature(topicsArray[0], PROOF_SELECTOR);

        address claimant = address(uint160(uint256(topicsArray[3])));

        return (topicsArray[1], claimant);
    }

    /**
     * @notice Validates a packed format proof
     * @dev Currently unimplemented
     * @param proof The packed proof data to validate
     */
    function validatePacked(bytes calldata proof) external {
        _validatePackedProof(proof);
    }

    /**
     * @notice Validates multiple packed format proofs in a batch
     * @dev Currently unimplemented
     * @param proofs Array of packed proof data to validate
     */
    function validateBatchPacked(bytes[] calldata proofs) external {
        for (uint256 i = 0; i < proofs.length; i++) {
            _validatePackedProof(proofs[i]);
        }
    }

    /**
     * @notice Internal function to validate a packed proof
     * @dev Currently unimplemented
     * @param proof The packed proof data to validate
     */
    function _validatePackedProof(bytes calldata proof) internal {
        (
            uint32 chainId,
            address emittingContract,
            bytes memory topics,
            bytes memory data
        ) = CROSS_L2_PROVER_V2.validateEvent(proof);

        // revert checks (might not need chainId check)
        checkInboxContract(emittingContract);
        checkSupportedChainId(chainId);
        checkTopicLength(topics, 64); //signature and chainId
        checkTopicSignature(bytes32(topics), BATCH_PROOF_SELECTOR);

        //maybe add check that chainId from topics matches this chainId
        //but not needed because hash uniqueness is guaranteed by the source chain

        decodeMessageandStore(data);
    }

    /**
     * @notice Decodes a message body into intent hashes and claimants and stores them
     * @dev Used to decode the data from the BatchToBeProven event. The message body contains
     * chunks of intent hashes grouped by claimant. Each chunk has a 2-byte size prefix,
     * followed by a 20-byte claimant address, followed by the intent hashes.
     * @param messageBody The message body to decode
     */
    function decodeMessageandStore(bytes memory messageBody) internal {
        uint256 size = messageBody.length;
        uint256 offset = 0;

        //might be able to do this more efficently by checking 1-2 require instead of 3
        while (offset < size) {
            //get chunkSize and check for truncation
            uint16 chunkSize;
            require(offset + 2 <= size, "truncated chunkSize");
            assembly {
                chunkSize := mload(add(messageBody, add(offset, 2)))
                offset := add(offset, 2)
            }

            //get claimant address and check for truncation
            require(offset + 20 <= size, "truncated claimant address");
            address claimant;
            assembly {
                claimant := mload(add(messageBody, add(offset, 20)))
                offset := add(offset, 20)
            }

            //get intentHash and check for truncation
            require(offset + 32 * chunkSize <= size, "truncated intent set");
            bytes32 intentHash;
            for (uint16 i = 0; i < chunkSize; i++) {
                assembly {
                    intentHash := mload(add(messageBody, add(offset, 32)))
                    offset := add(offset, 32)
                }
                processIntent(intentHash, claimant);
            }
        }
    }

    function validatePackedAndClaim(bytes calldata proof, bytes32[] calldata routeHashes, ProverReward[] calldata proverRewards) external {
        _validatePackedAndClaim(proof, routeHashes, proverRewards);
    }

    function validateBatchPackedAndClaim(bytes[] calldata proofs, bytes32[][] calldata routeHashes, ProverReward[][] calldata proverRewards) external {
        for (uint256 i = 0; i < proofs.length; i++) {
            _validatePackedAndClaim(proofs[i], routeHashes[i], proverRewards[i]);
        }
    }
    function _validatePackedAndClaim(bytes calldata proof, bytes32[] calldata routeHashes, ProverReward[] calldata proverRewards) internal {
        (
            uint32 chainId,
            address emittingContract,
            bytes memory topics,
            bytes memory data
        ) = CROSS_L2_PROVER_V2.validateEvent(proof);

        // revert checks (might not need chainId check)
        checkInboxContract(emittingContract);
        checkSupportedChainId(chainId);
        checkTopicLength(topics, 64); //signature and chainId
        checkTopicSignature(bytes32(topics), BATCH_PROOF_SELECTOR);

        //maybe add check that chainId from topics matches this chainId
        //but not needed because hash uniqueness is guaranteed by the source chain

        decodeMessageandClaim(data, routeHashes, proverRewards);
    }

    function decodeMessageandClaim(bytes memory messageBody, bytes32[] calldata routeHashes, ProverReward[] calldata proverRewards) internal {
        uint256 size = messageBody.length;
        uint256 offset = 0;
        uint256 totalIntentHashes = 0;

        //might be able to do this more efficently by checking 1-2 require instead of 3
        while (offset < size) {
            //get chunkSize and check for truncation
            uint16 chunkSize;
            require(offset + 2 <= size, "truncated chunkSize");
            assembly {
                chunkSize := mload(add(messageBody, add(offset, 2)))
                offset := add(offset, 2)
            }

            //get claimant address and check for truncation
            require(offset + 20 <= size, "truncated claimant address");
            address claimant;
            assembly {
                claimant := mload(add(messageBody, add(offset, 20)))
                offset := add(offset, 20)
            }

            //get intentHash and check for truncation

            require(offset + 32 * chunkSize <= size, "truncated intent set");
            bytes32 intentHash;
            bytes32[] memory intentHashes = new bytes32[](chunkSize);
            Reward[] memory rewards = new Reward[](chunkSize);
            address[] memory claimants = new address[](chunkSize);
            uint256 startingIndex = totalIntentHashes;
            
            for (uint16 i = 0; i < chunkSize; i++) {
                assembly {
                    intentHash := mload(add(messageBody, add(offset, 32)))
                    offset := add(offset, 32)
                }
                intentHashes[i] = intentHash;
                rewards[i] = _toReward(proverRewards[totalIntentHashes]);
                validateIntentHash(routeHashes[totalIntentHashes], rewards[i], intentHashes[i]);
                claimants[i] = claimant;
                totalIntentHashes++;
            }
            IIntentSource(INTENT_SOURCE).batchPushWithdraw(intentHashes, routeHashes[startingIndex:totalIntentHashes], rewards, claimants);
        }
    }

    /**
     * @notice Processes a single intent proof
     * @dev Updates proven intent mapping and emits event if not already proven
     * @param intentHash Hash of the intent being proven
     * @param claimant Address that fulfilled the intent and should receive rewards
     */
    function processIntent(bytes32 intentHash, address claimant) internal {
        if (provenIntents[intentHash] != address(0)) {
            emit IntentAlreadyProven(intentHash);
        } else {
            provenIntents[intentHash] = claimant;
            emit IntentProven(intentHash, claimant);
        }
    }

    function checkTopicSignature(
        bytes32 topic,
        bytes32 selector
    ) internal pure {
        if (topic != selector) revert InvalidEventSignature();
    }

    function checkInboxContract(address emittingContract) internal view {
        if (emittingContract != INBOX) revert InvalidEmittingContract();
    }

    function checkSupportedChainId(uint32 chainId) internal view {
        if (!supportedChainIds[chainId]) revert UnsupportedChainId();
    }

    function checkTopicLength(
        bytes memory topics,
        uint256 length
    ) internal pure {
        if (topics.length != length) revert InvalidTopicsLength();
    }

    /**
     * @notice Returns the proof type used by this prover
     * @dev Implementation of IProver interface method
     * @return ProofType The type of proof mechanism (Polymer)
     */
    function getProofType() external pure override returns (ProofType) {
        return PROOF_TYPE;
    }
}
