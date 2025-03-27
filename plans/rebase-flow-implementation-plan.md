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
- **Related Implementation Plans**: Withdrawal Queue Implementation (dependent)
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
2. Fix critical bugs in existing implementation (double burn, missing validation)
3. Add robust error handling for cross-chain messages
4. Ensure mathematically correct profit calculation and distribution
5. Implement secure protocol fee collection with proper treasury distribution
6. Build comprehensive test suite covering the entire rebase flow

### Out of Scope

1. Changes to the fundamental architecture of the system
2. Implementation of withdrawal queue processing (separate plan)
3. Changes to deployment strategy
4. UI integration or external system interactions

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

The rebase flow follows a clearly defined process with distinct responsibilities at each level:

#### 1. Spoke Chain (Collection Phase)
- Process starts with admin trigger ("Start" in diagram)
- Pool collects balances from each listed token
- Total amount of profit is calculated
- Message sent to home chain with local metrics

#### 2. Hyperlane (Messaging Layer)
- Handles cross-chain message delivery
- Connects spoke chains to home chain
- Provides bidirectional messaging capabilities

#### 3. Home Chain (Calculation Phase)
- Calculates ratio of total supply and profit that was got
- Determines global reward rate
- Deducts protocol fees
- Mints shares to fee recipients
- Sends updated rates to all spoke chains

#### 4. Service Layer
- Monitors number of rebases
- Tracks balances of accepted tokens

### Critical Issues Requiring Fixes

1. **Double Burn in Withdraw Function**: StablePool.withdraw() burns user tokens twice (lines 150 and 159), causing users to lose twice the intended amount.

2. **Missing Validation in EcoDollar.rebase()**: No check to ensure new multiplier is >= current multiplier.

3. **Incomplete Error Handling**: Cross-chain message failures need proper handling.

4. **Incomplete State Management**: rebaseInProgress flag not properly reset if process fails.

5. **Withdrawal Queue Integration**: Rebase needs to trigger withdrawal queue processing.

## Implementation Details

### Files to Modify

- **contracts/StablePool.sol**
  - Fix double burn bug in withdraw function
  - Enhance rebase initiation logic
  - Implement handle function for receiving rebase data
  - Add rebase state management
  - Add event emissions

- **contracts/Rebaser.sol**
  - Enhance message handling with better validation
  - Optimize protocol fee calculation
  - Improve rebase propagation with error handling
  - Add proper event emissions
  - Combine chains and validChainIDs as a struct

- **contracts/EcoDollar.sol**
  - Enhance rebase function with proper validation
  - Ensure share-to-token conversion is accurate
  - Add event emissions

- **test/RebaseFlow.t.sol** (new file)
  - Implement comprehensive test suite for rebase flow

### Core Architecture Enhancements

#### 1. StablePool Rebase Initiation

```solidity
/**
 * @notice Broadcasts yield information to the home chain for rebase calculations
 * @param _tokens The current list of token addresses to include in calculation
 * @dev Only callable by owner, initiates the cross-chain rebase process
 */
function initiateRebase(
    address[] calldata _tokens
) external onlyOwner checkTokenList(_tokens) {
    // Prevent concurrent rebases
    if (rebaseInProgress) {
        revert RebaseInProgress();
    }
    
    // Mark rebase as in progress
    rebaseInProgress = true;
    
    // Calculate local token balances for yield determination
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
    
    // Encode message with local metrics
    bytes memory message = abi.encode(localTokens, localShares);
    
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
    
    // Emit event for offchain monitoring
    emit RebaseInitiated(localTokens, localShares, HOME_CHAIN, messageId);
}
```

#### 2. Rebaser Calculation Logic

