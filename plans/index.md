# Eco Routes Protocol - Implementation Plans

This document serves as an index of all implementation plans for the Eco Routes Protocol. It provides quick access to all plans, their current status, and other key information.

## Active Plans

| Plan | Description | Status | Last Updated | Branch |
|------|-------------|--------|-------------|--------|
| [Crowd Liquidity Protocol](./crowd-liquidity-project-plan.md) | Master plan for cross-chain rebasing token and liquidity pool system | Approved | 2025-03-26 | N/A |
| [Rebase Flow Implementation](./rebase-flow-implementation-plan.md) | Implementation of cross-chain rebase mechanism | Active | 2025-03-26 | feat/rebase/rebase-flow-implementation |
| [Withdrawal Queue Implementation](./withdrawal-queue-implementation-plan.md) | Implementation of withdrawal queue for liquidity management | Draft | 2025-03-26 | feat/withdrawal/withdrawal-queue-implementation |

## Completed Plans

No completed plans yet.

## Plan Templates

| Template | Description | Purpose |
|----------|-------------|---------|
| [Example Project Plan](./example-project-plan.md) | Template for project-level plans | Creating new project-wide plans |
| [Example Implementation Plan](./example-implementation-plan.md) | Template for specific implementation plans | Creating component implementation plans |

## Implementation Path

The implementation of the Crowd Liquidity Project will proceed in the following order:

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

## Decision History

| Date | Plan | Decision Point | Selected Option | Reasoning |
|------|------|----------------|-----------------|-----------|
| 2025-03-26 | Crowd Liquidity Project | Rebase Timing Mechanism | Scheduled Time-Based Rebases | Better control over timing and gas optimization |
| 2025-03-26 | Crowd Liquidity Project | Withdrawal Queue Processing Strategy | Process Queues Only During Rebalancing | Cleaner code structure, more reliable processing |
| 2025-03-26 | Crowd Liquidity Project | Cross-Chain Communication Protocol | Hybrid Messaging With Fallback Systems | Higher resilience and flexibility |
| 2025-03-26 | Rebase Flow Implementation | Rebase Trigger Mechanism | Admin-triggered rebases | Better control over timing and gas optimization |
| 2025-03-26 | Rebase Flow Implementation | Protocol Fee Distribution | Auto-mint to treasury | Simpler flow, more gas-efficient |

## Task Progress Overview

| Task | Status | Progress | Next Action |
|------|--------|----------|-------------|
| Project Planning | Complete | 100% | N/A |
| Rebase Flow | In Progress | 0% | Begin implementation |
| Withdrawal Queue | Not Started | 0% | Implement after Rebase Flow |
| Liquidity Access | Not Started | 0% | Create implementation plan |
| Cross-Chain Rebalancing | Not Started | 0% | Create implementation plan |

---

Last updated: 2025-03-26