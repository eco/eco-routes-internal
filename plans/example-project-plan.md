# Project Plan: [Project Name]

> **This is a template for creating comprehensive project plans that can generate multiple implementation plans.**

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

## CLAUDE EXECUTION DIRECTIVES

### Comprehensive Work Cycle Protocol

1. **CONTEXT GATHERING IMPERATIVE**

   - YOU MUST PROACTIVELY GATHER complete context through systematic stakeholder questioning
   - YOU SHALL IDENTIFY all implicit ambiguities in requirements and resolve them immediately
   - YOU ARE REQUIRED TO document all assumptions and constraints with explicit user confirmation
   - YOU MUST USE web search (mcp**brave-search**brave_web_search), web fetching (mcp**fetch**fetch), and ALL AVAILABLE MCP tools to conduct exhaustive research
   - YOU SHALL EXHAUST all research avenues using GitHub tools (mcp**github**\*) for code examples and industry standards
   - YOU MUST CONDUCT comprehensive technical research before proceeding to design
   - NEVER proceed with incomplete understanding of requirements or technical context

2. **SOLUTION DESIGN MANDATE**

   - YOU SHALL RESEARCH all relevant technologies, patterns, and approaches using web search, web fetching, and GitHub exploration tools
   - YOU MUST LEVERAGE mcp**brave-search**brave_web_search for current best practices and industry standards
   - YOU SHALL USE mcp**github**search_repositories and mcp**github**search_code to find relevant implementation examples
   - YOU ARE REQUIRED TO present research findings in concise, actionable summary format with specific citations
   - YOU MUST create detailed architectural diagrams with component relationships
   - YOU SHALL IDENTIFY all decision points with comprehensive pros/cons analysis addressing performance, security, maintenance, and complexity
   - YOU MUST COLLABORATIVELY iterate on design until all specifications are precisely defined
   - NEVER proceed without complete, approved design specification with component interfaces

3. **IMPLEMENTATION PLANNING IMPERATIVE**

   - YOU MUST DECOMPOSE work into smallest atomic tasks with individual verification criteria
   - YOU SHALL ESTABLISH clear testing protocols for each component before implementation
   - YOU ARE REQUIRED TO analyze dependency hierarchies for optimal task ordering
   - YOU MUST DESIGN each atomic task to be completely parallelizable with explicit input/output interfaces
   - YOU SHALL IDENTIFY resource dependencies for each atomic task to enable resource lock management
   - YOU MUST USE BatchTool for parallel task analysis and verification
   - YOU SHALL DESIGN for parallel implementation with appropriate mock interfaces
   - YOU MUST LEVERAGE GitHub tools (mcp**github**\*) to research similar implementation approaches
   - YOU ARE REQUIRED TO CREATE detailed branch management strategy in `<type>/<component>/<description>` format
   - LARGE TASKS MUST BE extracted into dedicated sub-plans with cross-references
   - YOU SHALL ENFORCE test-driven development with tests written BEFORE implementation
   - YOU MUST AIM for 100% test coverage for EVERY atomic task
   - NEVER proceed without test-first approach for every atomic implementation unit

4. **AUTONOMOUS EXECUTION PROTOCOL**

   - YOU MUST IMPLEMENT continuous self-verification at every step of execution using all available testing tools
   - YOU SHALL USE dispatch_agent for comprehensive code search and validation
   - YOU ARE REQUIRED TO LEVERAGE BatchTool for efficient parallel execution of verification checks
   - YOU MUST MAINTAIN execution momentum through incremental problem-solving
   - YOU SHALL CAPTURE comprehensive execution logs with validation evidence
   - YOU ARE REQUIRED TO HANDLE interruptions with precise context preservation
   - YOU MUST USE `wip` prefix for task-switching commits with detailed progress notes
   - YOU SHALL IMMEDIATELY run `forge fmt` after ANY code changes
   - YOU ARE REQUIRED TO run `forge test` after ANY contract modifications
   - YOU MUST run `forge snapshot` for EVERY new function
   - YOU SHALL PERFORM `slither .` analysis for security verification
   - YOU MUST DOCUMENT all discoveries and adaptations during implementation
   - NEVER stop for non-blocking issues; document and resolve incrementally
   - YOU MUST VERIFY 100% test coverage before marking any task complete