```solidity
/**
 * @dev Hyperlane message handler for processing rebase data from spoke chains
 * @param _origin The chain ID from which the message was sent
 * @param _sender The address that sent the message (32-byte form)
 * @param _message The encoded payload containing shares and balances
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
    
    // Decode message payload
    (uint256 balances, uint256 shares) = abi.decode(
        _message,
        (uint256, uint256)
    );
    
    // Update chain data counters
    chainReports[_origin] = true;
    currentChainCount++;
    sharesTotal += shares;
    balancesTotal += balances;
    
    // Emit data receipt event
    emit ReceivedRebaseInformation(_origin, balances, shares);
    
    // If all chains have reported, calculate and propagate rebase
    if (currentChainCount == chains.length) {
        // Calculate rebase metrics with SafeMath
        uint256 netNewBalances = balancesTotal - (sharesTotal * currentMultiplier) / BASE;
        
        // Handle zero or negative profit scenario
        if (netNewBalances <= 0) {
            emit ZeroProfitRebase(balancesTotal, sharesTotal, currentMultiplier);
            _resetRebaseState();
            return;
        }
        
        // Calculate protocol's share of profit
        uint256 protocolShare = (netNewBalances * protocolRate) / BASE;
        
        // Calculate new multiplier and protocol mint rate
        uint256 newMultiplier = ((balancesTotal - protocolShare) * BASE) / sharesTotal;
        uint256 protocolMintRate = (protocolShare * BASE) / sharesTotal;
        
        // Ensure multiplier only increases
        if (newMultiplier <= currentMultiplier) {
            emit InvalidMultiplierCalculated(currentMultiplier, newMultiplier);
            _resetRebaseState();
            return;
        }
        
        // Update current multiplier
        currentMultiplier = newMultiplier;
        
        // Emit calculation event
        emit CalculatedRebase(
            balancesTotal,
            sharesTotal,
            netNewBalances,
            protocolShare,
            newMultiplier,
            protocolMintRate
        );
        
        // Propagate rebase to all chains
        bool allSucceeded = true;
        for (uint256 i = 0; i < chains.length; i++) {
            uint32 chain = chains[i];
            bool success = _propagateRebase(chain, newMultiplier, protocolMintRate);
            
            if (!success) {
                allSucceeded = false;
                emit RebasePropagationFailed(chain);
            }
        }
        
        // Reset state for next rebase cycle
        _resetRebaseState();
        
        // If any propagation failed, emit event but don't revert
        // This allows the rebase to partially succeed
        if (!allSucceeded) {
            emit PartialRebaseCompletion();
        }
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
 * @param _protocolMintRate The protocol mint rate for fee distribution
 * @return success Whether the propagation was successful
 */
function _propagateRebase(
    uint32 _chain,
    uint256 _multiplier,
    uint256 _protocolMintRate
) private returns (bool success) {
    try this.propagateRebase(_chain, _multiplier, _protocolMintRate) returns (bool result) {
        return result;
    } catch {
        return false;
    }
}

/**
 * @notice Propagates rebase data to a specified chain
 * @param _chain The destination chain ID
 * @param _multiplier The new reward multiplier
 * @param _protocolMintRate The protocol mint rate for fee distribution
 * @return success Whether the propagation was successful
 */
function propagateRebase(
    uint32 _chain,
    uint256 _multiplier,
    uint256 _protocolMintRate
) external returns (bool success) {
    // Only allow internal calls from this contract
    if (msg.sender != address(this)) {
        revert UnauthorizedCaller(msg.sender, address(this));
    }
    
    // Encode message with rebase data
    bytes memory message = abi.encode(_multiplier, _protocolMintRate);
    
    // Quote fee for cross-chain message
    uint256 fee = IMailbox(MAILBOX).quoteDispatch(
        _chain,
        POOL,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    // Check if contract has enough ETH for fee
    if (address(this).balance < fee) {
        emit InsufficientFeeForRebase(_chain, fee, address(this).balance);
        return false;
    }
    
    // Dispatch message to destination chain
    try IMailbox(MAILBOX).dispatch{value: fee}(
        _chain,
        POOL,
        message,
        "", // Empty metadata for relayer
        IPostDispatchHook(RELAYER)
    ) returns (uint256 messageId) {
        emit RebasePropagated(_chain, _multiplier, _protocolMintRate, messageId);
        return true;
    } catch (bytes memory reason) {
        emit RebasePropagationError(_chain, reason);
        return false;
    }
}
```

#### 3. EcoDollar Rebase Function Enhancement

