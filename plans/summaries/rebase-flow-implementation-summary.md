# Rebase Flow Implementation - Technical Summary

## Overview

The Rebase Flow Implementation plan outlines the technical approach for implementing a cross-chain rebasing mechanism that ensures eUSD tokens maintain consistent value across all supported chains. The mechanism works by collecting yield information from each chain, calculating a global multiplier on the home chain, and distributing this multiplier to all participating chains.

## Key Components

1. **StablePool Rebase Initiation**: Initiates the rebase process by collecting local token balances and shares, then sending this information to the home chain.

2. **Rebaser Calculation Logic**: Receives reports from all chains, calculates global multiplier based on total shares and balances, determines protocol profits, and prepares for distribution.

3. **EcoDollar Rebase Application**: Receives the new multiplier and updates the share-to-token conversion rate, effectively rebasing the token.

4. **StablePool Rebase Finalization**: Completes the rebase process by applying the new rate and minting protocol shares.

## Decision Points

### Decision 1: Rebase Trigger Mechanism

| Option | Description | Pros | Cons | Status |
|--------|-------------|------|------|--------|
| ✓ **Option A: Admin-triggered rebases** | Rebases initiated by admin action | More control over timing, can be scheduled at optimal times | Requires active management, less autonomous | **SELECTED** (2025-03-26) |
| **Option B: Automatic threshold-based rebases** | Rebases triggered when certain threshold conditions are met | Fully autonomous, no need for manual intervention | May trigger at suboptimal times, harder to predict | Not selected |

**Rationale for Selection**: Option A provides more control over timing, allows for optimization of gas costs through batching, and aligns with the design indicated in the rebase flow diagram which shows an explicit "Start" action.

### Decision 2: Protocol Fee Distribution

| Option | Description | Pros | Cons | Status |
|--------|-------------|------|------|--------|
| ✓ **Option A: Automatically mint protocol share to treasury** | Protocol fees are immediately minted to the treasury | Immediate fee capture, simpler flow, more gas-efficient | Less flexible in fee allocation | **SELECTED** (2025-03-26) |
| **Option B: Store protocol share for later distribution** | Protocol fees are accumulated and distributed later | More flexible fee distribution options | More complex logic, additional transactions needed, less gas-efficient | Not selected |

**Rationale for Selection**: Option A aligns with the current implementation in the Rebaser contract, is more gas-efficient, and provides a simpler, more predictable fee capture mechanism.

## Implementation Steps

1. **Set up test environment** (Est: 1h)
   - Configure mock contracts for testing
   - Set up multi-chain testing framework

2. **Implement StablePool rebase initiation** (Est: 1.5h)
   - Write tests for initiateRebase function
   - Implement/refine initiateRebase function
   - Add proper event emissions
   - Implement rebase state management

3. **Implement Rebaser calculation logic** (Est: 2h)
   - Write tests for message handling
   - Refine handle function
   - Implement protocol fee calculation
   - Add proper rebase propagation with error handling

4. **Implement EcoDollar rebase application** (Est: 1.5h)
   - Write tests for rebase function
   - Implement/refine rebase function
   - Implement share-to-token conversion logic
   - Add proper event emissions

5. **Implement StablePool rebase finalization** (Est: 1h)
   - Write tests for handle function
   - Implement/refine handle function
   - Add protocol mint logic
   - Implement rebase state reset

6. **Integration testing** (Est: 1.5h)
   - Write end-to-end rebase flow test
   - Test with multiple chains
   - Test error scenarios and recovery
   - Test protocol fee distribution

7. **Security and optimization** (Est: 1h)
   - Run security analysis
   - Optimize gas usage
   - Review access control
   - Final review and documentation

## Technical Considerations

### Security Considerations
- Ensure proper validation of cross-chain messages
- Verify sender addresses in all handle functions
- Implement reentrancy protection for all state-changing functions
- Ensure proper access control on administrative functions

### Performance Considerations
- Optimize gas usage in cross-chain messages
- Batch operations where possible
- Minimize state changes during high-frequency operations

### Integration Points
- StablePool → Rebaser: Cross-chain message with shares and tokens
- Rebaser → StablePool: Cross-chain message with new multiplier and protocol mint rate
- StablePool → EcoDollar: Function call to update rebase multiplier

## Dependencies

- Complete implementation of the StablePool contract
- Complete implementation of the EcoDollar contract
- Hyperlane integration for cross-chain messaging
- Proper contract deployment on all participating chains

## Current Status

- Plan created and approved
- Decisions confirmed by user
- Implementation not yet begun
- Branch: feat/rebase/rebase-flow-implementation

[View Full Implementation Plan](../rebase-flow-implementation-plan.md)