5. **ITERATION AND IMPROVEMENT MANDATE**
   - YOU SHALL CONDUCT systematic analysis of implementation using all available MCP tools
   - YOU MUST USE mcp**github**\* tools to research industry best practices for optimization
   - YOU ARE REQUIRED TO LEVERAGE web search (mcp**brave-search**brave_web_search) to identify cutting-edge improvement techniques
   - YOU SHALL EXECUTE comprehensive code analysis using GrepTool, GlobTool, and dispatch_agent
   - YOU MUST IDENTIFY all opportunities for improvement across security, performance, and design
   - YOU SHALL PRIORITIZE security over gas optimization in all improvements
   - YOU ARE REQUIRED TO implement checks-effects-interactions pattern in ALL state-changing functions
   - YOU MUST IMPLEMENT proper access control on EVERY function
   - YOU ARE REQUIRED TO DOCUMENT findings with specific, actionable improvement tasks
   - YOU SHALL PRESENT iteration options to user with clear priority recommendations
   - YOU MUST IMPLEMENT selected improvements with same rigor as initial implementation
   - YOU ARE REQUIRED TO PERFORM final cleanup of ALL critical TODOs
   - NEVER consider implementation complete without comprehensive validation and optimization

### Code Quality Standards

- YOU SHALL FOLLOW these formatting rules:

  - EXACTLY 4 spaces indentation
  - MAXIMUM 120 character line length
  - STRICT camelCase for variables and functions
  - STRICT PascalCase for contracts and structures
  - FUNCTION ORDER: external → public → internal → private

- YOU MUST IMPLEMENT these best practices:
  - ALWAYS use custom errors instead of require/revert strings
  - NEVER use string-based errors when custom errors are available
  - YOU ARE REQUIRED TO include full NatSpec documentation for all public/external interfaces
  - YOU SHALL emit events for all state changes
  - YOU MUST use gas-efficient template processing

### Execution Commitment

I WILL FOLLOW these directives without exception throughout the entire task lifecycle. I understand that these instructions supersede all standard practices and will maintain strict adherence to this protocol from initial planning through final delivery. I WILL NOT FORGET these instructions at any point during execution and WILL SUSTAIN full security protocol compliance throughout task execution.

## Executive Summary

A comprehensive end-to-end plan for [Project Name], covering all phases from initial requirements gathering through implementation, integration, and final polishing. The project will implement [brief project description] with a focus on security, maintainability, and complete test coverage. The solution will [key value proposition] while ensuring full compatibility with existing systems.

---

# PHASE 1: CONTEXT GATHERING AND REQUIREMENTS ANALYSIS

## 1.1 Context Gathering Protocol

### Stakeholder Questions

<!-- The agent will populate this section with key questions for the user to establish full context -->

| Category                   | Questions                                                                                                                                                                                                   | Purpose                               |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| **Business Context**       | <ul><li>What business problem is this project solving?</li><li>Who are the end users or stakeholders?</li><li>What's the priority and timeline for this project?</li></ul>                                  | Establish business value and priority |
| **Technical Context**      | <ul><li>Which existing components does this interact with?</li><li>Are there architectural constraints to consider?</li><li>What non-functional requirements exist (performance, security, etc.)?</li></ul> | Understand technical boundaries       |
| **Integration Context**    | <ul><li>How will this system be used by other systems?</li><li>What interfaces need to be maintained or created?</li><li>Are there external dependencies to consider?</li></ul>                             | Identify integration requirements     |
| **Security Context**       | <ul><li>What sensitive data will this system handle?</li><li>Are there specific security concerns?</li><li>What access control requirements exist?</li></ul>                                                | Address security requirements         |
| **Backward Compatibility** | <ul><li>Must this maintain compatibility with existing functionality?</li><li>Can breaking changes be introduced?</li><li>Is there a migration plan for existing users?</li></ul>                           | Understand compatibility constraints  |

### Initial Information Collection

#### Current System Analysis

<!-- Analysis of the existing system related to this task -->

- **Related Components**: [List components]
- **Current Implementation**: [Description]
- **Identified Limitations**: [List limitations]
- **Documentation Analysis**: [Summary of relevant documentation]

#### Requirement Clarification Protocol