```solidity
/**
 * @notice Updates the reward multiplier for rebasing the token
 * @param _newMultiplier The new reward multiplier to apply
 * @dev Only callable by owner (StablePool), ensures multiplier only increases
 */
function rebase(uint256 _newMultiplier) external onlyOwner {
    // Ensure multiplier only increases
    if (_newMultiplier < rewardMultiplier) {
        revert RewardMultiplierTooLow(_newMultiplier, rewardMultiplier);
    }
    
    // Update reward multiplier
    uint256 oldMultiplier = rewardMultiplier;
    rewardMultiplier = _newMultiplier;
    
    // Emit rebase event with old and new multipliers
    emit Rebased(oldMultiplier, rewardMultiplier);
}
```

#### 4. StablePool Rebase Finalization

```solidity
/**
 * @notice Handles incoming rebase message from home chain
 * @param _origin The origin chain ID
 * @param _sender The sender address in 32-byte form
 * @param _message The message payload
 * @dev Finalizes rebase by updating EcoDollar multiplier and minting protocol fees
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
    
    // Decode message payload
    (uint256 newMultiplier, uint256 protocolMintRate) = abi.decode(
        _message,
        (uint256, uint256)
    );
    
    // Apply rebase to EcoDollar token
    try IEcoDollar(REBASE_TOKEN).rebase(newMultiplier) {
        // Calculate and mint protocol share
        uint256 totalShares = IEcoDollar(REBASE_TOKEN).getTotalShares();
        uint256 protocolMintAmount = (protocolMintRate * totalShares) / BASE;
        
        if (protocolMintAmount > 0) {
            IEcoDollar(REBASE_TOKEN).mint(TREASURY_ADDRESS, protocolMintAmount);
        }
        
        // Process withdrawal queues if applicable
        _processWithdrawalQueues();
        
        // Reset rebase state
        rebaseInProgress = false;
        
        // Emit rebase completion event
        emit RebaseFinalized(newMultiplier, protocolMintRate, protocolMintAmount);
    } catch (bytes memory reason) {
        // Handle rebase failure
        rebaseInProgress = false;
        emit RebaseApplicationFailed(reason);
    }
}

/**
 * @dev Internal function to process withdrawal queues after rebase
 */
function _processWithdrawalQueues() internal {
    // Process withdrawal queue for each whitelisted token
    for (uint256 i = 0; i < whitelistedTokens.length; i++) {
        address token = whitelistedTokens[i];
        uint256 balance = IERC20(token).balanceOf(address(this));
        
        // Check if token is above threshold
        if (balance > tokenThresholds[token]) {
            // Process withdrawal queue for this token
            processWithdrawalQueue(token);
        }
    }
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

### Custom Error Definitions

```solidity
// StablePool errors
error RebaseInProgress();
error UnauthorizedMailbox(address actual, address expected);
error UnauthorizedSender(bytes32 actual, bytes32 expected);
error InvalidOriginChain(uint32 actual, uint32 expected);
error RebaseApplicationFailed(bytes reason);

// Rebaser errors
error UnauthorizedCaller(address actual, address expected);
error InvalidOriginChain(uint32 chain);
error InsufficientFeeForRebase(uint32 chain, uint256 required, uint256 available);
error RebasePropagationError(uint32 chain, bytes reason);
error PartialRebaseCompletion();

