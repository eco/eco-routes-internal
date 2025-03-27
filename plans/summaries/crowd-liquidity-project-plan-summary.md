# Crowd Liquidity Project - Technical Summary

## Overview

The Crowd Liquidity Project plan outlines the comprehensive strategy for implementing a cross-chain rebasing token and liquidity pool system. The system consists of StablePool contracts on multiple chains, a central Rebaser on the home chain, and EcoDollar tokens that receive yield through rebasing.

## Key Components

1. **StablePool**: Multi-token liquidity pool that accepts various stablecoins and implements a withdrawal queue for liquidity management.

2. **EcoDollar**: Share-based rebasing token that represents ownership in the protocol and receives yield through rebasing.

3. **Rebaser**: Central contract that collects yield information from all chains, calculates a global multiplier, and distributes it back to all chains.

4. **Cross-Chain Communication**: Hyperlane messaging system for cross-chain communication with potential fallback systems.

## Decision Points

### Decision 1: Rebase Timing Mechanism

| Option | Description | Pros | Cons | Status |
|--------|-------------|------|------|--------|
| ✓ **Option A: Scheduled Time-Based Rebases** | Rebases occur on a predefined schedule | Predictable schedule, simpler user experience, reduced gas costs from batched operations | May not respond quickly to market changes, requires external automation | **SELECTED** (2025-03-26) |
| **Option B: Event-Driven Rebases** | Rebases triggered by specific events or thresholds | More responsive to market conditions, no reliance on external scheduling | Less predictable for users, might trigger too frequently | Not selected |

**Rationale for Selection**: Option A provides predictability for users, reduces the risk of rebasing during high volatility periods, and allows for more efficient gas usage through batched operations.

### Decision 2: Withdrawal Queue Processing Strategy

| Option | Description | Pros | Cons | Status |
|--------|-------------|------|------|--------|
| **Option A: Process Queues During Regular Operations** | Process withdrawals opportunistically during normal operations | More responsive withdrawal processing, better user experience | More complex codebase, potential for partial queue processing | Not selected |
| ✓ **Option B: Process Queues Only During Rebalancing** | Process withdrawals only during scheduled rebalancing | Simpler code structure, guaranteed complete queue processing | Users may wait longer for withdrawals, more gas used in single operations | **SELECTED** (2025-03-26) |

**Rationale for Selection**: Option B provides a cleaner code structure, reduces the risk of partial queue processing, and aligns withdrawal processing with liquidity availability from rebalancing operations.

### Decision 3: Cross-Chain Communication Protocol

| Option | Description | Pros | Cons | Status |
|--------|-------------|------|------|--------|
| **Option A: Pure Hyperlane Integration** | Use only Hyperlane for cross-chain messaging | Simpler integration, lower complexity, well-established security | Single point of failure, limited by Hyperlane's chain support | Not selected |
| ✓ **Option B: Hybrid Messaging With Fallback Systems** | Use multiple messaging protocols with fallbacks | Higher resilience, optimization options, broader chain support | Much higher complexity, harder to reason about security | **SELECTED** (2025-03-26) |

**Rationale for Selection**: While Option B increases complexity, it was selected for its greater resilience and flexibility for cross-chain operations, especially important for a protocol that needs to operate reliably across multiple chains.

## Technical Requirements

### Functional Requirements

- **FR-01**: Users can deposit stablecoins for eUSD
- **FR-02**: Users can withdraw stablecoins by burning eUSD
- **FR-03**: System rebases eUSD across all chains
- **FR-04**: Protocol distributes yield to eUSD holders
- **FR-05**: Withdrawal queues handle liquidity shortfalls
- **FR-06**: Pools allow solvers to access liquidity for cross-chain intents
- **FR-07**: Protocol rebalances liquidity across chains
- **FR-08**: System collects various fees to sustain operations
- **FR-09**: Administrators can manage whitelisted tokens and thresholds
- **FR-10**: Protocol captures profit from stablecoins deposited in stable pool

### Non-Functional Requirements

- **NFR-01**: Cross-chain operations must be gas-efficient
- **NFR-02**: System must be secure against reentrancy attacks
- **NFR-03**: Contract access control must be properly enforced
- **NFR-04**: Protocol must handle message failures gracefully
- **NFR-05**: System must scale to support multiple chains
- **NFR-06**: Protocol fees must be configurable
- **NFR-07**: Withdrawal queues must be fair and efficient
- **NFR-08**: Rebase operations must complete within reasonable timeframe

### Security Requirements

- **SR-01**: Only verified cross-chain messages can trigger state changes
- **SR-02**: Only authorized solvers can access pool liquidity
- **SR-03**: Protocol funds must be protected from unauthorized withdrawal
- **SR-04**: Rebase calculations must be secure against manipulation
- **SR-05**: Contracts must be robust against precision and overflow issues
- **SR-06**: System must be upgradeable or have migration path

## Implementation Path

The implementation will proceed in the following order:

1. **Rebase Flow Implementation**: Implement cross-chain rebase mechanism
   - Handle profit collection, calculation, and distribution
   - Integrate with StablePool and EcoDollar contracts
   - Ensure proper protocol fee collection

2. **Withdrawal Queue Implementation**: Implement withdrawal queue for liquidity management
   - Implement queue data structure and operations
   - Integrate with withdrawal process
   - Ensure proper queue processing

3. **Liquidity Access Implementation**: Implement solver liquidity access (future plan)
   - Implement Lit signature verification
   - Enable authorized liquidity usage for cross-chain intents
   - Integrate with IntentSource/Inbox system

4. **Cross-Chain Rebalancing**: Implement liquidity rebalancing across chains (future plan)
   - Implement CCTP integration
   - Enable cross-chain liquidity movement
   - Optimize liquidity distribution

## Current Status

- Project plan created and approved
- Key decisions made on rebase timing, withdrawal queue processing, and cross-chain communication
- Ready for implementation of first component (Rebase Flow)

[View Full Project Plan](../full/crowd-liquidity-project-plan.md)