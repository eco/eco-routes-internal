// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Route, TokenAmount} from "../types/Intent.sol";

interface IStablePool {
    // Legacy withdrawal queue structure
    struct WithdrawalQueueEntry {
        address user;
        uint80 amount;
        uint16 next; // may need a higher number...
    }

    struct WithdrawalQueueInfo {
        // same size as WithdrawalQueueEntry.next
        uint16 head;
        uint16 tail;
        uint16 highest;
        uint16 lowest;
    }

    // New enhanced withdrawal request structure with priority tracking
    struct WithdrawalRequest {
        address user;           // User requesting withdrawal
        uint256 shareAmount;    // Amount in shares (not tokens)
        address preferredToken; // Token to receive upon withdrawal
        uint256 requestTime;    // Timestamp of request (used for prioritization)
        uint32 waitingPeriod;   // Min time in queue before processing (for priority)
        bool processed;         // Whether this request has been processed
    }

    // Local chain metrics structure
    struct LocalMetrics {
        uint256 profit;        // Local profit since last rebase
        uint256 totalShares;   // Current total shares on this chain
        uint64 timestamp;      // Timestamp of the metrics
    }

    // Rebase result structure
    struct RebaseResult {
        uint256 multiplier;      // New reward multiplier value
        uint256 rebaseId;        // Unique identifier for this rebase
        bool processQueues;      // Flag indicating whether to process withdrawal queues
        uint64 timestamp;        // Timestamp when this result was created
    }

    // Events
    event LitPaused();
    event LitUnpaused();
    
    event WhitelistUpdated(address[] _newWhitelist);
    event TokenThresholdsChanged(TokenAmount[] _newThresholds);
    
    event RebaseFeeChanged(uint256 _newFee);
    event RebalanceFeeChanged(uint256 _newFee);
    event ProtocolFeeChanged(uint256 _newFee);
    event WithdrawerFeeChanged(uint256 _newFee);
    
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event RebalanceComplete(uint32 sourceDomain, uint256 newBalance);
    
    // Legacy event
    event AddedToWithdrawalQueue(address indexed user, WithdrawalQueueEntry entry);
    event WithdrawalQueueThresholdReached(address token);
    
    // New withdrawal queue events
    event WithdrawalQueued(
        uint256 indexed withdrawalId,
        address indexed user, 
        address token, 
        uint256 amount,
        uint256 shares
    );
    event WithdrawalProcessed(
        uint256 indexed withdrawalId,
        address indexed user,
        address token,
        uint256 amount,
        uint256 waitTime
    );
    event WithdrawalCancelled(
        uint256 indexed withdrawalId,
        address indexed user,
        uint256 amount
    );
    event WithdrawalQueueProcessed(
        uint256 processedCount,
        uint256 gasUsed,
        uint256 remainingInQueue
    );
    event WithdrawalQueueProcessingTriggered(uint256 rebaseId);
    event EmergencyWithdrawal(
        address indexed user,
        address indexed token,
        uint256 grossAmount,
        uint256 netAmount,
        uint256 fee
    );
    event PriorityWithdrawalProcessed(uint256 indexed withdrawalId, uint256 waitTime);
    event EstimatedWaitTimeChanged(uint256 oldTime, uint256 newTime);
    event RewardMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier, uint256 rebaseId);
    event RebaseInitiated(uint256 profit, uint256 shares);

    // Custom Errors for Gas Efficiency
    error InvalidToken();
    error InvalidAmount();
    error InsufficientTokenBalance(
        address _token,
        uint256 _balance,
        uint256 _needed
    );
    error InsufficientFees(uint256 _requiredFee);
    error TransferFailed();
    error UseAddToken();
    error UseDelistToken();
    error UseUpdateThreshold();
    error InvalidCaller(address _caller, address _expectedCaller);
    error PoolClosedForCleaning();
    error InvalidSignature(bytes32 _hash, bytes _signature);
    error InvalidTokensHash(bytes32 _expectedHash);
    
    // New errors for the enhanced withdrawal system
    error UnauthorizedMailbox(address actual, address expected);
    error UnauthorizedSender(bytes32 actual, bytes32 expected);
    error InvalidOriginChain(uint32 actual, uint32 expected);
    error UnauthorizedRebaseInitiator(address actual, address expected);
    error InsufficientPoolLiquidity(address token, uint256 amount);
    error UnauthorizedWithdrawalProcessor(address caller);
    error StaleRebase(uint256 lastRebaseTimestamp);
    error WithdrawalProcessingActive();
    error WithdrawalAlreadyProcessed(uint256 withdrawalId);
    error UnauthorizedCancellation(uint256 withdrawalId, address caller);
    error MaxGasLimitReached();
    error InvalidWaitingPeriod(uint32 provided, uint32 min, uint32 max);
    error QueueOverflow(uint256 queueSize, uint256 maxSize);

    // Privileged functions
    function addTokens(
        address[] calldata _oldTokens,
        TokenAmount[] calldata _whitelistChanges
    ) external;

    function delistTokens(
        address[] calldata _oldTokens,
        address[] calldata _toDelist
    ) external;

    function updateThresholds(
        address[] memory _oldTokens,
        TokenAmount[] memory _thresholdChanges
    ) external;

    function initiateRebase(address[] calldata _tokens) external;
    function unpauseLit() external;
    function pauseLit() external;

    // Public functions
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint80 amount) external;
    
    // New withdrawal functions
    function requestWithdrawal(address _preferredToken, uint256 _amount, uint32 _waitingPeriod) external;
    function emergencyWithdraw(address _preferredToken, uint256 _amount) external;
    function cancelWithdrawal(uint256 _withdrawalId) external;
    function getEstimatedWaitTime() external view returns (uint256);
    function processWithdrawalQueue() external;
    
    // View functions
    function getBalance(address user) external view returns (uint256);
    function getProtocolFee() external view returns (uint256);
    function getWithdrawerFee() external view returns (uint256);
    
    function accessLiquidity(
        bytes32 _intentHash,
        uint96 _executionFee,
        Route calldata _route,
        bytes32 _rewardhash,
        address _prover,
        bytes calldata _signature
    ) external payable;
}
