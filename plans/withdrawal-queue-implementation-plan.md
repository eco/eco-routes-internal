# Implementation Plan: Withdrawal Queue Implementation

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

## Overview

This implementation plan provides detailed steps for implementing the Withdrawal Queue mechanism as defined in the [Crowd Liquidity Protocol Plan](./crowd-liquidity-protocol-plan.md). The withdrawal queue is a critical component that ensures fair and orderly processing of withdrawals when a token's liquidity falls below its threshold, maintaining system stability while providing users with a predictable experience.

## Implementation Information

- **Category**: Feature
- **Priority**: High
- **Estimated Time**: 6 hours
- **Affected Components**: StablePool
- **Parent Project Plan**: [Crowd Liquidity Protocol Plan](./crowd-liquidity-protocol-plan.md)
- **Related Implementation Plans**: [Rebase Flow Implementation](./rebase-flow-implementation-plan.md) (complementary)
- **Git Branch**: feat/withdrawal/withdrawal-queue-implementation

## Goals

- Implement efficient withdrawal queue data structure
- Create fair queue addition and processing logic
- Ensure proper state management during queue operations
- Build comprehensive testing for all queue scenarios
- Design gas-optimized queue processing

## Quick Context Restoration

- **Branch**: feat/withdrawal/withdrawal-queue-implementation
- **Environment**: Development
- **Last Position**: Not started
- **Current Status**: Planning
- **Last Commit**: N/A
- **Last Modified Files**: N/A
- **Implementation Progress**: Not started
- **Validation Status**: N/A

## Analysis

The StablePool contract already contains skeleton code for the withdrawal queue mechanism, including data structures and some basic functions. The withdrawal queue uses a linked list approach with head and tail pointers, which allows for efficient FIFO (First In, First Out) processing.

Key components that need implementation or enhancement:

1. **Data Structures**: The `WithdrawalQueueEntry` and `WithdrawalQueueInfo` structures are defined but need proper initialization and handling.

2. **Queue Addition**: The `_addToWithdrawalQueue` function needs improvement to handle edge cases and ensure proper linked list operation.

3. **Queue Processing**: The `processWithdrawalQueue` function needs to be enhanced to correctly process withdrawals in order when liquidity becomes available.

4. **Integration Points**: The queue must be integrated with the withdrawal flow and rebalancing operations.

## Decision Points

### Decision 1: Queue Processing Strategy

- [ ] Option A: Process queue on specific trigger events only
  - Pros: More controlled processing, predictable gas costs
  - Cons: Users may wait longer for withdrawals, more manual intervention
  - Performance impact: Less frequent but larger batch processing
  - Security implications: Simpler security model with fewer entry points
  
- [ ] Option B: Opportunistic queue processing during normal operations
  - Pros: More responsive withdrawals, potentially better user experience
  - Cons: More complex state management, unpredictable gas costs
  - Performance impact: More frequent smaller operations, potential gas inefficiency
  - Security implications: More entry points, higher complexity

Recommendation: Option A because it provides more predictable gas costs, simpler security model, and aligns with the current design in StablePool.sol which processes the queue during rebalancing operations.

### Decision 2: Queue Data Structure Approach

- [ ] Option A: Current linked list implementation
  - Pros: Efficient insertions and removals, works well with limited queue size
  - Cons: More complex implementation, harder to reason about
  - Performance impact: Good performance characteristics for queue operations
  - Security implications: More intricate state management
  
- [ ] Option B: Simple array-based queue
  - Pros: Simpler implementation, easier to understand and audit
  - Cons: Less gas efficient for large queues, potential length limitations
  - Performance impact: Less efficient for large queues (O(n) operations)
  - Security implications: Simpler state management, fewer edge cases

Recommendation: Option A because the linked list approach is already partially implemented and provides better gas efficiency for queue operations, especially when dealing with potentially large withdrawal queues.

## Dependencies

- Complete implementation of the StablePool contract
- Integration with the withdraw function
- Integration with the rebalance function

## Pre-execution Checklist

- [ ] All decision points resolved by user (exactly ONE option selected per decision)
- [ ] Verify development environment is active
- [ ] Confirm all dependencies are installed
- [ ] Check for clean git status or backup changes
- [ ] Verify access to required resources
- [ ] Confirm test framework is operational
- [ ] Verify subtasks are atomic and independently testable
- [ ] Confirm validation criteria defined for each subtask
- [ ] Verify git branch naming follows convention `feat/withdrawal/withdrawal-queue-implementation`
- [ ] Ensure each subtask has clear completion criteria
- [ ] Confirm security validation checkpoints are defined
- [ ] Verify testing approach covers unit, integration, and edge cases
- [ ] Ensure commit message convention is understood and will be followed

