pragma solidity ^0.8.26;

import {BaseProver} from "./BaseProver.sol";
import {Semver} from "../libs/Semver.sol";
import {ICrossL2ProverV2} from "../interfaces/ICrossL2ProverV2.sol";


contract PolymerProver is BaseProver, Semver {
    ProofType public constant PROOF_TYPE = ProofType.Polymer;

    /**
     * @notice Emitted when attempting to prove an already-proven intent
     * @dev Event instead of error to allow batch processing to continue
     * @param _intentHash Hash of the already proven intent
     */
    event IntentAlreadyProven(bytes32 _intentHash);

    ICrossL2ProverV2 public immutable CROSS_L2_PROVER_V2;

    address public immutable INBOX;

    mapping(uint32 => bool) public supportedChainIds;

    bytes32 public constant PROOF_SELECTOR = keccak256("ToBeProven(bytes32,uint256,address)");

    constructor(address _crossL2ProverV2, address _inbox, uint32[] memory _supportedChainIds) {
        CROSS_L2_PROVER_V2 = ICrossL2ProverV2(_crossL2ProverV2);
        INBOX = _inbox;
        for (uint32 i = 0; i < _supportedChainIds.length; i++) {
            supportedChainIds[_supportedChainIds[i]] = true;
        }
    }

    function validateIntentFufillment(bytes calldata proof) external {
        //validate event using CrossL2ProverV2
        (
            uint32 chainId,
            address emittingContract,
            bytes memory topics,
            bytes memory data
        ) = CROSS_L2_PROVER_V2.validateEvent(proof);

       
        require(emittingContract == INBOX, "Invalid emitting contract");

        // might not need this check
        require(supportedChainIds[chainId], "Unsupported chainId"); 

        //deconstruct topics into intent hash, chainId, and claimant
        bytes32[] memory topicsArray = new bytes32[](3);
        require(topics.length >= 96, "Invalid topics length");

        // Use assembly for efficient memory operations when splitting topics per example
        assembly {
            let topicsPtr := add(topics, 32)
            
            for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                mstore(
                    add(add(topicsArray, 32), mul(i, 32)),
                    mload(add(topicsPtr, mul(i, 32)))
                )
            }
        }
        require(topicsArray[0] == PROOF_SELECTOR, "Invalid event signature");

        bytes32 intentHash = topicsArray[1];

        address claimant = address(uint160(uint256(topicsArray[3])));

        if (provenIntents[intentHash] != address(0)) {
            emit IntentAlreadyProven(intentHash);
        } else {
            provenIntents[intentHash] = claimant;
            emit IntentProven(intentHash, claimant);
        }

    }


    
    /**
     * @notice Returns the proof type used by this prover
     * @return ProofType indicating Polymer proving mechanism
     */
    function getProofType() external pure override returns (ProofType) {
        return PROOF_TYPE;
    }
}
