# Plan Index (Example Template)

This file serves as a template for the plan index. Create your actual working index as `index.md` which will be git-ignored.

## Plan Hierarchy Framework

### Plan Type Definitions

#### Project Plan

A high-level plan that defines the overall architecture, components, and execution strategy for an entire project. Project plans:

- Define system architecture and component interactions
- Identify major decision points and design considerations
- Break down large projects into manageable implementation plans
- Establish project-wide standards and quality gates
- Track overall progress across multiple implementation phases
- Follow the format in `/plans/example-project-plan.md`

#### Implementation Plan

A detailed execution plan focused on implementing a specific component or feature. Implementation plans:

- Link back to their parent project plan with explicit reference
- Provide step-by-step execution tasks for a specific component
- Include comprehensive testing strategy for the component
- Define clear validation criteria for each task
- Track detailed progress at the function/feature level
- Follow the format in `/plans/example-implementation-plan.md`

### When to Create Different Plan Types

#### Create a Project Plan When:

- The work spans multiple components or features
- Architectural decisions are required
- Overall system design is needed
- Multiple developers/teams may work in parallel
- The estimated work exceeds 40 hours

#### Create an Implementation Plan When:

- Implementing a specific component from a project plan
- The work is focused on a clearly defined feature or module
- The scope is manageable by a single developer or pair
- The implementation path is relatively clear
- The estimated work is 8-40 hours

#### Extract a Separate Implementation Plan When:

- A task within an implementation plan exceeds 8 hours
- A component requires specialized expertise
- A component can be developed in parallel
- A component has high complexity or risk

### Plan Cross-References

Plans should reference each other to maintain consistency:

- Project plans list all child implementation plans in Section 3.2
- Implementation plans reference their parent project plan in the Implementation Information section
- The index maintains bidirectional references between projects and implementations

## Project Plans

| Plan                                                   | Category | Status      | Branch    | Created    | Last Updated | Components             | Implementation Plans                                            |
| ------------------------------------------------------ | -------- | ----------- | --------- | ---------- | ------------ | ---------------------- | --------------------------------------------------------------- |
| [Example Project Plan](./example-project-plan.md)      | Example  | Not Started | N/A       | YYYY-MM-DD | YYYY-MM-DD   | ComponentA, ComponentB | [Example Implementation Plan](./example-implementation-plan.md) |
| [Feature X Project](./YYYY-MM-DD-feature-x-project.md) | Feature  | In Progress | feature/x | YYYY-MM-DD | YYYY-MM-DD   | ComponentC, ComponentD | [Feature X Component C](./YYYY-MM-DD-feature-x-component-c.md)  |

## Implementation Plans

| Plan                                                            | Category | Status      | Branch            | Created    | Last Updated | Parent Project                                         | Affected Components | Key Features                          |
| --------------------------------------------------------------- | -------- | ----------- | ----------------- | ---------- | ------------ | ------------------------------------------------------ | ------------------- | ------------------------------------- |
| [Example Implementation Plan](./example-implementation-plan.md) | Example  | Not Started | task/example-task | YYYY-MM-DD | YYYY-MM-DD   | [Example Project Plan](./example-project-plan.md)      | Example components  | Error Handling, Incremental Execution |
| [Feature X Component C](./YYYY-MM-DD-feature-x-component-c.md)  | Feature  | In Progress | task/feature-x-c  | YYYY-MM-DD | YYYY-MM-DD   | [Feature X Project](./YYYY-MM-DD-feature-x-project.md) | ComponentC          | TODO Tracking                         |
| [Bug Fix](./YYYY-MM-DD-bug-fix.md)                              | Bugfix   | Blocked     | task/bug-fix      | YYYY-MM-DD | YYYY-MM-DD   | N/A                                                    | ComponentD          | Debugging Session                     |

## Completed Plans

| Plan                                             | Category | Completed  | Branch              | Created    | Affected Components    | Key Outcomes                            |
| ------------------------------------------------ | -------- | ---------- | ------------------- | ---------- | ---------------------- | --------------------------------------- |
| [Completed Task](./YYYY-MM-DD-completed-task.md) | Feature  | YYYY-MM-DD | task/completed-task | YYYY-MM-DD | ComponentD, ComponentE | Feature X Implemented, 5 TODOs Resolved |

## Plan Categories

- **Project**: Overall project plan that may include multiple implementation plans
- **Feature**: New functionality
- **Bugfix**: Fix for existing issue
- **Refactor**: Code improvements without changing functionality
- **Documentation**: Documentation updates only
- **Testing**: Test additions or improvements
- **DevOps**: Build, deployment, or infrastructure changes
- **Security**: Security audits and improvements

## Status Definitions

- **Planned**: Project approved, detailed planning not yet begun
- **Not Started**: Plan created but execution not begun
- **In Progress**: Work has started but is not complete
- **Blocked**: Cannot proceed due to external dependency
- **Debugging**: Implementation encountered error, debugging in progress
- **Reviewing**: Implementation complete, awaiting review
- **Completed**: All tasks finished successfully
- **Abandoned**: Plan will not be completed (with reason)

## Key Plan Features

- **Error Handling**: Detailed documentation of errors and debugging plans
- **TODO Tracking**: Systematic tracking and resolution of TODO comments
- **Incremental Execution**: Step-by-step implementation with validation
- **Debugging Session**: Timestamped log of debugging activities
- **Code Cleanup**: Final review and cleanup of temporary code
- **Architecture Design**: System design and component interactions
- **Integration Testing**: Cross-component testing and integration
- **Decision Points**: Major design decisions with comprehensive analysis
- **Performance Benchmarking**: Systematic performance measurement
- **Security Analysis**: Threat modeling and security testing