// EcoDollar errors
error RewardMultiplierTooLow(uint256 provided, uint256 minimum);
```

### Gas Optimization Techniques

1. **Message Encoding Optimization**: Reduce cross-chain message size by using compact encoding

2. **Unchecked Math Operations**: Use unchecked blocks for arithmetic that cannot overflow

3. **Struct Packing**: Combine chains and validChainIDs as a struct with field packing

4. **Memory vs. Storage**: Optimize storage reads/writes by using memory variables

5. **Loop Optimization**: Optimize loops in token balance calculation and queue processing

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
   - `testRebaseValidMultiplier`: Verify rebase function accepts valid multipliers
   - `testRebaseInvalidMultiplier`: Verify rebase function rejects decreasing multipliers
   - `testShareToTokenConversion`: Verify correct conversion before and after rebase
   - `testEventEmissions`: Verify proper events are emitted

### Integration Tests

1. **Complete Rebase Flow**:
   ```typescript
   it("should complete full rebase flow across chains", async function() {
     // Set up test environment with multiple anvil instances
     const [homeChain, spokeChain1, spokeChain2] = await setupMultiChainTest();
     
     // Deploy contracts on each chain
     const contracts = await deployContracts(homeChain, [spokeChain1, spokeChain2]);
     
     // Seed pools with initial liquidity
     await seedPoolLiquidity(contracts);
     
     // Initiate rebase on spoke chains
     await initiateRebaseOnSpokeChains(contracts);
     
     // Wait for Hyperlane messages to be delivered
     await waitForMessageDelivery();
     
     // Verify calculation on home chain
     const rebaseCalc = await verifyRebaseCalculation(contracts.homeChain);
     
     // Verify distribution to spoke chains
     await verifyDistributionToSpokeChains(contracts, rebaseCalc);
     
     // Verify final state after rebase
     await verifyFinalState(contracts);
   });
   ```

2. **Error Scenarios**:
   ```typescript
   it("should handle chain disconnection gracefully", async function() {
     // Set up test environment with multiple anvil instances
     const [homeChain, spokeChain1, spokeChain2] = await setupMultiChainTest();
     
     // Deploy contracts on each chain
     const contracts = await deployContracts(homeChain, [spokeChain1, spokeChain2]);
     
     // Seed pools with initial liquidity
     await seedPoolLiquidity(contracts);
     
     // Initiate rebase on spoke1 but not spoke2 (simulating disconnection)
     await initiateRebaseOnSpokeChain(contracts.spokeChain1);
     
     // Wait for partial message delivery
     await waitForMessageDelivery();
     
     // Verify homeChain doesn't calculate rebase with partial data
     await verifyNoRebaseCalculation(contracts.homeChain);
     
     // Verify spoke chains maintain consistent state
     await verifyConsistentState(contracts);
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

- [ ] Step 2: Fix critical bugs [Priority: Critical] [Est: 1h]
  - [ ] Sub-task 2.1: Fix double burn bug in StablePool.withdraw
  - [ ] Sub-task 2.2: Add proper validation to EcoDollar.rebase
  - [ ] Sub-task 2.3: Write tests verifying bug fixes
  - [ ] Sub-task 2.4: Run security analysis on fixed code

- [ ] Step 3: Enhance StablePool rebase initiation [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 3.1: Write tests for initiateRebase function with comprehensive scenarios
  - [ ] Sub-task 3.2: Implement enhanced initiateRebase with proper state management
  - [ ] Sub-task 3.3: Add custom errors and event emissions
  - [ ] Sub-task 3.4: Optimize gas usage in token balance calculation

- [ ] Step 4: Improve Rebaser calculation logic [Priority: High] [Est: 2h]
  - [ ] Sub-task 4.1: Write tests for Rebaser's handle function with diverse scenarios
  - [ ] Sub-task 4.2: Enhance handle function with robust validation and cleaner flow
  - [ ] Sub-task 4.3: Implement safe protocol fee calculation with edge case handling
  - [ ] Sub-task 4.4: Add proper error handling for propagation failures
  - [ ] Sub-task 4.5: Refactor chains and validChainIDs into efficient struct

- [ ] Step 5: Upgrade EcoDollar rebasing [Priority: High] [Est: 1h]
  - [ ] Sub-task 5.1: Write comprehensive tests for EcoDollar rebase function
  - [ ] Sub-task 5.2: Enhance rebase function with validation and error handling
  - [ ] Sub-task 5.3: Verify share-to-token conversion accuracy before/after rebase
  - [ ] Sub-task 5.4: Add improved event emissions with old/new multiplier values

- [ ] Step 6: Complete StablePool rebase finalization [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 6.1: Write tests for StablePool's handle function with various scenarios
  - [ ] Sub-task 6.2: Implement enhanced handle function with proper validation
  - [ ] Sub-task 6.3: Add treasury mint logic with gas optimizations
  - [ ] Sub-task 6.4: Integrate withdrawal queue processing after rebase
  - [ ] Sub-task 6.5: Implement proper rebase state reset with error handling

- [ ] Step 7: Build integration test suite [Priority: Critical] [Est: 2h]
  - [ ] Sub-task 7.1: Create end-to-end test for complete rebase flow
  - [ ] Sub-task 7.2: Implement multi-chain testing with parallel anvil instances
  - [ ] Sub-task 7.3: Add tests for error conditions (chain disconnection, message failure)
  - [ ] Sub-task 7.4: Verify protocol fee distribution across treasury accounts
  - [ ] Sub-task 7.5: Test interaction with withdrawal queue processing

- [ ] Step 8: Security and optimization [Priority: Critical] [Est: 1.5h]
  - [ ] Sub-task 8.1: Run comprehensive security analysis with Slither
  - [ ] Sub-task 8.2: Measure and optimize gas usage for cross-chain operations
  - [ ] Sub-task 8.3: Verify access control across all components
  - [ ] Sub-task 8.4: Complete NatSpec documentation for all functions
  - [ ] Sub-task 8.5: Generate gas report and security analysis documentation

## Validation Checkpoints

### Implementation Validation Matrix

| Subtask | Compilation | Test Coverage | Security Checks | Gas Analysis | Documentation |
|---------|-------------|---------------|-----------------|--------------|---------------|
| 1.1-1.3 Test infrastructure | Must compile | Framework tested | N/A | N/A | Test strategy documented |
| 2.1-2.4 Fix critical bugs | Must compile | 100% coverage | Slither validation | Before/after comparison | Bug fix documented |
| 3.1-3.4 StablePool rebase | Must compile | 100% coverage | Access control verified | Gas snapshot | NatSpec complete |
| 4.1-4.5 Rebaser calculation | Must compile | 100% coverage | Math safety verified | Gas optimization | NatSpec complete |
| 5.1-5.4 EcoDollar rebasing | Must compile | 100% coverage | Edge cases tested | Gas analysis | NatSpec complete |
| 6.1-6.5 Rebase finalization | Must compile | 100% coverage | Error handling verified | Gas snapshot | NatSpec complete |
| 7.1-7.5 Integration testing | Must compile | E2E flow covered | Attack vectors tested | N/A | Test cases documented |
| 8.1-8.5 Security & optimization | Must compile | All tests pass | No critical findings | 10%+ gas reduction | Complete report |

### Quality Requirements

- **Code must follow all [Solidity Implementation Requirements](../CLAUDE.md#solidity-implementation-requirements)**
- **100% test coverage for all modified functions**
- **All functions must have comprehensive NatSpec documentation**
- **All public/external functions must use custom errors instead of require strings**
- **All state changes must emit appropriate events**
- **All code must follow the checks-effects-interactions pattern**
- **All functions must implement proper access control**

## Risk Assessment

### High-Risk Areas

1. **Cross-Chain Message Failures**
   - **Risk**: Message delivery failure could leave system in inconsistent state
   - **Mitigation**: Implement robust error handling, state reset mechanism, event logging

2. **Protocol Fee Calculation**
   - **Risk**: Incorrect calculation could lead to over/under-minting of protocol fees
   - **Mitigation**: Comprehensive testing with diverse scenarios, mathematical verification

3. **Double Burn Bug**
   - **Risk**: Users lose twice the intended amount in withdrawals
   - **Mitigation**: Fix bug, add comprehensive tests, validate with formal verification

4. **Rebase State Management**
   - **Risk**: Improper state management could block future rebases
   - **Mitigation**: Ensure state is reset properly even on errors, add admin recovery function

### Medium-Risk Areas

1. **Gas Optimization**
   - **Risk**: Inefficient code could make cross-chain operations too expensive
   - **Mitigation**: Gas benchmarking, optimization of hot paths, minimize storage operations

2. **Withdrawal Queue Integration**
   - **Risk**: Improper integration could lead to stuck withdrawals
   - **Mitigation**: Test integration thoroughly, ensure proper queue processing

3. **Chain Addition/Removal**
   - **Risk**: Adding/removing chains could disrupt rebase flow
   - **Mitigation**: Test chain management operations, ensure proper validation

## Rollback and Recovery Plan

If implementation fails or critical issues are discovered:

1. **For Critical Bugs**:
   - Immediately implement focused fix for specific issue
   - Run comprehensive tests to verify fix works
   - Deploy emergency update if already in production

2. **For Complex Implementation Issues**:
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

3. **For Cross-Chain Coordination Issues**:
   - Implement circuit breaker in home chain Rebaser
   - Add admin recovery function to reset stuck rebase state
   - Create diagnostic function to verify system consistency

## Progress Tracking

- [x] Plan created
- [x] Plan approved by user
- [x] Decisions confirmed (all Decision Points have exactly ONE selected option)
- [ ] Implementation complete
- [ ] Testing complete
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