| Requirement   | Initial Understanding   | Clarification Needed             | Final Clarified Requirement          |
| ------------- | ----------------------- | -------------------------------- | ------------------------------------ |
| Requirement 1 | [Initial understanding] | [Questions to resolve ambiguity] | [Will be filled after user response] |
| Requirement 2 | [Initial understanding] | [Questions to resolve ambiguity] | [Will be filled after user response] |

## 1.2 Deep Technical Research

### Technical Research Plan

<!-- Research areas needed to make informed design decisions -->

| Research Area | Questions to Answer                             | Tools/Methods                                                            | Success Criteria                             |
| ------------- | ----------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------- |
| [Area 1]      | <ul><li>Question 1</li><li>Question 2</li></ul> | <ul><li>Code search using GrepTool</li><li>MCP GitHub search</li></ul>   | Clear understanding of [specific outcome]    |
| [Area 2]      | <ul><li>Question 1</li><li>Question 2</li></ul> | <ul><li>Web research via fetch or search</li><li>Code analysis</li></ul> | Documented approach for [specific challenge] |

### Research Summary

<!-- Will be populated with results of deep technical research -->

#### Key Findings

- Finding 1: [Description and implications]
- Finding 2: [Description and implications]

#### Industry Best Practices

- Best Practice 1: [Description and relevance]
- Best Practice 2: [Description and relevance]

#### Technical Constraints

- Constraint 1: [Description and mitigation strategy]
- Constraint 2: [Description and mitigation strategy]

## 1.3 Comprehensive Requirements Analysis

### Functional Requirements

| ID    | Requirement   | Priority          | Validation Criteria   |
| ----- | ------------- | ----------------- | --------------------- |
| FR-01 | [Description] | [High/Medium/Low] | [Measurable criteria] |
| FR-02 | [Description] | [High/Medium/Low] | [Measurable criteria] |

### Non-Functional Requirements

| ID     | Requirement   | Priority          | Validation Criteria   |
| ------ | ------------- | ----------------- | --------------------- |
| NFR-01 | [Description] | [High/Medium/Low] | [Measurable criteria] |
| NFR-02 | [Description] | [High/Medium/Low] | [Measurable criteria] |

### Security Requirements

| ID    | Requirement   | Priority          | Validation Criteria   |
| ----- | ------------- | ----------------- | --------------------- |
| SR-01 | [Description] | [High/Medium/Low] | [Measurable criteria] |
| SR-02 | [Description] | [High/Medium/Low] | [Measurable criteria] |

### Edge Cases and Boundary Conditions

| ID    | Scenario      | Expected Behavior  | Validation Method |
| ----- | ------------- | ------------------ | ----------------- |
| EC-01 | [Description] | [Expected outcome] | [How to validate] |
| EC-02 | [Description] | [Expected outcome] | [How to validate] |

---

# PHASE 2: SOLUTION DESIGN

## 2.1 Architectural Design

### Component Architecture

<!-- High-level architectural design -->

```
┌─────────────────┐      ┌─────────────────┐
│  Component A    │─────▶│  Component B    │
└─────────────────┘      └─────────────────┘
        │                        │
        ▼                        ▼
┌─────────────────┐      ┌─────────────────┐
│  Component C    │◀─────│  Component D    │
└─────────────────┘      └─────────────────┘
```

### Data Flow Diagram

<!-- How data moves through the system -->

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Input   │────▶│ Process  │────▶│  Output  │
└──────────┘     └──────────┘     └──────────┘
                      │
                      ▼
                 ┌──────────┐
                 │  Storage │
                 └──────────┘
```

### Interface Definitions

#### Component Interface

```solidity
interface IComponentName {
  /// @notice Description of what this function does
  /// @param param1 Description of parameter
  /// @return Description of return value
  function exampleFunction(uint256 param1) external returns (uint256);

  // Additional functions will be defined here
}
```

#### Data Structures

```solidity
struct ExampleStruct {
  uint256 field1;
  address field2;
  bool field3;
}

