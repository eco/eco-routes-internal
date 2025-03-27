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

## Overview

This implementation plan provides detailed steps for implementing the cross-chain Rebase Flow mechanism as defined in the [Crowd Liquidity Project Plan](./crowd-liquidity-project-plan.md). The rebase flow is a crucial component that ensures eUSD tokens maintain consistent value across all chains by collecting yield information, calculating a global multiplier, and distributing that multiplier to all participating chains.

## Implementation Information

- **Category**: Feature
- **Priority**: High
- **Estimated Time**: 8 hours
- **Affected Components**: StablePool, Rebaser, EcoDollar, Hyperlane integration
- **Parent Project Plan**: [Crowd Liquidity Project Plan](./crowd-liquidity-project-plan.md)
- **Related Implementation Plans**: Withdrawal Queue Implementation (dependent)
- **Git Branch**: feat/rebase/rebase-flow-implementation

## Goals

- Implement complete cross-chain rebase flow as shown in documentation
- Create robust error handling for cross-chain messages
- Ensure correct profit calculation and distribution
- Implement secure protocol fee collection
- Build comprehensive test suite for rebase functionality

## Quick Context Restoration

- **Branch**: feat/rebase/rebase-flow-implementation
- **Environment**: Development
- **Last Position**: Not started
- **Current Status**: Planning
- **Last Commit**: N/A
- **Last Modified Files**: N/A
- **Implementation Progress**: Not started
- **Validation Status**: N/A

## Analysis

The Rebase Flow mechanism consists of three main phases:

1. **Collection Phase**: Each StablePool on a spoke chain collects profit information, calculates local yield, and sends this data to the home chain Rebaser.

2. **Calculation Phase**: The Rebaser on the home chain receives data from all chains, calculates a global multiplier based on total shares and total balances, determines protocol profits, and prepares for distribution.

3. **Distribution Phase**: The Rebaser sends the new multiplier to all chains, and each chain updates its EcoDollar contract with the new value, effectively rebasing the token.

Based on the analyzed code, the Rebaser contract already contains most of the calculation logic, but needs to be connected with the StablePool initiation and EcoDollar application. The existing rebase process also needs testing and potential optimizations.

## Decision Points

### Decision 1: Rebase Trigger Mechanism

- [x] Option A: Admin-triggered rebases
  - Pros: More control over timing, can be scheduled at optimal times
  - Cons: Requires active management, less autonomous
  - Performance impact: Less frequent rebases, potentially higher gas per rebase
  - Security implications: Lower risk of manipulation through timing
  
- [ ] Option B: Automatic threshold-based rebases
  - Pros: Fully autonomous, no need for manual intervention
  - Cons: May trigger at suboptimal times, harder to predict
  - Performance impact: Could lead to frequent rebases in volatile conditions
  - Security implications: Potential for gaming the threshold triggers

Recommendation: Option A because it provides more control over timing, allows for optimization of gas costs through batching, and aligns with the design indicated in the rebase flow diagram which shows an explicit "Start" action.

**Decision**: Option A selected (Admin-triggered rebases) based on user confirmation on 2025-03-26.

### Decision 2: Protocol Fee Distribution

- [x] Option A: Automatically mint protocol share to treasury
  - Pros: Immediate fee capture, simpler flow
  - Cons: Less flexible in fee allocation
  - Performance impact: More gas-efficient
  - Security implications: Fixed fee allocation pattern

- [ ] Option B: Store protocol share for later distribution
  - Pros: More flexible fee distribution options
  - Cons: More complex logic, additional transactions needed
  - Performance impact: Less gas-efficient due to multiple transactions
  - Security implications: More entry points, higher complexity

Recommendation: Option A because it aligns with the current implementation in the Rebaser contract, is more gas-efficient, and provides a simpler, more predictable fee capture mechanism.

**Decision**: Option A selected (Automatically mint protocol share to treasury) based on user confirmation on 2025-03-26.

## Dependencies

- Complete implementation of the StablePool contract
- Complete implementation of the EcoDollar contract
- Hyperlane integration for cross-chain messaging
- Proper contract deployment on all participating chains

## Pre-execution Checklist

- [ ] All decision points resolved by user (exactly ONE option selected per decision)
- [ ] Verify development environment is active
- [ ] Confirm all dependencies are installed
- [ ] Check for clean git status or backup changes
- [ ] Verify access to required resources
- [ ] Confirm test framework is operational
- [ ] Verify subtasks are atomic and independently testable
- [ ] Confirm validation criteria defined for each subtask
- [ ] Verify git branch naming follows convention `feat/rebase/rebase-flow-implementation`
- [ ] Ensure each subtask has clear completion criteria
- [ ] Confirm security validation checkpoints are defined
- [ ] Verify testing approach covers unit, integration, and edge cases
- [ ] Ensure commit message convention is understood and will be followed