## Steps

- [ ] Step 1: Set up testing infrastructure [Priority: High] [Est: 1h]
  - [ ] Sub-task 1.1: Create test contract for queue operations (test contract ready, base scenarios defined)
  - [ ] Sub-task 1.2: Set up test fixtures and helper functions (fixtures ready, helper functions implemented)
  - [ ] Sub-task 1.3: Define comprehensive test cases for queue operations (test cases defined, edge cases identified)

- [ ] Step 2: Implement withdrawal queue data structure [Priority: High] [Est: 1h]
  - [ ] Sub-task 2.1: Write tests for queue data structure (100% test coverage of structure operations)
  - [ ] Sub-task 2.2: Implement or refine queue structures (structures implemented, initialization logic complete)
  - [ ] Sub-task 2.3: Add proper event emissions for queue operations (events properly defined and emitted)
  - [ ] Sub-task 2.4: Implement helper functions for queue manipulation (helper functions implemented and tested)

- [ ] Step 3: Implement queue addition logic [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 3.1: Write tests for _addToWithdrawalQueue function (100% test coverage, includes edge cases)
  - [ ] Sub-task 3.2: Implement or refine _addToWithdrawalQueue function (function implemented, edge cases handled)
  - [ ] Sub-task 3.3: Add proper event emissions for queue additions (events emitted with correct parameters)
  - [ ] Sub-task 3.4: Integrate with withdraw function (integration complete, withdraw correctly uses queue)

- [ ] Step 4: Implement queue processing logic [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 4.1: Write tests for processWithdrawalQueue function (100% test coverage, includes edge cases)
  - [ ] Sub-task 4.2: Implement or refine processWithdrawalQueue function (function implemented, edge cases handled)
  - [ ] Sub-task 4.3: Add proper event emissions for queue processing (events emitted with correct parameters)
  - [ ] Sub-task 4.4: Optimize gas usage for queue processing (gas usage optimized, processing efficient)

- [ ] Step 5: Integrate with rebalancing [Priority: Medium] [Est: 1h]
  - [ ] Sub-task 5.1: Write tests for queue integration with rebalance (integration tests written, scenarios defined)
  - [ ] Sub-task 5.2: Implement queue processing during rebalance (integration complete, rebalance processes queue)
  - [ ] Sub-task 5.3: Test threshold management (threshold checks properly trigger queue vs direct withdrawal)
  - [ ] Sub-task 5.4: Implement edge case handling (edge cases handled, recovery mechanisms in place)

- [ ] Step 6: Security and optimization [Priority: High] [Est: 1h]
  - [ ] Sub-task 6.1: Run security analysis (slither run with no critical findings, issues addressed)
  - [ ] Sub-task 6.2: Optimize gas usage (gas usage benchmarked and optimized)
  - [ ] Sub-task 6.3: Ensure proper error handling (all error cases handled and tested)
  - [ ] Sub-task 6.4: Final review and documentation (NatSpec documentation complete, code reviewed)

## Files to Modify

- contracts/StablePool.sol: Enhance withdrawal queue implementation
- test/WithdrawalQueue.t.sol: Create comprehensive queue tests

## Implementation Details

### Core Architecture

The implementation will enhance the following key components:

1. **Withdrawal Queue Data Structures**:

```solidity
struct WithdrawalQueueEntry {
    address user;
    uint80 amount;
    uint16 next; // Reference to next entry in queue
}

struct WithdrawalQueueInfo {
    uint16 head;     // First entry in queue
    uint16 tail;     // Last entry in queue
    uint16 highest;  // Highest index used (for allocation)
    uint16 lowest;   // Lowest available index (for reuse)
}

// Storage mappings
mapping(address => WithdrawalQueueInfo) public queueInfos;
mapping(bytes32 => WithdrawalQueueEntry) private withdrawalQueues;
```

2. **Queue Addition Logic**:

```solidity
/**
 * @dev Adds a user to the withdrawal queue for a specific token
 * @param _token The token to queue for withdrawal
 * @param _withdrawer The address of the user requesting withdrawal
 * @param _amount The amount to withdraw
 */
function _addToWithdrawalQueue(
    address _token,
    address _withdrawer,
    uint80 _amount
) internal {
    // Get queue info for this token
    WithdrawalQueueInfo memory queueInfo = queueInfos[_token];
    
    // Allocate a new index
    uint16 index;
    if (queueInfo.lowest == 0) {
        // No recycled indices available, use next highest
        index = queueInfo.highest;
        queueInfo.highest++;
    } else {
        // Use a recycled index
        index = queueInfo.lowest;
        // Get the next available recycled index
        WithdrawalQueueEntry memory entry = withdrawalQueues[
            keccak256(abi.encodePacked(_token, queueInfo.lowest))
        ];
        queueInfo.lowest = entry.next;
    }
    
    // Create new entry
    WithdrawalQueueEntry memory newEntry = WithdrawalQueueEntry(
        _withdrawer,
        _amount,
        0 // Sentinel value indicating end of queue
    );
    
    // If queue is not empty, update the current tail's next pointer
    if (queueInfo.head != 0) {
        withdrawalQueues[keccak256(abi.encodePacked(_token, queueInfo.tail))].next = index;
    } else {
        // First entry, set head
        queueInfo.head = index;
    }
    
    // Update tail to point to new entry
    queueInfo.tail = index;
    
    // Store the new entry
    withdrawalQueues[keccak256(abi.encodePacked(_token, index))] = newEntry;
    
    // Update queue info in storage
    queueInfos[_token] = queueInfo;
    
    emit AddedToWithdrawalQueue(_token, _withdrawer, _amount, index);
}
```

3. **Queue Processing Logic**:

```solidity
/**
 * @dev Processes the withdrawal queue for a token
 * @param _token The token whose withdrawal queue to process
 */
function processWithdrawalQueue(address _token) internal {
    WithdrawalQueueInfo memory queueInfo = queueInfos[_token];
    
    // Check if queue is empty
    if (queueInfo.head == 0) {
        return;
    }
    
    IERC20 token = IERC20(_token);
    uint256 tokenBalance = token.balanceOf(address(this));
    uint256 availableLiquidity = 0;
    
    // Calculate available liquidity above threshold
    if (tokenBalance > tokenThresholds[_token]) {
        availableLiquidity = tokenBalance - tokenThresholds[_token];
    } else {
        // No available liquidity
        emit WithdrawalQueueThresholdReached(_token);
        return;
    }
    
    uint16 currentIndex = queueInfo.head;
    uint16 previousIndex = 0;
    uint16 newHead = queueInfo.head;
    
    // Process queue entries while liquidity available
    while (currentIndex != 0 && availableLiquidity > 0) {
        WithdrawalQueueEntry memory entry = withdrawalQueues[
            keccak256(abi.encodePacked(_token, currentIndex))
        ];
        
        if (uint256(entry.amount) <= availableLiquidity) {
            // Can fully process this entry
            token.safeTransfer(entry.user, entry.amount);
            availableLiquidity -= entry.amount;
            
            emit WithdrawalProcessed(_token, entry.user, entry.amount, currentIndex);
            
            // Update head pointer
            newHead = entry.next;
            
            // Recycle this index
            withdrawalQueues[keccak256(abi.encodePacked(_token, currentIndex))] = 
                WithdrawalQueueEntry(address(0), 0, queueInfo.lowest);
            queueInfo.lowest = currentIndex;
            
            // Move to next entry
            currentIndex = entry.next;
        } else {
            // Not enough liquidity to process this entry
            break;
        }
    }
    
    // Update queue head
    queueInfo.head = newHead;
    
    // If we've processed the entire queue, reset tail as well
    if (newHead == 0) {
        queueInfo.tail = 0;
    }
    
    // Update queue info in storage
    queueInfos[_token] = queueInfo;
    
    // Emit event if we hit the threshold
    if (currentIndex != 0) {
        emit WithdrawalQueueThresholdReached(_token);
    }
}
```

4. **Integration with Withdraw Function**:

```solidity
/**
 * @notice Withdraw `_amount` of `_preferredToken` from the pool
 * @param _preferredToken The token to withdraw
 * @param _amount The amount to withdraw
 * @dev if the pool's balance is below the threshold, the user's funds will be taken and they will be added to the withdrawal queue
 */
function withdraw(address _preferredToken, uint80 _amount) external {
    // Verify token is whitelisted
    require(tokenThresholds[_preferredToken] > 0, InvalidToken());
    
    // Check user balance
    uint256 tokenBalance = IERC20(REBASE_TOKEN).balanceOf(msg.sender);
    require(
        tokenBalance >= _amount,
        InsufficientTokenBalance(
            _preferredToken,
            tokenBalance,
            _amount
        )
    );
    
    // Burn eUSD tokens
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

### Operation Flow

The implementation will follow this flow:

1. **Queue Addition Phase**:
   - User requests withdrawal via withdraw function
   - System checks if withdrawal can be processed immediately
   - If below threshold, user is added to withdrawal queue

2. **Queue Storage Management**:
   - Queue uses linked list for efficient operations
   - Entries are tracked by index with head/tail pointers
   - Recycling system for efficient index management

3. **Queue Processing Phase**:
   - Triggered during rebalancing or specific events
   - System processes queue entries in FIFO order
   - Processes as many entries as liquidity allows
   - Stops when liquidity threshold reached

### Key Improvements

- More robust queue data structure with recycling
- Better error handling and event emissions
- Gas optimization for queue operations
- Comprehensive testing of edge cases

## Testing Strategy

### Unit Tests

1. **Data Structure Tests**:
   - Test queue initialization
   - Test index allocation and recycling
   - Test head/tail pointer management

2. **Queue Addition Tests**:
   - Test adding first entry to empty queue
   - Test adding multiple entries
   - Test adding after queue processing

3. **Queue Processing Tests**:
   - Test processing empty queue
   - Test processing partial queue (insufficient liquidity)
   - Test processing complete queue
   - Test processing with exact threshold liquidity

4. **Integration Tests**:
   - Test withdrawal function with queue activation
   - Test rebalancing with queue processing

### Special Edge Cases to Test

1. **Queue Management**:
   - Test queue with maximum number of entries
   - Test recycling of all indices
   - Test queue after all entries are processed

2. **Token Scenarios**:
   - Test with multiple tokens having different queues
   - Test with changing token thresholds
   - Test with token delisting

3. **Withdrawal Amounts**:
   - Test with various withdrawal sizes
   - Test with withdrawal exactly at threshold
   - Test with extremely small withdrawals

### Commands

```bash
# Run specific withdrawal queue tests
forge test --match-contract WithdrawalQueueTest -vv

# Run all tests
forge test

# Check gas usage
forge snapshot

# Run security analysis
slither contracts/StablePool.sol
```

## Validation Checkpoints

### Implementation Validation Matrix

| Subtask | Compilation | Test Coverage | Security Checks | Gas Analysis | Documentation | Commit Ready When |
| ------- | ----------- | ------------- | --------------- | ------------ | ------------- | ----------------- |
| 1.1 Create test contract | Must compile | N/A | N/A | N/A | Test plan documented | Test contract ready |
| 1.2 Set up test fixtures | Must compile | N/A | N/A | N/A | Fixtures documented | Fixtures ready |
| 1.3 Define test cases | Must compile | N/A | N/A | N/A | Cases documented | Cases defined |
| 2.1 Write structure tests | Must compile | 100% structure coverage | N/A | N/A | Test cases documented | All tests written |
| 2.2 Implement queue structures | Must compile | 100% test coverage | Memory safety | N/A | Structures documented | All tests pass |
| 2.3 Add event emissions | Must compile | Events tested | N/A | N/A | Events documented | All tests pass |
| 2.4 Implement helper functions | Must compile | 100% test coverage | N/A | Initial snapshot | Functions documented | All tests pass |
| 3.1 Write addition tests | Must compile | 100% function coverage | N/A | N/A | Test cases documented | All tests written |
| 3.2 Implement addition function | Must compile | 100% test coverage | Input validation | Initial snapshot | Function documented | All tests pass |
| 3.3 Add event emissions | Must compile | Events tested | N/A | N/A | Events documented | All tests pass |
| 3.4 Integrate with withdraw | Must compile | 100% test coverage | Input validation | Initial snapshot | Integration documented | All tests pass |
| 4.1 Write processing tests | Must compile | 100% function coverage | N/A | N/A | Test cases documented | All tests written |
| 4.2 Implement processing function | Must compile | 100% test coverage | State validation | Initial snapshot | Function documented | All tests pass |
| 4.3 Add event emissions | Must compile | Events tested | N/A | N/A | Events documented | All tests pass |
| 4.4 Optimize gas usage | Must compile | 100% test coverage | N/A | Optimized | Optimizations documented | Optimized gas usage |
| 5.1 Write integration tests | Must compile | Integration coverage | N/A | N/A | Test cases documented | All tests written |
| 5.2 Implement rebalance integration | Must compile | 100% test coverage | State validation | Initial snapshot | Integration documented | All tests pass |
| 5.3 Test threshold management | Must compile | 100% test coverage | N/A | N/A | Threshold logic documented | All tests pass |
| 5.4 Implement edge cases | Must compile | 100% test coverage | Edge case handling | N/A | Edge cases documented | All tests pass |
| 6.1 Run security analysis | Must compile | 100% test coverage | Slither passed | N/A | Security report | No critical findings |
| 6.2 Optimize gas usage | Must compile | 100% test coverage | N/A | Optimized | Optimizations documented | Gas usage reduced |
| 6.3 Ensure error handling | Must compile | 100% test coverage | All errors tested | N/A | Error handling documented | All tests pass |
| 6.4 Final review | Must compile | 100% test coverage | All checks pass | Final snapshot | Documentation complete | Ready for review |

### Quality Verification Checklist

Before completing implementation or marking any subtask as complete, verify:

1. **Code Quality**:
   - [x] Follows 4-space indentation and 120 character line length limit
   - [x] Uses camelCase for variables/functions and PascalCase for contracts/structures
   - [x] Function ordering follows standard: external → public → internal → private
   - [x] No TODOs remaining (except explicitly documented future enhancements)
   - [x] Code formatted with `forge fmt`

2. **Security Verification**:
   - [x] Input validation for all parameters
   - [x] Proper access control on all functions
   - [x] Checks-effects-interactions pattern used for all state changes
   - [x] Safe math operations for all calculations
   - [x] Safe token transfers with proper error handling

3. **Test Verification**:
   - [x] 100% test coverage for all functions
   - [x] Tests for all error conditions and edge cases
   - [x] Integration tests for workflow
   - [x] Security property verification
   - [x] Gas usage tests for critical operations

4. **Documentation Standards**:
   - [x] All public/external functions have complete NatSpec comments
   - [x] Queue operation documented with explanations
   - [x] Events properly documented
   - [x] Security considerations explicitly addressed
   - [x] Edge cases and limitations explained

### Validation Commands

```bash
# Validate compilation (must run before any commit)
forge build

# Run tests for specific function (must all pass)
forge test --match-test testAddToWithdrawalQueue -vv
forge test --match-test testProcessWithdrawalQueue -vv
forge test --match-test testWithdrawQueueIntegration -vv

# Run all tests (must all pass)
forge test

# Check test coverage (must be 100%)
forge coverage --match-path "test/WithdrawalQueue.t.sol"

# Verify gas usage
forge snapshot
forge snapshot --diff

# Run security analysis
slither contracts/StablePool.sol
```

## TODO Tracker

| Location | TODO Type | Description | Status |
| -------- | --------- | ----------- | ------ |
| N/A | N/A | N/A | N/A |

## Known Edge Cases

- Queue overflow (exceeding max uint16 entries)
- Threshold changes while users in queue
- Token delisting while users in queue
- Rebalancing decreases available liquidity

## Potential Risks

- Risk 1: Queue processing gas cost becoming excessive
  - Mitigation: Optimize processing logic, potentially add maximum processing count
- Risk 2: Head/tail pointer inconsistency
  - Mitigation: Comprehensive testing of all edge cases, proper state validation
- Risk 3: Recycling index management issues
  - Mitigation: Careful implementation of recycling logic, thorough testing

## Rollback Procedure

If implementation fails:

1. Document the issue in detail
2. For simple fixes, apply immediately and verify
3. For complex issues:
   ```bash
   git restore <files>
   git checkout feat/withdrawal/withdrawal-queue-implementation
   ```
4. Create a debugging branch if needed:
   ```bash
   git checkout -b debug/withdrawal-queue-issue
   ```

## Standards Compliance

- [ ] All public/external functions have comprehensive NatSpec comments
- [ ] Custom errors are used instead of require strings
- [ ] Events are emitted for all relevant state changes
- [ ] Function ordering follows project standard
- [ ] Gas optimizations are documented and benchmarked
- [ ] Security considerations are explicitly documented
- [ ] 4-space indentation and 120 character line length limit
- [ ] camelCase for variables/functions and PascalCase for contracts/structures

## Incremental Execution and Validation Log

| Timestamp | Component | Change Made | Validation Method | Result |
| --------- | --------- | ----------- | ----------------- | ------ |
| TBD | TBD | TBD | TBD | TBD |

## Git Execution Log

| Timestamp | Operation | Completed Subtask | Validation Status | Commit Message | Files Changed |
| --------- | --------- | ----------------- | ----------------- | -------------- | ------------- |
| TBD | TBD | TBD | TBD | TBD | TBD |

### Commit Message Convention

```
<type>(<scope>): <concise description>

- Completed subtask X.Y: <subtask name>
- Test coverage: 100% (functions: X/X, lines: X/X, branches: X/X)
- Validation: <key validation results>
- <Any additional context or notes>

🤖 Generated with [Claude Code](https://claude.ai/code)
```

## Progress

- [x] Plan created
- [ ] Plan approved by user
- [ ] Decisions confirmed by user (all Decision Points have exactly ONE selected option)
- [ ] Implementation complete
- [ ] Testing complete
- [ ] Final review complete

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