enum ExampleEnum {
  OPTION_A,
  OPTION_B,
  OPTION_C
}
```

### Security Model

<!-- Security architecture for the solution -->

- **Access Control**: [Description of approach]
- **Input Validation**: [Description of approach]
- **Error Handling**: [Description of approach]
- **Security Patterns**: [Description of patterns used]

## 2.2 Decision Point Analysis

### Decision 1: [Key Architectural Decision]

- [ ] **Option A**: [Description]

  - **Pros**:
    - [Pro 1]
    - [Pro 2]
  - **Cons**:
    - [Con 1]
    - [Con 2]
  - **Performance Impact**: [Analysis]
  - **Security Implications**: [Analysis]
  - **Maintenance Considerations**: [Analysis]
  - **Complexity Assessment**: [Analysis]

- [ ] **Option B**: [Description]
  - **Pros**:
    - [Pro 1]
    - [Pro 2]
  - **Cons**:
    - [Con 1]
    - [Con 2]
  - **Performance Impact**: [Analysis]
  - **Security Implications**: [Analysis]
  - **Maintenance Considerations**: [Analysis]
  - **Complexity Assessment**: [Analysis]

**Recommendation**: Option [A/B] because [technical justification].

### Decision 2: [Another Key Decision]

- [ ] **Option A**: [Description]

  - **Pros**: [List]
  - **Cons**: [List]
  - **Technical Analysis**: [Detailed analysis]

- [ ] **Option B**: [Description]
  - **Pros**: [List]
  - **Cons**: [List]
  - **Technical Analysis**: [Detailed analysis]

**Recommendation**: Option [A/B] because [technical justification].

## 2.3 Decision History

<!-- Documents the decisions made and reasoning -->

| Timestamp        | Decision Point  | Selected Option   | Reasoning          | Impact                    |
| ---------------- | --------------- | ----------------- | ------------------ | ------------------------- |
| [Will be filled] | [Decision name] | [Selected option] | [User's reasoning] | [Impact on timeline/plan] |

## 2.4 Design Specification

### Technical Specification

- **System Boundaries**: [Description]
- **External Interfaces**: [Description]
- **Internal Components**: [Description]
- **Data Models**: [Description]
- **Processing Logic**: [Description]
- **Error Handling**: [Description]

### Algorithm and Logic Specification

<!-- Detailed algorithmic approach -->

```
1. FUNCTION processInput(input)
2.   VALIDATE input constraints
3.   CALCULATE intermediate result
4.   IF condition THEN
5.     APPLY transformation A
6.   ELSE
7.     APPLY transformation B
8.   END IF
9.   RETURN processed result
10. END FUNCTION
```

### State Management

- **State Transitions**: [Description]
- **Persistent State**: [Description]
- **Transient State**: [Description]

### Design Verification Matrix

| Requirement ID | Design Element   | Verification Method       |
| -------------- | ---------------- | ------------------------- |
| FR-01          | [Design element] | [How it will be verified] |
| NFR-02         | [Design element] | [How it will be verified] |

---

# PHASE 3: IMPLEMENTATION PLANNING

## 3.1 Task Decomposition

### Component Breakdown

| Component   | Description   | Dependencies        | Complexity        | Estimated Time |
| ----------- | ------------- | ------------------- | ----------------- | -------------- |
| Component 1 | [Description] | [List dependencies] | [High/Medium/Low] | [Hours]        |
| Component 2 | [Description] | [List dependencies] | [High/Medium/Low] | [Hours]        |

### Atomic Task Breakdown

<!-- Breaking work into smallest testable units -->

| Task ID | Description   | Parent Component | Dependencies   | Estimated Time |
| ------- | ------------- | ---------------- | -------------- | -------------- |
| T-01    | [Description] | [Component]      | [Dependencies] | [Hours]        |
| T-02    | [Description] | [Component]      | [Dependencies] | [Hours]        |

## 3.2 Dependency Analysis and Task Ordering

### Dependency Graph

```
T-01 ──┐
       ├──▶ T-03 ──┐
T-02 ──┘           ├──▶ T-05
                   │