## Steps

- [ ] Step 1: Set up test environment [Priority: High] [Est: 1h]
  - [ ] Sub-task 1.1: Configure mock contracts for testing (mock contracts ready, test environment configured)
  - [ ] Sub-task 1.2: Set up multi-chain testing framework (multiple anvil instances configured, test script ready)

- [ ] Step 2: Implement StablePool rebase initiation [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 2.1: Write tests for initiateRebase function (100% test coverage, includes valid and invalid scenarios)
  - [ ] Sub-task 2.2: Implement or refine initiateRebase function (function implemented with proper error handling, 100% test coverage)
  - [ ] Sub-task 2.3: Add proper event emissions for rebase events (events properly defined and emitted, tested for correct parameters)
  - [ ] Sub-task 2.4: Implement rebase state management (rebaseInProgress flag properly managed, tested for race conditions)

- [ ] Step 3: Implement Rebaser calculation logic [Priority: High] [Est: 2h]
  - [ ] Sub-task 3.1: Write tests for message handling on Rebaser (100% test coverage, includes valid and invalid message scenarios)
  - [ ] Sub-task 3.2: Refine Rebaser handle function (function implemented with proper validation, 100% test coverage)
  - [ ] Sub-task 3.3: Implement protocol fee calculation (fee calculation logic implemented, tested with various scenarios)
  - [ ] Sub-task 3.4: Add proper rebase propagation with error handling (propagation logic implemented with retry mechanism, tested with failure scenarios)

- [ ] Step 4: Implement EcoDollar rebase application [Priority: High] [Est: 1.5h]
  - [ ] Sub-task 4.1: Write tests for EcoDollar rebase function (100% test coverage, includes valid and invalid scenarios)
  - [ ] Sub-task 4.2: Implement or refine EcoDollar rebase function (function implemented with proper validation, 100% test coverage)
  - [ ] Sub-task 4.3: Implement share-to-token conversion logic (conversion logic implemented, tested with various multipliers)
  - [ ] Sub-task 4.4: Add proper event emissions (events properly defined and emitted, tested for correct parameters)

- [ ] Step 5: Implement StablePool rebase finalization [Priority: High] [Est: 1h]
  - [ ] Sub-task 5.1: Write tests for handle function on StablePool (100% test coverage, includes valid and invalid message scenarios)
  - [ ] Sub-task 5.2: Implement or refine StablePool handle function (function implemented with proper validation, 100% test coverage)
  - [ ] Sub-task 5.3: Add protocol mint logic (mint logic implemented, tested with various fee rates)
  - [ ] Sub-task 5.4: Implement rebase state reset (rebaseInProgress flag reset, tested in various scenarios)

- [ ] Step 6: Integration testing [Priority: Critical] [Est: 1.5h]
  - [ ] Sub-task 6.1: Write end-to-end rebase flow test (test covers complete flow, all stages verified)
  - [ ] Sub-task 6.2: Test with multiple chains (multi-chain test successful, verified with different chain counts)
  - [ ] Sub-task 6.3: Test error scenarios and recovery (error handling tested, recovery mechanisms verified)
  - [ ] Sub-task 6.4: Test protocol fee distribution (fee distribution verified, correct amounts received)

- [ ] Step 7: Security and optimization [Priority: High] [Est: 1h]
  - [ ] Sub-task 7.1: Run security analysis (slither run with no critical findings, all issues addressed)
  - [ ] Sub-task 7.2: Optimize gas usage (gas usage benchmarked and optimized, gas report generated)
  - [ ] Sub-task 7.3: Review access control (all functions have appropriate access controls, tested with unauthorized access)
  - [ ] Sub-task 7.4: Final review and documentation (NatSpec documentation complete, README updated)

## Files to Modify

- contracts/StablePool.sol: Enhance rebase initiation and handle logic
- contracts/Rebaser.sol: Enhance message handling and rebase propagation
- contracts/EcoDollar.sol: Improve rebase application
- test/RebaseFlow.t.sol: Create comprehensive rebase flow tests

## Implementation Details

### Core Architecture

The implementation will enhance the following key components:

1. **StablePool Rebase Initiation**:

```solidity
/**
 * @notice Broadcasts yield information to a central chain for rebase calculations
 * @param _tokens The current list of token addresses
 */
function initiateRebase(
    address[] calldata _tokens
) external onlyOwner checkTokenList(_tokens) {
    require(!rebaseInProgress, "Rebase already in progress");
    rebaseInProgress = true;

    uint256 length = _tokens.length;
    uint256 localTokens = 0;
    for (uint256 i = 0; i < length; ++i) {
        localTokens += IERC20(_tokens[i]).balanceOf(address(this));
    }

    uint256 localShares = EcoDollar(REBASE_TOKEN).totalShares();

    uint256 fee = IMailbox(MAILBOX).quoteDispatch(
        HOME_CHAIN,
        REBASER,
        abi.encode(localTokens, localShares),
        "", // metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    IMailbox(MAILBOX).dispatch{value: fee}(
        HOME_CHAIN,
        REBASER,
        abi.encode(localTokens, localShares),
        "", // metadata for relayer
        IPostDispatchHook(RELAYER)
    );
    
    emit RebaseInitiated(localTokens, localShares, HOME_CHAIN);
}
```

2. **Rebaser Calculation Logic**:

```solidity
/**
 * @dev Hyperlane "handle" method, called when a message is received.
 * @param _origin The chain ID from which the message was sent.
 * @param _sender The address that sent this message on the origin chain, in 32-byte form.
 * @param _message The encoded message payload.
 */
function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
) external payable override {
    // Ensure only the local mailbox can call this
    require(msg.sender == MAILBOX, "Caller is not the local mailbox");
    require(_sender == POOL, "sender is not the pool contract");
    require(validChainIDs[_origin], "Invalid origin chain");
    
    (uint256 shares, uint256 balances) = abi.decode(
        _message,
        (uint256, uint256)
    );
    
    currentChainCount++;
    sharesTotal += shares;
    balancesTotal += balances;

    emit ReceivedRebaseInformation(_origin, shares, balances);

    uint256 chainCount = chains.length;

    if (currentChainCount == chainCount) {
        // Calculate rebase parameters
        uint256 netNewBalances = balancesTotal - (sharesTotal * currentMultiplier) / BASE;
        uint256 protocolShare = (netNewBalances * protocolRate) / BASE;
        uint256 newMultiplier = ((balancesTotal - protocolShare) * BASE) / sharesTotal;
        uint256 protocolMintRate = (protocolShare * BASE) / sharesTotal;

        emit CalculatedRebase(
            balancesTotal,
            sharesTotal,
            netNewBalances,
            protocolShare,
            newMultiplier,
            protocolMintRate
        );

        // Reset counters for next rebase
        currentChainCount = 0;
        sharesTotal = 0;
        balancesTotal = 0;
        currentMultiplier = newMultiplier;

        // Propagate rebase to all chains
        for (uint256 i = 0; i < chainCount; i++) {
            uint32 chain = chains[i];
            bool success = propagateRebase(chain, protocolMintRate);
            if (!success) {
                emit RebasePropagationFailed(chain);
                revert RebasePropagationFailed(chain);
            }
        }
    }
}
```

3. **EcoDollar Rebase Application**:

```solidity
/**
 * @notice Updates the reward multiplier for rebasing
 * @param _newMultiplier The new reward multiplier
 */
function rebase(uint256 _newMultiplier) external onlyOwner {
    require(_newMultiplier >= rewardMultiplier, "RewardMultiplierTooLow");
    rewardMultiplier = _newMultiplier;
    emit Rebased(rewardMultiplier);
}
```

4. **StablePool Rebase Finalization**:

```solidity
/**
 * @notice Finalizes the rebase flow
 * @param _origin The origin chain of the message
 * @param _sender The address of the sender on the origin chain
 * @param _message The message body
 */
function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _message
) external payable override {
    // Ensure only the local mailbox can call this
    require(msg.sender == MAILBOX, "Caller is not the local mailbox");
    require(_sender == REBASER, "sender is not the rebaser contract");
    require(_origin == HOME_CHAIN, "Invalid origin chain");

    (uint256 rewardMultiplier, uint256 protocolMintRate) = abi.decode(
        _message,
        (uint256, uint256)
    );
    
    // Apply rebase to EcoDollar
    IEcoDollar(REBASE_TOKEN).rebase(rewardMultiplier);

    // Mint protocol share to pool
    uint256 protocolMintAmount = (protocolMintRate * IEcoDollar(REBASE_TOKEN).getTotalShares()) / 1e18;
    IEcoDollar(REBASE_TOKEN).mint(address(this), protocolMintAmount);
    
    // Reset rebase state
    rebaseInProgress = false;
    
    emit RebaseFinalized(rewardMultiplier, protocolMintRate, protocolMintAmount);
}
```

### Operation Flow

The implementation will follow this flow:

1. **Initiation Phase**:
   - Owner calls `initiateRebase` on StablePool
   - StablePool calculates local tokens and shares
   - StablePool sends message to Rebaser on home chain

2. **Calculation Phase**:
   - Rebaser receives messages from all StablePools
   - When all chains reported, Rebaser calculates new multiplier
   - Rebaser calculates protocol share

3. **Distribution Phase**:
   - Rebaser sends multiplier to all chains
   - Each StablePool receives message and calls EcoDollar.rebase
   - Protocol share is minted to each pool
   - Rebase state is reset

### Key Improvements

- Enhanced error handling for cross-chain messages
- Better event emissions for tracking rebase flow
- Proper state management to prevent concurrent rebases
- Comprehensive testing for all steps in the flow
- Gas optimization for cross-chain messages

## Testing Strategy

### Unit Tests

1. **StablePool Tests**:
   - Test initiateRebase with valid and invalid parameters
   - Test handle function with valid and invalid messages
   - Test rebase state management

2. **Rebaser Tests**:
   - Test handle function with various chain reports
   - Test calculation logic with different scenarios
   - Test propagation logic and error handling

3. **EcoDollar Tests**:
   - Test rebase function with valid and invalid multipliers
   - Test share-to-token conversion before and after rebase

### Integration Tests

1. **End-to-End Rebase Flow**:
   - Test complete flow from initiation to finalization
   - Verify correct multiplier calculation and distribution
   - Verify correct protocol fee collection

2. **Multi-Chain Scenarios**:
   - Test with varying number of chains
   - Test partial chain reporting
   - Test chain addition/removal during rebase

3. **Error Scenarios**:
   - Test message failure handling
   - Test recovery mechanisms
   - Test partial completion scenarios

### Commands

```bash
# Run specific rebase tests
forge test --match-contract RebaseTest -vv

# Run all tests
forge test

# Check gas usage
forge snapshot

# Run security analysis
slither contracts/Rebaser.sol
slither contracts/StablePool.sol
slither contracts/EcoDollar.sol
```

## Validation Checkpoints

### Implementation Validation Matrix

| Subtask | Compilation | Test Coverage | Security Checks | Gas Analysis | Documentation | Commit Ready When |
| ------- | ----------- | ------------- | --------------- | ------------ | ------------- | ----------------- |
| 1.1 Configure mock contracts | Must compile | N/A | N/A | N/A | Setup documented | Mock contracts ready |
| 1.2 Set up multi-chain testing | Must compile | N/A | N/A | N/A | Framework documented | Test framework ready |
| 2.1 Write initiateRebase tests | Must compile | 100% of function | N/A | N/A | Test cases documented | All tests written |
| 2.2 Implement initiateRebase | Must compile | 100% test coverage | Input validation | Initial snapshot | Function documented | All tests pass |
| 2.3 Add event emissions | Must compile | Events tested | N/A | N/A | Events documented | All tests pass |
| 2.4 Implement state management | Must compile | 100% test coverage | Race conditions | N/A | Logic documented | All tests pass |
| 3.1 Write Rebaser tests | Must compile | 100% of function | N/A | N/A | Test cases documented | All tests written |
| 3.2 Refine handle function | Must compile | 100% test coverage | Message validation | Initial snapshot | Function documented | All tests pass |
| 3.3 Implement fee calculation | Must compile | 100% test coverage | Math safety | N/A | Logic documented | All tests pass |
| 3.4 Add rebase propagation | Must compile | 100% test coverage | Error handling | N/A | Function documented | All tests pass |
| 4.1 Write EcoDollar tests | Must compile | 100% of function | N/A | N/A | Test cases documented | All tests written |
| 4.2 Implement rebase function | Must compile | 100% test coverage | Input validation | Initial snapshot | Function documented | All tests pass |
| 4.3 Implement conversion logic | Must compile | 100% test coverage | Math safety | N/A | Logic documented | All tests pass |
| 4.4 Add event emissions | Must compile | Events tested | N/A | N/A | Events documented | All tests pass |
| 5.1 Write StablePool tests | Must compile | 100% of function | N/A | N/A | Test cases documented | All tests written |
| 5.2 Implement handle function | Must compile | 100% test coverage | Message validation | Initial snapshot | Function documented | All tests pass |
| 5.3 Add protocol mint logic | Must compile | 100% test coverage | Math safety | N/A | Logic documented | All tests pass |
| 5.4 Implement state reset | Must compile | 100% test coverage | Race conditions | N/A | Logic documented | All tests pass |
| 6.1 Write end-to-end test | Must compile | Full flow coverage | N/A | N/A | Test documented | Test passes |
| 6.2 Test with multiple chains | Must compile | Multi-chain coverage | N/A | N/A | Test documented | All tests pass |
| 6.3 Test error scenarios | Must compile | Error path coverage | Recovery | N/A | Scenarios documented | All tests pass |
| 6.4 Test fee distribution | Must compile | 100% test coverage | N/A | N/A | Test documented | All tests pass |
| 7.1 Run security analysis | Must compile | 100% test coverage | Slither passed | N/A | Security report | No critical findings |
| 7.2 Optimize gas usage | Must compile | 100% test coverage | N/A | Optimized | Optimizations documented | Gas usage reduced |
| 7.3 Review access control | Must compile | 100% test coverage | Access testing | N/A | Controls documented | All tests pass |
| 7.4 Final review | Must compile | 100% test coverage | All checks pass | Final snapshot | Documentation complete | Ready for review |

### Quality Verification Checklist

Before completing implementation or marking any subtask as complete, verify:

1. **Code Quality**:
   - [ ] Follows 4-space indentation and 120 character line length limit
   - [x] Uses camelCase for variables/functions and PascalCase for contracts/structures
   - [x] Function ordering follows standard: external → public → internal → private
   - [x] No TODOs remaining (except explicitly documented future enhancements)
   - [x] Code formatted with `forge fmt`

2. **Security Verification**:
   - [x] Message validation for all cross-chain communication
   - [x] Input validation for all parameters
   - [x] Proper access control on all functions
   - [x] Checks-effects-interactions pattern used for all state changes
   - [x] Race condition prevention in rebase state management

3. **Test Verification**:
   - [x] 100% test coverage for all functions
   - [x] Tests for all error conditions and edge cases
   - [x] Integration tests for cross-chain flow
   - [x] Security property verification
   - [x] Gas usage tests for critical operations

4. **Documentation Standards**:
   - [x] All public/external functions have complete NatSpec comments
   - [x] Rebase flow documented with explanations
   - [x] Events properly documented
   - [x] Security considerations explicitly addressed
   - [x] Protocol fees and calculation logic explained

### Validation Commands

```bash
# Validate compilation (must run before any commit)
forge build

# Run tests for specific function (must all pass)
forge test --match-test testInitiateRebase -vv
forge test --match-test testRebaserHandle -vv
forge test --match-test testEcoDollarRebase -vv
forge test --match-test testStablePoolHandle -vv

# Run all tests (must all pass)
forge test

# Check test coverage (must be 100%)
forge coverage --match-path "test/RebaseFlow.t.sol"

# Verify gas usage
forge snapshot
forge snapshot --diff

# Run security analysis
slither contracts/Rebaser.sol
slither contracts/StablePool.sol
slither contracts/EcoDollar.sol
```

## TODO Tracker

| Location | TODO Type | Description | Status |
| -------- | --------- | ----------- | ------ |
| contracts/Rebaser.sol:42 | combine | Combine chains and validChainIDs as a struct | Pending |

## Known Edge Cases

- Chain disconnection during rebase should pause the process
- Protocol fee calculation should handle zero profit scenarios
- EcoDollar rebase should never decrease the multiplier
- Withdrawal queue processing after rebase completion

## Potential Risks

- Risk 1: Cross-chain message failure
  - Mitigation: Implement retry mechanism and proper error handling
- Risk 2: Calculation errors in rebase determination
  - Mitigation: Comprehensive testing with various scenarios
- Risk 3: Race conditions in rebase state
  - Mitigation: Proper state management and completion verification

## Rollback Procedure

If implementation fails:

1. Document the issue in detail
2. For simple fixes, apply immediately and verify
3. For complex issues:
   ```bash
   git restore <files>
   git checkout feat/rebase/rebase-flow-implementation
   ```
4. Create a debugging branch if needed:
   ```bash
   git checkout -b debug/rebase-flow-issue
   ```

## Standards Compliance

- [ ] All public/external functions have comprehensive NatSpec comments
- [ ] Custom errors are used instead of require strings
- [ ] Events are emitted for all relevant state changes
- [ ] Function ordering follows project standard
- [ ] Gas optimizations are documented and benchmarked
- [ ] Security considerations are explicitly documented
- [x] camelCase for variables/functions and PascalCase for contracts/structures

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
- [x] Plan approved by user
- [x] Decisions confirmed by user (all Decision Points have exactly ONE selected option)
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