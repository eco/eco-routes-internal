# Implementation Plan: Rebase Flow Implementation

> **FOLLOW [INSTRUCTIONS](../CLAUDE.md)!**
>
> ## Key Process References
>
> - **General Process**: Follow the [Task Execution Protocol](../CLAUDE.md#mandatory-execution-sequence)
> - **Decision Management**: Apply the [Decision Architecture](../CLAUDE.md#decision-architecture)
> - **Error Handling**: Use the [Problem Resolution System](../CLAUDE.md#problem-resolution-system)
> - **Scope Management**: Respect [Issue Classification System](../CLAUDE.md#issue-classification-system)
> - **Code Standards**: Implement [Solidity Implementation Requirements](../CLAUDE.md#solidity-implementation-requirements)
> - **Quality Assurance**: Follow [Development Discipline](../CLAUDE.md#development-discipline)
> - **Testing Commands**: Use [Solidity Development Imperatives](../CLAUDE.md#solidity-development-imperatives)
> - **Git Framework**: Adhere to [Git Execution Framework](../CLAUDE.md#git-execution-framework)

## Executive Summary

This implementation plan details the cross-chain Rebase Flow mechanism for the Eco Routes Protocol. The rebase flow ensures eUSD tokens maintain consistent value across all supported chains through a three-phase process: collection of local pool metrics, centralized calculation of the global multiplier, and distribution of updated rates to all participating chains. This implementation will fix critical bugs in the existing contracts, optimize cross-chain messaging, and provide robust error handling for all components.

## Implementation Information

- **Category**: Feature
- **Priority**: Critical
- **Estimated Time**: 10 hours
- **Affected Components**: StablePool, Rebaser, EcoDollar, Hyperlane integration
- **Parent Project Plan**: [Crowd Liquidity Project Plan](./crowd-liquidity-project-plan.md)
- **Related Implementation Plans**: None
- **Git Branch**: feat/rebase/rebase-flow-implementation

## Current Status and Technical Context

### System Architecture

The Rebase Flow operates across a multi-chain architecture with these core components:

1. **StablePool (per chain)**: Manages deposits/withdrawals and initiates rebase flow
2. **Rebaser (home chain only)**: Central coordinator for cross-chain rebase calculations
3. **EcoDollar (per chain)**: Rebasing token that uses share-based accounting
4. **Hyperlane Integration**: Cross-chain messaging protocol for communication

### Current Implementation Status

- **StablePool**: Basic rebase initiation exists but lacks proper state management
- **Rebaser**: Most calculation logic exists but needs error handling improvements
- **EcoDollar**: Share-based accounting implemented but rebase function needs validation
- **Critical Bug**: Double burn in StablePool withdraw function must be fixed
- **Missing Components**: Proper error handling, comprehensive testing, event emissions

## Goals and Scope

### Primary Goals

1. Implement complete cross-chain rebase flow matching the swimlane diagram
2. Fix critical issues in existing implementation (update reward multiplier, remove rebaseInProgress flag)
3. Ensure mathematically correct profit calculation and distribution
4. Implement secure protocol share allocation and treasury distribution
5. Build comprehensive test suite covering the entire rebase flow

### Out of Scope

1. Changes to the fundamental architecture of the system
2. Withdrawal queue processing (in a separate implementation plan)
3. Cross-chain message handling (will be handled by a service)
4. Testing integration with external messaging service
5. Changes to deployment strategy
6. UI integration or external system interactions

## Decision Points

### Decision 1: Rebase Trigger Mechanism

- [x] **Option A: Admin-triggered rebases**
  - **Pros**: Precise control over timing, gas optimization through batching, predictable operations
  - **Cons**: Requires active management, less autonomous than automated approaches
  - **Performance impact**: Less frequent rebases with potentially higher gas per operation
  - **Security implications**: Lower risk of timing manipulation, explicit authorization for each rebase
  
- [ ] **Option B: Automatic threshold-based rebases**
  - **Pros**: Fully autonomous operation, no manual intervention required
  - **Cons**: May trigger at suboptimal network times, harder to predict execution
  - **Performance impact**: More frequent rebases during volatile conditions
  - **Security implications**: Potential for gaming threshold triggers, complex validation needs

**Decision**: Option A selected (Admin-triggered rebases) based on user confirmation on 2025-03-26.

**Rationale**: Admin-triggered rebases provide precise operational control, align with the explicit "Start" action in the swimlane diagram, and enable gas optimization by scheduling rebases during low-congestion periods. This approach also reduces attack vectors by requiring explicit authorization.

### Decision 2: Protocol Fee Distribution

- [x] **Option A: Automatically mint protocol share to treasury**
  - **Pros**: Immediate fee capture, simpler execution flow, reduced gas costs
  - **Cons**: Less flexibility in fee allocation compared to delayed distribution
  - **Performance impact**: More gas-efficient due to single-step processing
  - **Security implications**: Cleaner security model with fewer entry points
  
- [ ] **Option B: Store protocol share for later distribution**
  - **Pros**: More flexible distribution strategies, adjustable allocation post-rebase
  - **Cons**: More complex state management, additional transactions needed
  - **Performance impact**: Less gas-efficient due to multi-step processing
  - **Security implications**: More attack vectors with additional entry points

**Decision**: Option A selected (Automatically mint protocol share to treasury) based on user confirmation on 2025-03-26.

**Rationale**: Direct minting to treasury provides a simpler implementation with fewer security considerations while reducing gas costs associated with fee management. This approach aligns with the current Rebaser contract design and provides predictable fee capture behavior.

## Technical Analysis

### Rebase Flow Process (from high-definition swimlane diagram)

The rebase flow follows this exact process as shown in the swimlane diagram:

#### 1. Spoke Chain (Collection Phase)
- Process starts with admin trigger ("Start" in diagram)
- Pool earns funds from a yield source
- Profit is tracked as a variable in the StablePool contract
- Total EcoDollar shares are tracked and updated on deposits/withdrawals
- Send a message to home chain with amount of profit and current total shares
- Set the profit to 0 in storage (critical for preventing double-counting)
- Later: Receive and set the current multiplier from home chain
- End rebase process

#### 2. Hyperlane (Messaging Layer)
- Send profit information to home chain
- Later: Send updated multiplier to all spoke chains
- Handle message delivery between chains

#### 3. Home Chain (Calculation Phase)
- Aggregate total shares reported from all chains
- Track total supply across the entire protocol
- Calculate ratio of total supply and profit that was received
- Determine protocol share (fraction of profit allocated to protocol)
- Mint tokens representing protocol share to the treasury
- Calculate new multiplier based on remaining profit and total shares
- Send the updated multiplier to all spoke chains


### Visual Implementation Flow

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#2D74BA', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#1D4E89', 'lineColor': '#5D9CEC', 'secondaryColor': '#1D2B3A', 'tertiaryColor': '#132030', 'textColor': '#FFFFFF', 'fontSize': '14px', 'fontFamily': 'Arial', 'edgeLabelBackground': '#132030', 'mainBkg': '#132030', 'clusterBkg': '#1D2B3A', 'nodeTextColor': '#FFFFFF', 'nodeBorder': '#2D74BA', 'labelTextColor': '#FFFFFF', 'clusterBorder': '#1D4E89' }}}%%

flowchart TB
    subgraph "Spoke Chain"
        start["Start\n(Admin Triggered)"] --> collectYield["Pool earns funds\nfrom a yield"]
        collectYield --> saveProfit["Save amount of\nprofit internally"]
        saveProfit --> sendToHome["Send message to home\nwith amount of profit"]
        sendToHome --> resetProfit["Set profit to 0\nin storage"]
        receiveMultiplier["Receive updated\nmultiplier"] --> setMultiplier["Set the current\nmultiplier"]
        setMultiplier --> endProcess["End"]
    end

    subgraph "Hyperlane"
        sendMsgToHome["Send profit\nto home"]
        sendMsgToSpokes["Send to all\nspokes"]
        handleDelivery["Handle message\ndelivery"]
    end

    subgraph "Home Chain"
        aggregateShares["Aggregate total shares\nfrom all chains"]
        aggregateShares --> calculateRatio["Calculate ratio of\ntotal supply and profit"]
        calculateRatio --> determineProtocolShare["Determine protocol share\nfraction of profit"]
        determineProtocolShare --> mintToTreasury["Mint tokens representing\nprotocol share to treasury"]
        mintToTreasury --> calculateMultiplier["Calculate new multiplier\nbased on remaining profit"]
        calculateMultiplier --> distributeRate["Send updated multiplier\nto all spokes"]
    end

    sendToHome --> sendMsgToHome
    sendMsgToHome --> aggregateShares
    calculateMultiplier --> sendMsgToSpokes
    sendMsgToSpokes --> receiveMultiplier

    classDef started fill:#37996E,stroke:#1E5941,stroke-width:2px,color:#FFFFFF
    classDef critical fill:#B85D2D,stroke:#89351D,stroke-width:2px,color:#FFFFFF
    class start,calculateRatio started
    class resetProfit,determineProtocolShare critical
```

The diagram above illustrates the complete implementation flow with:
- **Green nodes**: Starting points in the process
- **Yellow nodes**: Critical operations that require special attention
- **Arrows**: Data flow between components

### Critical Issues Requiring Fixes

1. **No Validation Needed in EcoDollar.updateRewardMultiplier()**: Multiplier can be set to any value as determined by the rebase process.



## Implementation Details

### Files to Modify

- **contracts/StablePool.sol**
  - Add profit tracking variable to store accumulated profit
  - Update deposit and withdraw functions to track and report EcoDollar shares
  - Enhance rebase initiation with fixed authority check
  - Implement handle function for receiving rebase data
  - Add direct access to update EcoDollar's multiplier
  - Add event emissions for tracking share changes and rebase events

- **contracts/Rebaser.sol**
  - Implement tracking of total EcoDollar shares across all chains
  - Add share aggregation logic to handle function
  - Optimize protocol share calculation using protocolShareRate
  - Add owner-controlled function to update protocolShareRate
  - Add proper event emissions for share tracking and protocol share allocation
  - Combine chains and validChainIDs as a struct
  - Maintain proper protocol state for external message handling service

- **contracts/EcoDollar.sol**
  - Remove public rebase function entirely
  - Add privileged updateRewardMultiplier method accessible only to StablePool
  - Ensure share-to-token conversion remains accurate
  - Add event emissions for multiplier changes

- **contracts/interfaces/IEcoDollar.sol**
  - Add updateRewardMultiplier to interface for StablePool access

- **test/RebaseFlow.t.sol** (new file)
  - Implement comprehensive test suite for rebase flow

### Core Architecture Enhancements

#### 1. Improved Share Tracking Approaches

After analyzing the challenges with per-transaction delta updates, we've identified more robust approaches for keeping the Rebaser updated with total shares:

##### Approach A: Periodic Batch Updates with Pre-Rebase Sync (Recommended)

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#2D74BA', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#1D4E89', 'lineColor': '#5D9CEC', 'secondaryColor': '#1D2B3A', 'tertiaryColor': '#132030', 'textColor': '#FFFFFF', 'fontSize': '14px', 'fontFamily': 'Arial', 'edgeLabelBackground': '#132030', 'mainBkg': '#132030', 'clusterBkg': '#1D2B3A', 'altBackground': '#132030', 'actorBkg': '#2D74BA', 'actorBorder': '#1D4E89', 'actorTextColor': '#FFFFFF', 'noteBkgColor': '#284665', 'noteBorderColor': '#2D74BA', 'noteTextColor': '#FFFFFF' }}}%%

sequenceDiagram
    participant Users
    participant StablePool
    participant EcoDollar
    participant Mailbox
    participant Rebaser
    
    rect rgb(24, 44, 67)
    Note over Users,StablePool: Normal Operation Period
    Users->>StablePool: Multiple deposits/withdrawals
    StablePool->>EcoDollar: mint/burn operations
    EcoDollar-->>EcoDollar: Update shares internally
    end
    
    rect rgb(32, 59, 89)
    Note over StablePool,Rebaser: Scheduled Batch Update (e.g., hourly)
    StablePool->>EcoDollar: getTotalShares()
    EcoDollar-->>StablePool: Current total shares
    StablePool->>StablePool: Store previous reported shares
    StablePool->>StablePool: Calculate net change since last report
    StablePool->>Mailbox: Send batch update with (total, changeAmount, sequenceNum)
    Mailbox-->>Rebaser: Deliver batch update
    Rebaser->>Rebaser: Update chainShares with sequence verification
    Rebaser->>Rebaser: Update totalShares across chains
    end
    
    rect rgb(49, 78, 112)
    Note over StablePool,Rebaser: Mandatory Pre-Rebase Sync
    Note right of Rebaser: Rebase Initiated
    Rebaser->>Rebaser: Request current shares from all pools
    Rebaser->>Mailbox: Send share verification request
    Mailbox-->>StablePool: Deliver verification request
    StablePool->>EcoDollar: getTotalShares()
    EcoDollar-->>StablePool: Current exact shares
    StablePool->>Mailbox: Send exact share count with high priority
    Mailbox-->>Rebaser: Deliver exact share count
    Rebaser->>Rebaser: Update with authoritative values
    Rebaser->>Rebaser: Proceed with rebase calculations
    end
```

##### Approach B: Threshold-Based Delta Updates with Reconciliation

```mermaid
%%{init: {'theme': 'dark', 'themeVariables': { 'primaryColor': '#2D74BA', 'primaryTextColor': '#FFFFFF', 'primaryBorderColor': '#1D4E89', 'lineColor': '#5D9CEC', 'secondaryColor': '#1D2B3A', 'tertiaryColor': '#132030', 'textColor': '#FFFFFF', 'fontSize': '14px', 'fontFamily': 'Arial', 'edgeLabelBackground': '#132030', 'mainBkg': '#132030', 'clusterBkg': '#1D2B3A', 'nodeTextColor': '#FFFFFF', 'nodeBorder': '#2D74BA', 'labelTextColor': '#FFFFFF', 'clusterBorder': '#1D4E89' }}}%%

flowchart TD
    subgraph "StablePool Operations"
        deposit["Deposit/Withdraw Operations"]
        deposit --> updateLocal["Update Local Delta Counter"]
        updateLocal --> checkThreshold{"Delta > Threshold?"}
        checkThreshold -->|Yes| sendUpdate["Send Delta Update to Rebaser"]
        checkThreshold -->|No| continue["Continue Operations"]
        
        timer["Timer (15-minute interval)"]
        timer --> checkPending{"Pending Deltas?"}
        checkPending -->|Yes| sendBatch["Send Accumulated Deltas"]
        checkPending -->|No| reset["Reset Timer"]
        
        rebaseReq["Rebase Request Received"]
        rebaseReq --> sendExact["Send Exact Share Count with High Priority"]
    end
    
    subgraph "Rebaser Operations"
        receiveUpdate["Receive Delta Updates"]
        receiveUpdate --> applyDelta["Apply to Chain Shares"]
        applyDelta --> updateTotal["Update Total Shares"]
        
        receiveExact["Receive Exact Share Count"]
        receiveExact --> reconcile["Reconcile with Current Value"]
        reconcile --> detectDrift{"Significant Drift?"}
        detectDrift -->|Yes| recordIssue["Record Discrepancy"]
        detectDrift -->|No| useExact["Use Exact Value for Rebase"]
        
        weekly["Weekly Reconciliation"]
        weekly --> requestCounts["Request Exact Counts from All Chains"]
    end
    
    sendUpdate --> receiveUpdate
    sendBatch --> receiveUpdate
    sendExact --> receiveExact
    requestCounts --> rebaseReq
    
    classDef normal fill:#1D2B3A,stroke:#2D74BA,color:#FFFFFF
    classDef important fill:#B85D2D,stroke:#89351D,color:#FFFFFF,stroke-width:2px
    classDef process fill:#284665,stroke:#2D74BA,color:#FFFFFF
    
    class deposit,updateLocal,continue,timer normal
    class sendUpdate,sendBatch,sendExact,receiveExact,reconcile,requestCounts process
    class rebaseReq,detectDrift,recordIssue,useExact important
```

##### Implementation Details

```solidity
/**
 * @notice Batch-based share tracking implementation (Approach A)
 */

/**
 * @notice Standard deposit function without immediate share updates
 * @param _token The token to deposit
 * @param _amount The amount to deposit
 */
function deposit(address _token, uint256 _amount) external {
    // Verify token is whitelisted
    if (tokenThresholds[_token] == 0) {
        revert InvalidToken(_token);
    }
    
    // Transfer token from user to pool
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    
    // Mint eUSD tokens to the user
    IEcoDollar(REBASE_TOKEN).mint(msg.sender, _amount);
    
    // Get current shares for local tracking only
    uint256 currentShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
    
    // Emit events for tracking
    emit Deposited(msg.sender, _token, _amount);
    emit SharesUpdated(currentShares);
    
    // No immediate cross-chain communication
    // Shares will be reported in next scheduled batch update
}

/**
 * @notice Standard withdrawal function without immediate share updates
 * @param _preferredToken The token to withdraw
 * @param _amount The amount to withdraw
 */
function withdraw(address _preferredToken, uint80 _amount) external {
    // Verify token is whitelisted
    if (tokenThresholds[_preferredToken] == 0) {
        revert InvalidToken(_preferredToken);
    }
    
    // Check user's balance
    uint256 tokenBalance = IERC20(REBASE_TOKEN).balanceOf(msg.sender);
    if (tokenBalance < _amount) {
        revert InsufficientTokenBalance(
            _preferredToken,
            tokenBalance,
            _amount
        );
    }
    
    // Burn eUSD tokens
    IEcoDollar(REBASE_TOKEN).burn(msg.sender, _amount);
    
    // Get current shares for local tracking only
    uint256 currentShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
    
    // Local tracking only - no cross-chain update
    emit SharesUpdated(currentShares);
    
    // Process withdrawal
    if (IERC20(_preferredToken).balanceOf(address(this)) > tokenThresholds[_preferredToken] + _amount) {
        // Sufficient liquidity, process withdrawal immediately
        IERC20(_preferredToken).safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _preferredToken, _amount);
    } else {
        // Insufficient liquidity, add to withdrawal queue
        _addToWithdrawalQueue(_preferredToken, msg.sender, _amount);
    }
}

/**
 * @notice Periodic batch update of share totals to Rebaser
 * @dev Called on a scheduled basis (e.g., hourly) or before rebases
 */
function sendSharesUpdate() external {
    // Only callable by authorized scheduler or admin
    if (msg.sender != SCHEDULER && msg.sender != owner()) {
        revert UnauthorizedSharesUpdate(msg.sender);
    }
    
    // Get current total shares
    uint256 currentShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
    
    // Calculate net change since last report
    int256 changeAmount = int256(currentShares) - int256(lastReportedShares);
    
    // Create batch update with metadata
    BatchShareUpdate memory update = BatchShareUpdate({
        totalShares: currentShares,
        changeSinceLastReport: changeAmount,
        sequenceNumber: ++updateSequence,
        timestamp: block.timestamp
    });
    
    // Encode message with batch update
    bytes memory message = abi.encode(update);
    
    // Send to Rebaser
    uint256 fee = IMailbox(MAILBOX).quoteDispatch(
        HOME_CHAIN,
        REBASER,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    IMailbox(MAILBOX).dispatch{value: fee}(
        HOME_CHAIN,
        REBASER,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    // Update last reported value for next time
    lastReportedShares = currentShares;
    
    emit SharesBatchUpdated(currentShares, changeAmount, updateSequence);
}

/**
 * @notice Responds to a verification request from Rebaser
 * @param _requestId Unique identifier for the verification request
 */
function respondToShareVerification(uint256 _requestId) external {
    // Only callable by authorized verifier or admin
    if (msg.sender != VERIFIER && msg.sender != owner()) {
        revert UnauthorizedVerification(msg.sender);
    }
    
    // Get exact current share count
    uint256 exactShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
    
    // Prepare high-priority verification response
    bytes memory message = abi.encode(
        ShareVerification({
            requestId: _requestId,
            exactShares: exactShares,
            timestamp: block.timestamp,
            isPreRebase: true
        })
    );
    
    // Send with higher gas limit and priority to ensure delivery before rebase
    uint256 fee = IMailbox(MAILBOX).quoteDispatch(
        HOME_CHAIN,
        REBASER,
        message,
        abi.encode(true), // High priority flag
        IPostDispatchHook(RELAYER)
    );
    
    IMailbox(MAILBOX).dispatch{value: fee}(
        HOME_CHAIN,
        REBASER,
        message,
        abi.encode(true), // High priority flag
        IPostDispatchHook(RELAYER)
    );
    
    // Update last verified value
    lastVerifiedShares = exactShares;
    
    emit SharesVerified(_requestId, exactShares);
}
```

#### 2. Rebaser Enhanced Share Tracking

##### Robust Share Tracking System with Verification

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#6C78AF', 'primaryTextColor': '#fff', 'primaryBorderColor': '#5D69A0', 'lineColor': '#5D69A0', 'secondaryColor': '#D3D8F9', 'tertiaryColor': '#E7E9FC' }}}%%

flowchart TD
    subgraph "Chain 1 (Optimism)"
        deposit1["User deposits tokens"]
        deposit1 --> update1["Update local shares"]
        withdraw1["User withdraws tokens"]
        withdraw1 --> burn1["Burn tokens & update shares"]
        
        update1 --> send1["Send immediate share update to Rebaser"]
        burn1 --> send1
        send1 --> shares1["chainShares[Chain1]"]
    end
    
    subgraph "Chain 2 (Base)"
        deposit2["User deposits tokens"]
        deposit2 --> update2["Update local shares"]
        withdraw2["User withdraws tokens"]
        withdraw2 --> burn2["Burn tokens & update shares"]
        
        update2 --> send2["Send immediate share update to Rebaser"]
        burn2 --> send2
        send2 --> shares2["chainShares[Chain2]"]
    end
    
    subgraph "Home Chain"
        rebaser["Rebaser contract"]
        updateShares["updateChainShares()"]
        
        shares1 --> updateShares
        shares2 --> updateShares
        
        updateShares --> aggregate["Aggregate total shares"]
        aggregate --> globalShares["totalShares (always current)"]
        globalShares --> emit["Emit TotalSharesUpdated"]
        
        rebaseStart["initiateRebase()"]
        rebaseStart --> useShares["Use current totalShares"]
        useShares --> calc["Calculate new multiplier"]
        calc --> distribute["Distribute multiplier"]
    end
    
    classDef chain1 fill:#D4F1F9,stroke:#05445E
    classDef chain2 fill:#D1F0B1,stroke:#2D5016
    classDef home fill:#FFE8D4,stroke:#8B4000
    classDef crit fill:#FFD700,stroke:#B8860B,stroke-width:2px
    
    class deposit1,update1,withdraw1,burn1,send1 chain1
    class deposit2,update2,withdraw2,burn2,send2 chain2
    class rebaser,updateShares,aggregate,globalShares,emit,rebaseStart,useShares,calc,distribute home
    class send1,send2,globalShares crit
```

##### Implementation Details

```solidity
/**
 * @dev Processes and aggregates shares from all chains
 * @param _origin The chain ID that reported shares
 * @param _shares The number of shares reported from that chain
 */
// Define data structures for robust share tracking
struct BatchShareUpdate {
    uint256 totalShares;        // Current total shares on this chain
    int256 changeSinceLastReport; // Net change since last report
    uint64 sequenceNumber;      // Monotonically increasing sequence number
    uint64 timestamp;           // Timestamp of this update
}

struct ShareVerification {
    uint256 requestId;         // ID of the verification request
    uint256 exactShares;       // Exact current share count
    uint64 timestamp;          // Timestamp of verification
    bool isPreRebase;          // Whether this was requested before a rebase
}

/**
 * @notice Process batch share updates from StablePool
 * @param _origin The chain ID from which the message was sent
 * @param _sender The address that sent the message (32-byte form)
 * @param _message The encoded batch update
 */
function handleBatchShareUpdate(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
) external payable {
    // Security validations
    if (msg.sender != MAILBOX) {
        revert UnauthorizedMailbox(msg.sender, MAILBOX);
    }
    
    if (_sender != POOL) {
        revert UnauthorizedSender(_sender, POOL);
    }
    
    if (!validChainIDs[_origin]) {
        revert InvalidOriginChain(_origin);
    }
    
    // Decode batch update
    BatchShareUpdate memory update = abi.decode(_message, (BatchShareUpdate));
    
    // Sequence number verification to prevent replay or out-of-order processing
    if (update.sequenceNumber <= chainLastSequence[_origin]) {
        // Skip or log outdated updates but don't revert
        emit OutdatedShareUpdate(_origin, update.sequenceNumber, chainLastSequence[_origin]);
        return;
    }
    
    // Update sequence tracking
    chainLastSequence[_origin] = update.sequenceNumber;
    
    // Update chain shares with the new total
    chainShares[_origin] = update.totalShares;
    chainLastUpdated[_origin] = update.timestamp;
    
    // Recalculate total shares across all chains
    _recalculateTotalShares();
    
    // Emit event for tracking
    emit BatchSharesUpdated(
        _origin, 
        update.totalShares, 
        update.changeSinceLastReport, 
        update.sequenceNumber
    );
}

/**
 * @notice Process share verification message (used before rebases)
 * @param _origin The chain ID from which the message was sent
 * @param _sender The address that sent the message (32-byte form)
 * @param _message The encoded verification data
 */
function handleShareVerification(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
) external payable {
    // Security validations
    if (msg.sender != MAILBOX) {
        revert UnauthorizedMailbox(msg.sender, MAILBOX);
    }
    
    if (_sender != POOL) {
        revert UnauthorizedSender(_sender, POOL);
    }
    
    if (!validChainIDs[_origin]) {
        revert InvalidOriginChain(_origin);
    }
    
    // Decode verification data
    ShareVerification memory verification = abi.decode(_message, (ShareVerification));
    
    // Check if this is a response to our verification request
    if (verificationRequests[verification.requestId].isActive) {
        // Mark request as fulfilled
        verificationRequests[verification.requestId].fulfilled = true;
        verificationRequests[verification.requestId].responseTime = block.timestamp;
    }
    
    // Update chain shares with the verified exact value
    uint256 previousShares = chainShares[_origin];
    chainShares[_origin] = verification.exactShares;
    chainLastVerified[_origin] = verification.timestamp;
    
    // Check for significant drift between reported and actual values
    int256 drift = int256(verification.exactShares) - int256(previousShares);
    if (uint256(drift < 0 ? -drift : drift) > DRIFT_THRESHOLD) {
        emit SignificantShareDrift(_origin, previousShares, verification.exactShares, drift);
    }
    
    // Recalculate total shares across all chains
    _recalculateTotalShares();
    
    // Update verification status for this chain
    chainVerified[_origin] = true;
    
    // If this is a pre-rebase verification and we have verification from all chains, mark ready
    if (verification.isPreRebase) {
        // Check if all chains are verified
        bool allVerified = true;
        for (uint256 i = 0; i < chains.length; i++) {
            if (!chainVerified[chains[i]]) {
                allVerified = false;
                break;
            }
        }
        
        if (allVerified) {
            readyForRebase = true;
            emit AllChainsVerified(totalShares);
        }
    }
    
    emit ShareVerificationProcessed(
        _origin,
        verification.requestId, 
        verification.exactShares,
        verification.isPreRebase
    );
}

/**
 * @notice Request verification of share counts from all chains
 * @dev Called before initiating a rebase
 */
function requestShareVerification() external onlyOwner {
    // Create a new verification request
    uint256 requestId = ++verificationRequestCounter;
    
    // Reset verification status for all chains
    for (uint256 i = 0; i < chains.length; i++) {
        chainVerified[chains[i]] = false;
    }
    
    // Record verification request
    verificationRequests[requestId] = VerificationRequest({
        requestTime: block.timestamp,
        isActive: true,
        fulfilled: false,
        responseTime: 0
    });
    
    readyForRebase = false;
    
    // Send verification request to all chains
    for (uint256 i = 0; i < chains.length; i++) {
        uint32 chainId = chains[i];
        
        bytes memory message = abi.encode(requestId);
        
        // Send with high priority
        uint256 fee = IMailbox(MAILBOX).quoteDispatch(
            chainId,
            POOL,
            message,
            abi.encode(true), // High priority flag
            IPostDispatchHook(RELAYER)
        );
        
        IMailbox(MAILBOX).dispatch{value: fee}(
            chainId,
            POOL,
            message,
            abi.encode(true), // High priority flag
            IPostDispatchHook(RELAYER)
        );
    }
    
    emit VerificationRequested(requestId);
}

/**
 * @notice Recalculate total shares across all chains
 */
function _recalculateTotalShares() private {
    uint256 totalSharesAcrossChains = 0;
    for (uint256 i = 0; i < chains.length; i++) {
        totalSharesAcrossChains += chainShares[chains[i]];
    }
    
    // Update total shares state
    totalShares = totalSharesAcrossChains;
    
    // Emit event
    emit TotalSharesUpdated(totalShares);
}
```

#### 3. IEcoDollar Interface Update

```solidity
interface IEcoDollar {
    // Existing methods...
    
    /**
     * @notice Update the reward multiplier - privileged method accessible only to StablePool
     * @param _newMultiplier The new reward multiplier value
     */
    function updateRewardMultiplier(uint256 _newMultiplier) external;
    
    /**
     * @notice Get the current reward multiplier
     * @return The current reward multiplier value
     */
    function rewardMultiplier() external view returns (uint256);
    
    // Other methods...
}
```

#### 2. StablePool Rebase Initiation

```solidity
/**
 * @notice Broadcasts yield information to the home chain for rebase calculations
 * @param _tokens The current list of token addresses to include in calculation
 * @dev Only callable by owner, initiates the cross-chain rebase process
 * @dev Follows the exact steps in the swimlane diagram:
 *      1. Start (admin triggered)
 *      2. Pool earns funds from yield
 *      3. Save amount of profit
 *      4. Send message to home
 *      5. Set profit to 0 in storage
 */
function initiateRebase(
    address[] calldata _tokens
) external checkTokenList(_tokens) {
    // Only allowed to be called by a fixed address with authority to trigger rebases
    if (msg.sender != REBASE_AUTHORITY) {
        revert UnauthorizedRebaseInitiator(msg.sender, REBASE_AUTHORITY);
    }
    // Note: We allow concurrent rebases since they don't conflict
    // Each rebase resets profit to zero, and new rebases simply add new profit
    
    // Calculate local token balances (earned from yield)
    uint256 length = _tokens.length;
    uint256 localTokens = 0;
    
    for (uint256 i = 0; i < length; ++i) {
        // Safe to use unchecked for gas optimization as token balances are limited
        unchecked {
            localTokens += IERC20(_tokens[i]).balanceOf(address(this));
        }
    }
    
    // Get total shares from EcoDollar
    uint256 localShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
    
    // Get current accumulated profit value (tracked as a variable in StablePool)
    uint256 profit = accumulatedProfit;
    
    // Encode message with local metrics including profit
    // Use consistent encoding format for external service integration
    bytes memory message = abi.encode(
        localTokens,  // Total tokens across all supported assets
        localShares,  // Total shares from EcoDollar
        profit        // Accumulated profit since last rebase
    );
    
    // This message will be processed by the external cross-chain messaging service
    // The exact integration mechanism will be implemented by the service
    // For testing purposes, we use Hyperlane's mailbox interface
    
    // Quote fee for cross-chain message
    uint256 fee = IMailbox(MAILBOX).quoteDispatch(
        HOME_CHAIN,
        REBASER,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    // Dispatch message to home chain
    uint256 messageId = IMailbox(MAILBOX).dispatch{value: fee}(
        HOME_CHAIN,
        REBASER,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    // Critical: Set profit to 0 in storage to prevent double-counting
    accumulatedProfit = 0;
    
    // Emit event for tracking
    emit RebaseInitiated(localTokens, localShares, profit, HOME_CHAIN, messageId);
}
```

#### 2. Rebaser Constructor and protocolShareRate Management

```solidity
/**
 * @notice Initialize the Rebaser contract with required parameters
 * @param _mailbox Address of the Hyperlane mailbox
 * @param _chainIds Array of valid chain IDs
 * @param _treasury Address of the treasury to receive protocol share
 * @param _initialProtocolShareRate Initial rate for protocol share allocation (in BASE units)
 */
constructor(
    address _mailbox,
    uint32[] memory _chainIds,
    address _treasury,
    uint256 _initialProtocolShareRate
) Ownable(msg.sender) {
    MAILBOX = _mailbox;
    TREASURY_ADDRESS = _treasury;
    
    // Set initial protocol share rate (in BASE units, e.g., 0.2 * 1e18 for 20%)
    protocolShareRate = _initialProtocolShareRate;
    
    // Initialize chain management
    for (uint256 i = 0; i < _chainIds.length; i++) {
        chains.push(_chainIds[i]);
        validChainIDs[_chainIds[i]] = true;
    }
    
    emit ProtocolShareRateSet(_initialProtocolShareRate);
}

/**
 * @notice Update the protocol share rate
 * @param _newRate New protocol share rate (in BASE units)
 * @dev Only callable by contract owner
 */
function setProtocolShareRate(uint256 _newRate) external onlyOwner {
    require(_newRate <= BASE, "Rate cannot exceed 100%");
    uint256 oldRate = protocolShareRate;
    protocolShareRate = _newRate;
    emit ProtocolShareRateSet(_newRate);
}

#### 3. Rebaser Message Handling

/**
 * @dev Hyperlane message handler for processing rebase data from spoke chains
 * @param _origin The chain ID from which the message was sent
 * @param _sender The address that sent the message (32-byte form)
 * @param _message The encoded payload containing shares, balances and profit
 * @dev Follows the exact steps in the swimlane diagram:
 *      1. Calculate ratio of total supply and profit received
 *      2. Determine protocol share (fraction of profit allocated to protocol)
 *      3. Mint tokens representing protocol share to treasury
 *      4. Calculate new multiplier based on remaining profit
 *      5. Send updated multiplier to all spokes
 */
function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
) external payable override {
    // Security validations
    if (msg.sender != MAILBOX) {
        revert UnauthorizedMailbox(msg.sender, MAILBOX);
    }
    
    if (_sender != POOL) {
        revert UnauthorizedSender(_sender, POOL);
    }
    
    if (!validChainIDs[_origin]) {
        revert InvalidOriginChain(_origin);
    }
    
    // Decode message payload using the same encoding format as StablePool
    (uint256 balances, uint256 shares, uint256 profit) = abi.decode(
        _message,
        (uint256, uint256, uint256)
    );
    
    // Update chain data counters
    chainReports[_origin] = true;
    currentChainCount++;
    
    // Track shares for this specific chain and update total
    trackChainShares(_origin, shares);
    
    // Also update local variables for calculation
    sharesTotal = totalShares; // Use the global totalShares updated by trackChainShares
    balancesTotal += balances;
    profitTotal += profit;
    
    // Emit data receipt event
    emit ReceivedRebaseInformation(_origin, balances, shares, profit);
    
    // If all chains have reported, calculate and propagate rebase
    if (currentChainCount == chains.length) {
        // STEP 1: Calculate ratio of total supply and profit that was got
        // This calculates the net new balances (effectively the profit)
        uint256 netNewBalances = profitTotal;
        
        // Handle zero profit scenario
        if (netNewBalances <= 0) {
            _resetRebaseState();
            return;
        }
        
        // STEP 2: Increment global reward rate
        // Calculate new multiplier based on total balances and shares
        uint256 newMultiplier = ((balancesTotal) * BASE) / sharesTotal;
        
        // STEP 2: Determine protocol share (fraction of profit allocated to protocol)
        // protocolShareRate is set during construction and can be updated by the contract owner
        uint256 protocolShareAmount = (netNewBalances * protocolShareRate) / BASE;
        
        // STEP 3: Mint tokens representing protocol share to treasury
        if (protocolShareAmount > 0) {
            // TOKEN refers to local EcoDollar contract on home chain
            // TREASURY_ADDRESS is a predefined constant address for the treasury
            IEcoDollar(TOKEN).mint(TREASURY_ADDRESS, protocolShareAmount);
        }
        
        // STEP 4: Calculate new multiplier based on remaining profit
        newMultiplier = ((balancesTotal - protocolShareAmount) * BASE) / sharesTotal;
        
        // Update current multiplier
        currentMultiplier = newMultiplier;
        
        // Emit calculation event
        emit CalculatedRebase(
            balancesTotal,
            sharesTotal,
            netNewBalances,
            protocolShareAmount,
            newMultiplier
        );
        
        // STEP 4: Send to all spokes
        // Propagate rebase to all chains
        for (uint256 i = 0; i < chains.length; i++) {
            uint32 chain = chains[i];
            _propagateRebase(chain, newMultiplier);
        }
        
        // Reset state for next rebase cycle
        _resetRebaseState();
    }
}


/**
 * @dev Internal function to reset rebase state
 */
function _resetRebaseState() private {
    // Reset chain counters
    currentChainCount = 0;
    sharesTotal = 0;
    balancesTotal = 0;
    
    // Reset chain reports
    for (uint256 i = 0; i < chains.length; i++) {
        chainReports[chains[i]] = false;
    }
}

/**
 * @dev Internal function to propagate rebase to a specific chain
 * @param _chain The destination chain ID
 * @param _multiplier The new reward multiplier
 */
function _propagateRebase(
    uint32 _chain,
    uint256 _multiplier
) private {
    propagateRebase(_chain, _multiplier);
}

/**
 * @notice Propagates rebase data to a specified chain
 * @param _chain The destination chain ID
 * @param _multiplier The new reward multiplier
 */
function propagateRebase(
    uint32 _chain,
    uint256 _multiplier
) private {
    // Encode message with rebase data - consistent format for external service
    // Simple single value encoding for the new multiplier value
    bytes memory message = abi.encode(_multiplier);
    
    // This message will be processed by the external cross-chain messaging service
    // The exact integration mechanism will be implemented by the service
    // For testing purposes, we use Hyperlane's mailbox interface
    
    // Quote fee for cross-chain message
    uint256 fee = IMailbox(MAILBOX).quoteDispatch(
        _chain,
        POOL,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    // Dispatch message to destination chain
    uint256 messageId = IMailbox(MAILBOX).dispatch{value: fee}(
        _chain,
        POOL,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    // Log message ID for reference
}
```

#### 3. Direct Reward Multiplier Updates

The EcoDollar contract will no longer have a separate rebase method. Instead, the StablePool contract will directly update the reward multiplier during the handle method when receiving the hyperlane message from the home chain.

#### 4. StablePool Rebase Finalization

```solidity
/**
 * @notice Handles incoming rebase message from home chain
 * @param _origin The origin chain ID
 * @param _sender The sender address in 32-byte form
 * @param _message The message payload
 * @dev Follows the exact steps in the swimlane diagram:
 *      1. Receive the message from the home chain
 *      2. Sets the current multiplier
 *      3. End
 */
function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
) external payable override {
    // Security validations
    if (msg.sender != MAILBOX) {
        revert UnauthorizedMailbox(msg.sender, MAILBOX);
    }
    
    if (_sender != REBASER) {
        revert UnauthorizedSender(_sender, REBASER);
    }
    
    if (_origin != HOME_CHAIN) {
        revert InvalidOriginChain(_origin, HOME_CHAIN);
    }
    
    // Decode message payload using the same format as Rebaser's propagateRebase
    uint256 newMultiplier = abi.decode(
        _message,
        (uint256)
    );
    
    // STEP 1: Receive the message from home chain
    // This is handled by the Hyperlane protocol
    
    // STEP 2: Directly update the reward multiplier in EcoDollar
    // We'll directly access EcoDollar's state instead of using a separate rebase method
    uint256 oldMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
    
    // Direct access to update the multiplier through a privileged method in StablePool
    // that has access to update EcoDollar state
    _updateEcoDollarMultiplier(newMultiplier);
    
    // No need to reset rebase state as concurrent rebases are allowed
    
    // Emit rebase completion event
    emit RebaseFinalized(oldMultiplier, newMultiplier);
    
    // STEP 3: End process
    // No further action required, process is complete
}

/**
 * @dev Updates the reward multiplier in the EcoDollar contract
 * @param _newMultiplier The new multiplier value to set
 */
function _updateEcoDollarMultiplier(uint256 _newMultiplier) internal {
    // This function assumes StablePool has the authority to directly update
    // EcoDollar's reward multiplier through a privileged interface
    uint256 oldMultiplier = IEcoDollar(REBASE_TOKEN).rewardMultiplier();
    IEcoDollar(REBASE_TOKEN).updateRewardMultiplier(_newMultiplier);
    
    // Emit event with old and new values
    emit EcoDollarMultiplierUpdated(oldMultiplier, _newMultiplier);
}

```

#### 5. Fix Double Burn Issue in StablePool.withdraw

```solidity
/**
 * @notice Withdraw `_amount` of `_preferredToken` from the pool
 * @param _preferredToken The token to withdraw
 * @param _amount The amount to withdraw
 * @dev If pool balance is below threshold, user is added to the withdrawal queue
 */
function withdraw(address _preferredToken, uint80 _amount) external {
    // Verify token is whitelisted
    if (tokenThresholds[_preferredToken] == 0) {
        revert InvalidToken(_preferredToken);
    }
    
    // Check user's balance
    uint256 tokenBalance = IERC20(REBASE_TOKEN).balanceOf(msg.sender);
    if (tokenBalance < _amount) {
        revert InsufficientTokenBalance(
            _preferredToken,
            tokenBalance,
            _amount
        );
    }
    
    // Burn eUSD tokens - THIS OCCURS ONLY ONCE TO FIX DOUBLE BURN BUG
    IEcoDollar(REBASE_TOKEN).burn(msg.sender, _amount);
    
    // Check if withdrawal can be processed immediately
    uint256 poolTokenBalance = IERC20(_preferredToken).balanceOf(address(this));
    if (poolTokenBalance > tokenThresholds[_preferredToken] + _amount) {
        // Sufficient liquidity, process withdrawal immediately
        IERC20(_preferredToken).safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _preferredToken, _amount);
    } else {
        // Insufficient liquidity, add to withdrawal queue
        _addToWithdrawalQueue(_preferredToken, msg.sender, _amount);
    }
}
```

### Custom Error and Event Definitions

```solidity
// StablePool errors
error UnauthorizedMailbox(address actual, address expected);
error UnauthorizedSender(bytes32 actual, bytes32 expected);
error InvalidOriginChain(uint32 actual, uint32 expected);
error UnauthorizedRebaseInitiator(address actual, address expected);

// Rebaser errors
error InvalidOriginChain(uint32 chain);

// StablePool events
event RebaseInitiated(uint256 balances, uint256 shares, uint256 profit, uint32 homeChain, uint256 messageId);
event RebaseFinalized(uint256 oldMultiplier, uint256 newMultiplier);
event EcoDollarMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier);
event SharesUpdated(uint256 newTotalShares);
event SharesBatchUpdated(uint256 totalShares, int256 changeAmount, uint64 sequence);
event SharesVerified(uint256 requestId, uint256 exactShares);
event Deposited(address indexed user, address indexed token, uint256 amount);
event Withdrawn(address indexed user, address indexed token, uint256 amount);

// Rebaser events
event ReceivedRebaseInformation(uint32 origin, uint256 balances, uint256 shares, uint256 profit);
event CalculatedRebase(uint256 balancesTotal, uint256 sharesTotal, uint256 profitTotal, uint256 protocolShareAmount, uint256 newMultiplier);
event BatchSharesUpdated(uint32 originChain, uint256 totalShares, int256 changeAmount, uint64 sequence);
event OutdatedShareUpdate(uint32 originChain, uint64 receivedSequence, uint64 currentSequence);
event SignificantShareDrift(uint32 originChain, uint256 previousValue, uint256 verifiedValue, int256 drift);
event ShareVerificationProcessed(uint32 originChain, uint256 requestId, uint256 exactShares, bool isPreRebase);
event VerificationRequested(uint256 requestId);
event AllChainsVerified(uint256 totalVerifiedShares);
event ProtocolShareMinted(uint256 protocolShareAmount, address treasury);
event ProtocolShareRateSet(uint256 newRate);
event TotalSharesUpdated(uint256 totalShares);
```


### Message Encoding Standards

The following encoding formats are used consistently throughout the system for future service integration:

1. **StablePool to Rebaser** (batch share update):
   ```solidity
   abi.encode(BatchShareUpdate({
       totalShares: currentShares,
       changeSinceLastReport: changeAmount,
       sequenceNumber: sequence,
       timestamp: block.timestamp
   }))
   ```
   
2. **StablePool to Rebaser** (verification response):
   ```solidity
   abi.encode(ShareVerification({
       requestId: requestId,
       exactShares: currentShares,
       timestamp: block.timestamp,
       isPreRebase: true
   }))
   ```
   
3. **StablePool to Rebaser** (rebase initiation):
   ```solidity
   abi.encode(localTokens, localShares, profit)
   ```
   Where:
   - `localTokens`: Total value of tokens held by the pool
   - `localShares`: Total EcoDollar shares
   - `profit`: Accumulated profit since last rebase

4. **Rebaser to StablePool** (verification request):
   ```solidity
   abi.encode(requestId)
   ```
   Where:
   - `requestId`: Unique identifier for the verification request

5. **Rebaser to StablePool** (multiplier update):
   ```solidity
   abi.encode(newMultiplier)
   ```
   Where:
   - `newMultiplier`: New reward multiplier value to be applied

Note: External cross-chain message handling and service integration testing are out of scope for this implementation.

### Gas Optimization Techniques

1. **Message Encoding Optimization**: Minimize cross-chain message size by including only essential data

2. **Unchecked Math Operations**: Use unchecked blocks for arithmetic that cannot overflow

3. **Struct Packing**: Combine chains and validChainIDs as a struct with field packing

4. **Memory vs. Storage**: Optimize storage reads/writes by using memory variables

5. **Loop Optimization**: Optimize loops in token balance calculation

6. **Validation Ordering**: Order validations to fail fast and avoid unnecessary computation

## Testing Strategy

### Unit Testing Suite

1. **StablePool Tests**:
   - `testInitiateRebaseValidParams`: Verify function works with valid parameters
   - `testInitiateRebaseInvalidParams`: Verify function rejects invalid parameters
   - `testRebaseStateManagement`: Verify rebaseInProgress flag is properly managed
   - `testHandleValidMessage`: Verify handle function processes valid messages
   - `testHandleInvalidMessage`: Verify handle function rejects invalid messages
   - `testProtocolFeeCollection`: Verify fees are correctly collected
   - `testFixDoubleWithdrawBug`: Verify withdrawal only burns tokens once

2. **Rebaser Tests**:
   - `testHandleFunction`: Verify proper handling of incoming messages
   - `testPartialReports`: Test behavior when only some chains report
   - `testCalculationLogic`: Verify correct calculation of multipliers
   - `testPropagateRebase`: Verify rebase propagation
   - `testErrorHandling`: Verify proper handling of error conditions
   - `testProtocolFeeCalculation`: Verify protocol fee is calculated correctly

3. **EcoDollar Tests**:
   - `testDirectMultiplierUpdate`: Verify only StablePool can update the multiplier
   - `testShareToTokenConversion`: Verify correct conversion before and after multiplier changes
   - `testEventEmissions`: Verify proper events are emitted upon multiplier changes

### Unit Tests

1. **StablePool Profit Tracking**:
   ```typescript
   it("should track and reset profit correctly", async function() {
     // Deploy StablePool contract
     const stablePool = await deployStablePool();
     
     // Update accumulated profit (simulating yield generation)
     await updateAccumulatedProfit(stablePool, 1000);
     
     // Verify profit is tracked
     const profit = await stablePool.accumulatedProfit();
     expect(profit).to.equal(1000);
     
     // Trigger rebase
     await stablePool.initiateRebase(tokenList);
     
     // Verify profit is reset
     const newProfit = await stablePool.accumulatedProfit();
     expect(newProfit).to.equal(0);
   });
   ```

2. **Protocol Share Calculation**:
   ```typescript
   it("should calculate protocol share correctly", async function() {
     // Deploy Rebaser with initial protocol share rate
     const initialRate = ethers.utils.parseEther("0.2"); // 20%
     const rebaser = await deployRebaser(initialRate);
     
     // Set up test parameters
     const netNewBalances = 1000;
     const sharesTotal = 500;
     
     // Calculate expected protocol share
     const expectedShare = (netNewBalances * initialRate) / BASE;
     
     // Call calculateProtocolShare (test helper function)
     const protocolShare = await rebaser.calculateProtocolShare(netNewBalances);
     
     // Verify calculation
     expect(protocolShare).to.equal(expectedShare);
   });
   ```

3. **Message Format Consistency**:
   ```typescript
   it("should use consistent message formats", async function() {
     // Test encoding/decoding on StablePool side
     const encoded = await testEncodeProfitMessage(100, 200, 300);
     const decoded = await testDecodeProfitMessage(encoded);
     
     // Verify decoded values match original inputs
     expect(decoded.localTokens).to.equal(100);
     expect(decoded.localShares).to.equal(200);
     expect(decoded.profit).to.equal(300);
     
     // Test encoding/decoding on Rebaser side
     const multiplier = ethers.utils.parseEther("1.1");
     const encodedMultiplier = await testEncodeMultiplierMessage(multiplier);
     const decodedMultiplier = await testDecodeMultiplierMessage(encodedMultiplier);
     
     // Verify decoded multiplier matches original
     expect(decodedMultiplier).to.equal(multiplier);
   });
   ```

### Validation Commands

```bash
# Run specific rebase tests
forge test --match-contract RebaseFlow -vv

# Test specifically for double burn fix
forge test --match-test testFixDoubleWithdrawBug -vv

# Run all tests
forge test

# Check gas usage
forge snapshot

# Run security analysis
slither contracts/Rebaser.sol --detect reentrancy-eth,reentrancy-no-eth
slither contracts/StablePool.sol --detect divide-before-multiply,incorrect-equality
slither contracts/EcoDollar.sol --detect unchecked-lowlevel
```

## Implementation Steps

- [ ] Step 1: Set up advanced testing infrastructure [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 1.1: Create mock contracts with comprehensive functionality (mock Hyperlane mailbox, mock ERC20s)
  - [ ] Sub-task 1.2: Set up multi-chain testing framework using parallel anvil instances
  - [ ] Sub-task 1.3: Create helper functions for cross-chain test scenarios

- [ ] Step 2: Fix critical issues [Priority: Critical] [Est: 0.5h]
  - [x] Sub-task 2.1: Verify EcoDollar has updateRewardMultiplier method (found at line 79 in EcoDollar.sol)
  - [x] Sub-task 2.2: Verify we need to fix double burn in withdraw (found at lines 138-152 in StablePool.sol)
  - [x] Sub-task 2.3: Verify rebaseInProgress flag has been removed (confirmed in comments at line 66 in StablePool.sol)
  - [ ] Sub-task 2.4: Write tests verifying fixes
  - [ ] Sub-task 2.5: Run security analysis on fixed code

- [ ] Step 3: Implement batch share updates from StablePool [Priority: High] [Est: 3h]
  - [ ] Sub-task 3.1: Add accumulatedProfit variable to StablePool contract
  - [ ] Sub-task 3.2: Add lastReportedShares variable to track previous reported value
  - [ ] Sub-task 3.3: Add updateSequence counter for message sequencing
  - [ ] Sub-task 3.4: Add BatchShareUpdate struct definition
  - [ ] Sub-task 3.5: Add ShareVerification struct definition
  - [ ] Sub-task 3.6: Implement sendSharesUpdate function for periodic batch updates
  - [ ] Sub-task 3.7: Add SharesBatchUpdated event
  - [ ] Sub-task 3.8: Implement respondToShareVerification for pre-rebase verification
  - [ ] Sub-task 3.9: Update initiateRebase to include profit information
  - [ ] Sub-task 3.10: Standardize message encoding format (replace abi.encodePacked with abi.encode)
  - [ ] Sub-task 3.11: Ensure proper profit reset in storage (accumulatedProfit = 0)
  - [ ] Sub-task 3.12: Write tests for batch update and verification
  - [ ] Sub-task 3.13: Fix double burn in withdraw() function
  - [ ] Sub-task 3.14: Add proper deposit/withdraw event emissions with share updates

- [ ] Step 4: Implement robust Rebaser share tracking [Priority: High] [Est: 3h]
  - [ ] Sub-task 4.1: Add chainShares mapping to track shares by chain ID
  - [x] Sub-task 4.2: Validate that chains and validChainIDs are already defined (confirmed at lines 33-40 in Rebaser.sol)
  - [ ] Sub-task 4.3: Add sequence tracking (chainLastSequence) for each chain
  - [ ] Sub-task 4.4: Add timestamp tracking (chainLastUpdated, chainLastVerified)
  - [ ] Sub-task 4.5: Add VerificationRequest struct and tracking system
  - [ ] Sub-task 4.6: Add chainVerified mapping for tracking verification status
  - [ ] Sub-task 4.7: Add readyForRebase flag for pre-rebase coordination
  - [ ] Sub-task 4.8: Add BatchShareUpdate struct definition
  - [ ] Sub-task 4.9: Add ShareVerification struct definition
  - [ ] Sub-task 4.10: Implement handleBatchShareUpdate for batch updates
  - [ ] Sub-task 4.11: Implement handleShareVerification for verification messages
  - [ ] Sub-task 4.12: Implement requestShareVerification for pre-rebase coordination
  - [ ] Sub-task 4.13: Implement _recalculateTotalShares helper function
  - [ ] Sub-task 4.14: Update rebase calculation to use verified share values
  - [ ] Sub-task 4.15: Add drift detection and reporting mechanisms
  - [x] Sub-task 4.16: Verify constructor already accepts protocolRate parameter (confirmed at line 72 in Rebaser.sol)
  - [x] Sub-task 4.17: Verify owner-controlled changeprotocolRate function exists (found at line 109 in Rebaser.sol)
  - [ ] Sub-task 4.18: Implement protocol share allocation and minting to treasury
  - [ ] Sub-task 4.19: Update standardized message encoding (using abi.encode consistently)
  - [ ] Sub-task 4.20: Remove protocol token minting from propagateRebase

- [ ] Step 5: Refine EcoDollar's multiplier update mechanism [Priority: High] [Est: 1h]
  - [x] Sub-task 5.1: Verify updateRewardMultiplier method security (confirmed with onlyOwner at line 79 in EcoDollar.sol)
  - [x] Sub-task 5.2: Verify event emissions for multiplier changes (found at line 82 in EcoDollar.sol)
  - [x] Sub-task 5.3: Verify share-to-token conversion accuracy (confirmed at lines 60-71 in EcoDollar.sol)
  - [ ] Sub-task 5.4: Add minimum multiplier validation check (optional, may not be needed for rebases)

- [ ] Step 6: Complete StablePool rebase finalization [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 6.1: Write tests for StablePool's handle function with various scenarios
  - [x] Sub-task 6.2: Verify access control in handle function (confirmed at lines 311-317 in StablePool.sol)  
  - [ ] Sub-task 6.3: Update handle function to use standardized message format
  - [ ] Sub-task 6.4: Remove protocol token minting from handle function (lines 325-328 in StablePool.sol)
  - [ ] Sub-task 6.5: Add proper event emissions for multiplier updates
  - [ ] Sub-task 6.6: Ensure proper end-of-process handling

- [ ] Step 7: Build integration test suite [Priority: Critical] [Est: 1.5h]
  - [ ] Sub-task 7.1: Create unit tests for StablePool batch share updates
  - [ ] Sub-task 7.2: Create unit tests for Rebaser share tracking and verification
  - [ ] Sub-task 7.3: Test message format consistency across components
  - [ ] Sub-task 7.4: Verify correct profit tracking and reset
  - [ ] Sub-task 7.5: Verify protocol share minting on home chain only
  - [ ] Sub-task 7.6: Test batch share updates with various scenarios
  - [ ] Sub-task 7.7: Test pre-rebase verification with sequence numbering
  - [ ] Sub-task 7.8: Test double burn fix in withdraw function

- [ ] Step 8: Security and optimization [Priority: Critical] [Est: 1.5h]
  - [ ] Sub-task 8.1: Run comprehensive security analysis with Slither
  - [ ] Sub-task 8.2: Measure and optimize gas usage for batch updates
  - [ ] Sub-task 8.3: Verify access control for new batch update functions
  - [ ] Sub-task 8.4: Verify message sequence integrity protections
  - [ ] Sub-task 8.5: Complete NatSpec documentation for all new functions
  - [ ] Sub-task 8.6: Generate gas report and security analysis documentation

## Validation Checkpoints

### Implementation Validation Matrix

| Subtask | Compilation | Test Coverage | Security Checks | Gas Analysis | Documentation |
|---------|-------------|---------------|-----------------|--------------|---------------|
| 1.1-1.3 Test infrastructure | Must compile | Framework tested | N/A | N/A | Test strategy documented |
| 2.1-2.5 Validate and fix critical issues | Must compile | 100% coverage | Slither validation | Before/after comparison | Bug fix documented |
| 3.1-3.14 Batch share updates in StablePool | Must compile | 100% coverage | Access control verified | Gas snapshot | NatSpec complete |
| 4.1-4.20 Share tracking in Rebaser | Must compile | 100% coverage | Math safety verified | Gas optimization | NatSpec complete |
| 5.1-5.4 EcoDollar multiplier mechanism | Must compile | 100% coverage | Privilege checks verified | Gas analysis | NatSpec complete |
| 6.1-6.6 StablePool message handling | Must compile | 100% coverage | No protocol fee minting verified | Gas snapshot | NatSpec complete |
| 7.1-7.8 Integration testing | Must compile | E2E flow covered | Attack vectors tested | N/A | Test cases documented |
| 8.1-8.6 Security & optimization | Must compile | All tests pass | No critical findings | 10%+ gas reduction | Complete report |

### Quality Requirements

- **Code must follow all [Solidity Implementation Requirements](../CLAUDE.md#solidity-implementation-requirements)**
- **100% test coverage for all new and modified functions**
- **All new functions must have comprehensive NatSpec documentation**
- **All public/external functions must use custom errors instead of require strings**
- **All state changes must emit appropriate events**
- **All code must follow the checks-effects-interactions pattern**
- **All functions must implement proper access control**
- **All message encodings should use abi.encode consistently**
- **All cross-chain messages should include sequence numbering when appropriate**
- **All token transfers should be properly tested for reentrancy vulnerabilities**
- **All functions should include appropriate validation checks before state changes**

## Risk Assessment

### High-Risk Areas

1. **Protocol Share Calculation**
   - **Risk**: Incorrect calculation could lead to over/under-minting of protocol share tokens
   - **Current Implementation**: Rebaser has protocolRate (for protocol share) and calculates protocol share amount
   - **Mitigation**: Comprehensive testing with diverse scenarios, mathematical verification

2. **Share Tracking Accuracy**
   - **Risk**: Inaccurate share tracking could result in incorrect multiplier calculations
   - **Current Implementation**: Basic tracking without sequence numbers or verification
   - **Mitigation**: Add batch updates with sequence numbers and mandatory pre-rebase verification

3. **Double Burn in Withdraw Function**
   - **Risk**: Token shares are burned twice during withdrawal, leading to user fund loss
   - **Current Implementation**: Confirmed issue in withdraw function
   - **Mitigation**: Fix the withdraw function to only burn tokens once

Note: Cross-chain message handling will be handled by a separate service, so associated risks and service integration testing are out of scope for this implementation.

### Medium-Risk Areas

1. **Message Ordering and Sequence Integrity**
   - **Risk**: Out-of-order message processing could cause incorrect state updates
   - **Current Implementation**: No sequence numbering in messages
   - **Mitigation**: Add sequence numbers, timestamps, and tracking for all cross-chain messages

2. **Gas Optimization for Batch Updates**
   - **Risk**: Excessive gas costs for frequent share updates across chains
   - **Current Implementation**: Updates sent for every rebase without batching
   - **Mitigation**: Implement batch updates to reduce frequency of cross-chain messages

3. **Protocol Share Minting Location**
   - **Risk**: Protocol share minted on all chains instead of just the home chain
   - **Current Implementation**: StablePool mints protocol share tokens locally
   - **Mitigation**: Move protocol share minting exclusively to home chain Rebaser

4. **Chain Addition/Removal**
   - **Risk**: Adding/removing chains could disrupt share tracking
   - **Current Implementation**: Chains array and validChainIDs mapping exist but need enhancement
   - **Mitigation**: Ensure proper chain validation with verification in the enhanced implementation

## Rollback and Recovery Plan

If implementation fails or critical issues are discovered:

1. **For Critical Bugs**:
   - Immediately implement focused fix for specific issue
   - Run comprehensive tests to verify fix works
   - Deploy emergency update if already in production

2. **For Share Tracking Issues**:
   - Add administrative rescue function to reset or correct share tracking state
   - Implement verification fallback mechanism that can be triggered manually
   - Add diagnostic function to identify discrepancies between expected and actual shares

3. **For Message Format Compatibility**:
   - Include version indicator in message format to support both old and new formats
   - Add message format converter function during transition period
   - Maintain backward compatibility with current message processing

4. **For Rebaser Calculation Issues**:
   ```bash
   # Create debug branch for analysis
   git checkout -b debug/rebase-flow-issue-<issue-id>
   
   # Isolate issue
   git bisect start
   git bisect bad HEAD
   git bisect good <known-good-commit>
   
   # Once issue is found, fix on main branch
   git checkout feat/rebase/rebase-flow-implementation
   
   # Apply targeted fix
   git cherry-pick -x <fix-commit>
   ```

5. **For Cross-Chain Coordination Issues**:
   - Implement circuit breaker in home chain Rebaser
   - Add admin recovery function to reset stuck rebase state
   - Create diagnostic function to verify system consistency

## Progress Tracking

- [x] Plan created
- [x] Plan approved by user
- [x] Decisions confirmed (all Decision Points have exactly ONE selected option)
- [x] Current implementation analyzed and validated
- [ ] Implementation of batch share updates complete
- [ ] Implementation of share verification system complete
- [ ] Testing complete with 100% coverage
- [ ] Security analysis complete
- [ ] Final review complete

## Commit Message Template

```
<type>(<scope>): <concise description>

- Completed subtask X.Y: <subtask name>
- Test coverage: 100% (functions: X/X, lines: X/X, branches: X/X)
- Security: <key security checks performed>
- Gas optimization: <gas savings achieved>

🤖 Generated with [Claude Code](https://claude.ai/code)
```

---

# Current Analysis Summary

Based on a thorough review of the existing codebase, we've identified the following key points:

1. **EcoDollar Contract**:
   - The `updateRewardMultiplier` method already exists with proper access controls
   - Share-based accounting is correctly implemented with token-to-share conversion functions
   - Event emissions are properly implemented for multiplier updates

2. **StablePool Contract**:
   - The `rebaseInProgress` flag has already been removed as concurrent rebases are safe
   - The contract currently uses `abi.encodePacked` for message encoding, which should be changed to `abi.encode`
   - The current implementation mints protocol share tokens locally, which should be moved to home chain only
   - There is a potential double burn issue in the withdraw function that needs to be fixed
   - The contract needs additional state variables for batch share updates and verification

3. **Rebaser Contract**:
   - Already has chains array and validChainIDs mapping for chain tracking
   - Already has protocolRate for protocol share calculation
   - No sequence numbering or verification mechanism for share tracking
   - The message decoding assumes a specific format that will need to be updated
   - Contains a TODO comment to combine chain data as a struct

4. **Cross-Chain Messaging**:
   - Currently uses Hyperlane's IMailbox and IMessageRecipient interfaces
   - Message formats need to be standardized to use abi.encode consistently
   - No sequence numbering or verification system is currently implemented

The implementation plan has been updated to reflect these findings, with specific tasks to enhance the existing implementation with batch-based share updates, verification mechanisms, and other improvements.

> **IMPORTANT: Before moving to implementation:**
>
> 1. Confirm user approval for the plan
> 2. Ensure all Decision Points have exactly ONE selected option
> 3. Verify pre-execution checklist is complete
>
> **Key Commands to Run:**
>
> - After ANY code changes: `forge fmt`
> - After ANY contract modifications: `forge test`
> - For gas optimization verification: `forge snapshot`
> - For security analysis: `slither .`