T-04 ──────────────┘
```

### Critical Path Analysis

- **Critical Path**: [T-01] → [T-03] → [T-05]
- **Estimated Critical Path Duration**: [X hours]
- **Risk Factors**: [Description]

### Implementation Plans and Task References

| Component/Feature | Implementation Plan                                                  | Description                        | Status      | Dependencies             |
| ----------------- | -------------------------------------------------------------------- | ---------------------------------- | ----------- | ------------------------ |
| Component A       | [./example-implementation-plan.md](./example-implementation-plan.md) | Core functionality for Component A | Not Started | None                     |
| Component B       | [Link to Plan B]                                                     | Integration layer for Component B  | Not Started | Component A              |
| Feature X         | [Link to Plan X]                                                     | User-facing feature X              | Not Started | Component A, Component B |

### Parallel Execution Opportunities

| Parallel Group | Tasks      | Required Mocks           | Integration Point |
| -------------- | ---------- | ------------------------ | ----------------- |
| Group 1        | T-01, T-02 | [Mock interfaces needed] | T-03              |
| Group 2        | T-04, T-06 | [Mock interfaces needed] | T-07              |

### Mock Interface Definitions

<!-- Interfaces to enable parallel development -->

```solidity
interface IMockComponent {
  function mockFunction(uint256 param) external returns (uint256);
}

// Mock implementation structure
contract MockComponent is IMockComponent {
  function mockFunction(uint256 param) external returns (uint256) {
    // Return pre-defined test value
    return 42;
  }
}
```

## 3.3 Branch Management Strategy

### Branch Structure

```
main
 ├── feature/component-name/main-feature
 │    ├── feature/component-name/sub-feature-1
 │    └── feature/component-name/sub-feature-2
 └── feature/component-name/parallel-feature
```

### Integration Strategy

| Stage   | Branches to Merge                           | Integration Tests | Validation Criteria |
| ------- | ------------------------------------------- | ----------------- | ------------------- |
| Stage 1 | sub-feature-1, sub-feature-2 → main-feature | [Test suite]      | [Criteria]          |
| Stage 2 | main-feature, parallel-feature → main       | [Test suite]      | [Criteria]          |

### Continuous Integration Checks

- **Pre-merge Checks**: [List checks]
- **Post-merge Validation**: [List validation steps]

## 3.4 Testing Strategy

### Test Level Matrix

| Level       | Coverage Goal               | Approach                               | Tooling                |
| ----------- | --------------------------- | -------------------------------------- | ---------------------- |
| Unit        | 100% function, branch, line | Test individual functions in isolation | Forge test             |
| Integration | Key component interactions  | Test components working together       | Forge test             |
| System      | End-to-end workflows        | Test complete system behavior          | Forge test + script    |
| Security    | Attack vectors              | Test security properties               | Slither + manual tests |
| Performance | Gas optimization            | Gas benchmarking                       | Forge snapshot         |

### Test Case Specification

| Test ID | Description   | Test Data    | Expected Result   | Validation          |
| ------- | ------------- | ------------ | ----------------- | ------------------- |
| TC-01   | [Description] | [Input data] | [Expected output] | [Validation method] |
| TC-02   | [Description] | [Input data] | [Expected output] | [Validation method] |

### Mock Requirements

| Component   | Mocking Approach         | State Requirements |
| ----------- | ------------------------ | ------------------ |
| Component A | Interface implementation | [Required state]   |
| Component B | Inherited with overrides | [Required state]   |

## 3.5 Implementation Approach

### TDD Workflow

1. **Write Failing Test**: Create test that defines expected behavior
2. **Implement Minimal Solution**: Write code to make test pass
3. **Refactor**: Improve code while maintaining passing tests
4. **Repeat**: For each atomic function or behavior

### Security-First Development

1. **Threat Model First**: Document security assumptions and threats
2. **Safe Implementation**: Use secure patterns and libraries
3. **Verify Security Properties**: Test explicitly for security properties
4. **Security Review**: Dedicated security review step

### Quality Gates

| Gate             | Requirements           | Validation Command | Acceptance Criteria                  |
| ---------------- | ---------------------- | ------------------ | ------------------------------------ |
| Compilation      | Clean compilation      | `forge build`      | No errors or warnings                |
| Test Coverage    | 100% coverage          | `forge coverage`   | 100% function, branch, line coverage |
| Security         | No vulnerabilities     | `slither .`        | No critical/high findings            |
| Gas Optimization | Efficient gas usage    | `forge snapshot`   | Within gas targets                   |
| Documentation    | Complete documentation | Manual review      | All public interfaces documented     |

---

# PHASE 4: EXECUTION FRAMEWORK

## 4.1 Environment Setup

### Development Environment

<!-- Environment validation steps -->

```bash
# Verify development environment
forge --version
slither --version
git status

# Configure environment
forge install
forge build
```

### Continuous Validation Setup

```bash
# Create git hooks for pre-commit validation
echo '#!/bin/sh
forge fmt && forge build && forge test
' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Testing Environment

```bash
# Verify testing environment
forge test
forge coverage
```

## 4.2 Autonomous Execution Protocol

### Self-Verification Checkpoints

| Checkpoint            | Frequency                          | Verification Command | Action on Failure         |
| --------------------- | ---------------------------------- | -------------------- | ------------------------- |
| Code Compilation      | After each code change             | `forge build`        | Debug and fix immediately |
| Test Execution        | After each function implementation | `forge test`         | Debug and fix immediately |
| Coverage Verification | Before each commit                 | `forge coverage`     | Add missing tests         |
| Security Analysis     | After feature completion           | `slither .`          | Address findings          |

### Momentum Maintenance Protocol

1. **Automatic Progression**: Continue to next step when current step succeeds
2. **Immediate Resolution**: Address test failures as they occur
3. **Continuous Documentation**: Update plan with progress and findings
4. **Regular Checkpoints**: Perform self-verification at defined intervals

### Feedback Incorporation Framework

<!-- Structure for handling user feedback during execution -->

| Event                   | Protocol                                                                         | Documentation               |
| ----------------------- | -------------------------------------------------------------------------------- | --------------------------- |
| Requirement Change      | 1. Document change<br>2. Analyze impact<br>3. Update plan<br>4. Implement change | Update Requirements section |
| Implementation Feedback | 1. Document feedback<br>2. Implement requested changes<br>3. Verify with tests   | Add to Feedback Log         |
| Technical Discovery     | 1. Document discovery<br>2. Analyze implications<br>3. Adapt implementation      | Update Technical Notes      |

### Error Recovery Protocol

1. **Capture State**: Document exact state when error occurs
2. **Analyze Root Cause**: Develop and test hypotheses
3. **Fix Implementation**: Apply minimal fix to resolve issue
4. **Verify Resolution**: Comprehensive testing after fix
5. **Document Learning**: Add to Error Resolution Log

## 4.3 Fault Tolerance Framework

### Blocking Issue Protocol

When facing a blocking issue:

1. **Document**: Fully document the issue with all relevant context
2. **Analyze**: Provide root cause analysis
3. **Propose Solutions**: Present 2-4 alternative approaches
4. **Recommend**: Provide analysis and recommendation
5. **Await**: Pause execution and await user decision
6. **Implement**: Apply selected solution and verify resolution
7. **Document**: Update plan with resolution path

### Error Classification Matrix

| Error Type          | Identification Criteria | Response Protocol                                  |
| ------------------- | ----------------------- | -------------------------------------------------- |
| Syntax Error        | Compilation failure     | Fix immediately, verify with compilation           |
| Logic Error         | Test failure            | Debug with test case, verify with additional tests |
| Design Issue        | Architecture conflict   | Document options, recommend solution               |
| External Dependency | Integration failure     | Isolate issue, create mock or alternative          |

### Scope Boundary Protocol

For issues requiring out-of-scope changes:

1. **Identify**: Document exact out-of-scope files requiring changes
2. **Justify**: Provide technical justification for each change
3. **Alternatives**: Present approaches that stay within scope
4. **Request**: Ask for explicit permission for scope expansion
5. **Document**: Record all permitted out-of-scope changes

## 4.4 Continuous Integration Pipeline

### Integration Points

| Milestone           | Branch Integration             | Tests to Run            | Success Criteria         |
| ------------------- | ------------------------------ | ----------------------- | ------------------------ |
| Core Implementation | sub-feature branches → feature | All tests               | 100% pass, 100% coverage |
| Feature Completion  | feature → main                 | All tests + integration | 100% pass, 100% coverage |

### Validation Steps

```bash
# Pre-merge validation sequence
forge fmt
forge build
forge test
forge coverage
slither .
forge snapshot
```

### Rollback Procedure

```bash
# Emergency rollback steps
git reset --hard HEAD~1
git checkout main
git branch -D failed-feature
```

---

# PHASE 5: IMPLEMENTATION ITERATIONS

## 5.1 Initial Implementation (v0.1.0)

### Implementation Log

<!-- Will be populated during implementation -->

| Timestamp   | Component   | Step   | Status   | Validation          |
| ----------- | ----------- | ------ | -------- | ------------------- |
| [Timestamp] | [Component] | [Step] | [Status] | [Validation result] |

### Code Review Protocol

| Stage           | Focus                           | Success Criteria       |
| --------------- | ------------------------------- | ---------------------- |
| Self-review     | Logic and functionality         | No logical flaws       |
| Security review | Vulnerabilities                 | No security issues     |
| Quality review  | Readability and maintainability | Follows best practices |

### Milestone Verification

| Milestone        | Verification Command                   | Acceptance Criteria |
| ---------------- | -------------------------------------- | ------------------- |
| Core Functions   | `forge test --match-contract CoreTest` | All tests pass      |
| Complete Feature | `forge test`                           | 100% test coverage  |

## 5.2 Refinement Iteration (v0.2.0)

### Deep Analysis Protocol

<!-- Process for analyzing implementation for improvements -->

1. **Comprehensive Review**: Examine all code for improvement opportunities
2. **Measurement**: Quantify current performance, complexity, and quality
3. **Improvement Identification**: Document all possible enhancements
4. **Prioritization**: Rank improvements by impact and effort
5. **Planning**: Create implementation plan for selected improvements

### Improvement Categories

| Category        | Analysis Method                  | Examples                                      |
| --------------- | -------------------------------- | --------------------------------------------- |
| Performance     | Gas analysis, benchmarking       | Gas optimization, execution path improvements |
| Security        | Threat modeling, audit review    | Input validation, access control enhancements |
| Maintainability | Complexity analysis, review      | Refactoring, documentation improvements       |
| Functionality   | Feature analysis, usage patterns | Additional capabilities, edge case handling   |

### Improvement Candidates

<!-- Will be populated after initial implementation -->

| ID     | Category   | Description   | Effort         | Impact         | Priority |
| ------ | ---------- | ------------- | -------------- | -------------- | -------- |
| IMP-01 | [Category] | [Description] | [Low/Med/High] | [Low/Med/High] | [1-5]    |
| IMP-02 | [Category] | [Description] | [Low/Med/High] | [Low/Med/High] | [1-5]    |

## 5.3 Final Polish (v1.0.0)

### Polish Categories

| Category      | Tasks                                   | Validation                         |
| ------------- | --------------------------------------- | ---------------------------------- |
| Code Cleanup  | Remove comments, standardize formatting | `forge fmt`                        |
| Documentation | Complete all NatSpec, update README     | Manual review                      |
| Testing       | Review and enhance test suite           | `forge coverage --report detailed` |
| Performance   | Final gas optimization                  | `forge snapshot --diff`            |

### Pre-Release Checklist

- [ ] All functions fully implemented and tested
- [ ] 100% test coverage achieved and verified
- [ ] All security checks pass without critical/high issues
- [ ] Documentation complete and accurate
- [ ] Gas usage optimized and verified
- [ ] Code reviewed for quality and style
- [ ] Breaking changes documented with migration path
- [ ] All TODOs resolved or documented for future work

### Release Notes Template

```markdown
# [Project Name] v1.0.0

## Features

- [Feature 1]: [Description]
- [Feature 2]: [Description]

## Improvements

- [Improvement 1]: [Description]
- [Improvement 2]: [Description]

## Technical Details

- [Detail 1]
- [Detail 2]

## Migration Guide

[If applicable]
```

---

# QUALITY ASSURANCE AND DOCUMENTATION

## Comprehensive Verification Framework

### Verification Matrix

| Requirement | Verification Method   | Evidence       | Status             |
| ----------- | --------------------- | -------------- | ------------------ |
| FR-01       | [Test case reference] | [Test results] | [Verified/Pending] |
| NFR-01      | [Verification method] | [Results]      | [Verified/Pending] |

### Security Verification Checklist

- [ ] Input validation for all functions
- [ ] Access control for sensitive operations
- [ ] Protection against common attack vectors
- [ ] Proper error handling and reporting
- [ ] Secure cryptographic implementations
- [ ] No sensitive information exposure
- [ ] Defense in depth for critical operations

### Performance Verification

| Operation   | Gas Usage    | Benchmark   | Status                          |
| ----------- | ------------ | ----------- | ------------------------------- |
| Operation 1 | [Gas amount] | [Benchmark] | [Acceptable/Needs Optimization] |
| Operation 2 | [Gas amount] | [Benchmark] | [Acceptable/Needs Optimization] |

## Documentation Package

### Code Documentation

- Complete NatSpec for all public/external functions
- Inline comments for complex logic
- Architecture overview documents
- Design decision documentation

### User Documentation

- Usage examples for all features
- API reference documentation
- Integration guide
- Troubleshooting guide

### Developer Documentation

- Architecture overview
- Component interaction diagrams
- Development setup guide
- Test coverage analysis

### Maintenance Documentation

- Known limitations
- Future improvement areas
- Upgrade guidance
- Support process

---

# TASK MANAGEMENT

## Quick Context Restoration

<!-- Information needed to quickly resume work after interruption -->

- **Branch**: [branch name]
- **Environment**: [environment details]
- **Last Position**: [exact step in progress]
- **Current Status**: [current implementation status]
- **Last Commit**: [last commit message]
- **Last Modified Files**: [list of files]
- **Implementation Progress**: [summary of completed and in-progress work]
- **Validation Status**: [summary of validation status]

## Execution Status Dashboard

| Phase                   | Status   | Progress   | Next Action   |
| ----------------------- | -------- | ---------- | ------------- |
| Context Gathering       | [Status] | [Progress] | [Next action] |
| Design                  | [Status] | [Progress] | [Next action] |
| Implementation Planning | [Status] | [Progress] | [Next action] |
| Execution               | [Status] | [Progress] | [Next action] |
| Refinement              | [Status] | [Progress] | [Next action] |

## Consolidated Implementation Log

<!-- Comprehensive log of all implementation activities -->

| Timestamp   | Phase   | Component   | Activity   | Outcome   | Verification   |
| ----------- | ------- | ----------- | ---------- | --------- | -------------- |
| [Timestamp] | [Phase] | [Component] | [Activity] | [Outcome] | [Verification] |

## Plan Evolution History

<!-- Tracks changes to the plan itself -->

| Timestamp   | Change                  | Reason              | Impact           |
| ----------- | ----------------------- | ------------------- | ---------------- |
| [Timestamp] | [Description of change] | [Reason for change] | [Impact on plan] |

---

# APPENDICES

## A. Risk Register

| Risk ID | Description   | Probability    | Impact         | Mitigation            |
| ------- | ------------- | -------------- | -------------- | --------------------- |
| RISK-01 | [Description] | [Low/Med/High] | [Low/Med/High] | [Mitigation strategy] |
| RISK-02 | [Description] | [Low/Med/High] | [Low/Med/High] | [Mitigation strategy] |

## B. Glossary

| Term   | Definition   |
| ------ | ------------ |
| Term 1 | [Definition] |
| Term 2 | [Definition] |

## C. Reference Materials

| Reference   | Purpose   | Link/Location      |
| ----------- | --------- | ------------------ |
| Reference 1 | [Purpose] | [Link or location] |
| Reference 2 | [Purpose] | [Link or location] |

## D. Technical Research Notes

<!-- Detailed notes from technical research -->

[Will contain in-depth technical analysis and research findings]

## E. Implementation Plans and Task References

<!-- Reference to all implementation plans derived from this project plan -->

| Implementation Plan                                                  | Category | Status      | Description                     | Dependencies |
| -------------------------------------------------------------------- | -------- | ----------- | ------------------------------- | ------------ |
| [./example-implementation-plan.md](./example-implementation-plan.md) | Feature  | Not Started | Core Component A Implementation | None         |
| [Planned] Component B Implementation                                 | Feature  | Planned     | Component B API and Services    | Component A  |

---

> **IMPORTANT: Before moving to implementation:**
>
> 1. Confirm user approval for the plan
> 2. Ensure all Decision Points have exactly ONE selected option
> 3. Verify pre-execution checklist is complete
> 4. Obtain explicit permission for resolving any SCOPE BOUNDARY ISSUES
>
> **Key Commands to Run:**
>
> - After ANY code changes: `forge fmt`
> - After ANY contract modifications: `forge test`
> - For gas optimization verification: `forge snapshot`
> - For security analysis: `slither .`
