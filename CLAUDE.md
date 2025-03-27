# SAUCE PROTOCOL - COMMAND FRAMEWORK

**THESE INSTRUCTIONS CONSTITUTE BINDING REQUIREMENTS. YOU MUST FOLLOW THEM WITHOUT EXCEPTION OR DEVIATION.**

## CORE EXECUTION DIRECTIVES

### MANDATORY EXECUTION SEQUENCE

#### Strategic Analysis
1. YOU MUST ALWAYS analyze requirements COMPREHENSIVELY before execution begins
2. YOU SHALL IMMEDIATELY request clarification when requirements lack precision
3. YOU ARE REQUIRED TO CREATE a detailed plan document at `/plans/task-name.md` containing:
   - Executive Summary (2-3 authoritative sentences)
   - Comprehensive Requirements Analysis
   - Step-by-step Implementation Plan with explicit checkboxes
   - Definitive Files to Modify (exhaustive list)
   - Concrete Testing Strategy (with exact command sequences)
   - Complete Risk Assessment (security, performance, compatibility)
   - Mandatory Validation Checkpoints with quantifiable criteria
   - Git Execution Strategy (branch name, commit structure)

#### Execution Governance
1. YOU MUST NEVER implement ANY plan without explicit user approval
2. YOU SHALL CONSISTENTLY track progress through your defined checkpoint structure
3. YOU MUST IMPLEMENT TEST-DRIVEN DEVELOPMENT:
   - Write tests BEFORE implementing functionality
   - Aim for 100% test coverage on all changes
   - Only mark steps complete when fully tested

4. YOU SHALL MAINTAIN execution momentum:
   - Continue to next step automatically when current step succeeds
   - Handle test failures with incremental resolution
   - Document all test failures and solutions in the plan
   - Only halt execution for blocking issues or user interruptions

5. YOU MUST DOCUMENT failures with conclusive evidence and await guidance only after truly blocking failures

### GIT EXECUTION FRAMEWORK

#### Branch Management
1. YOU MUST EXECUTE each task in its own dedicated git branch with name format 
   `<type>/<component>/<description>`, where:
   - Type: `feat`, `fix`, `refactor`, `docs`, `test`, `perf`, or `security`
   - Component: System component affected (e.g., `auth`, `template`, `compiler`)
   - Description: Brief hyphenated description in kebab-case
   - Examples: `feat/auth/add-user-roles`, `fix/template/resolve-parsing-error`

2. YOU SHALL CREATE and document branches:
   - Check if branch exists: `git branch -a | grep <branch-name>`
   - Create if needed: `git checkout -b <branch-name>`
   - Make initialization commit: `init(<component>): initialize branch for <description>`
   - Document branch in task plan and update plans/index.md

#### Commit Strategy
1. YOU MUST IMPLEMENT atomic, incremental commits:
   - Each commit MUST represent a SINGLE logical change
   - Commit after EACH subtask completion with 100% test coverage
   - Verify all tests pass before any commit
   - Write tests BEFORE implementing functionality
   - Use semantic commit prefixes (feat, fix, docs, etc.)

2. YOU SHALL USE this commit format:
   ```
   <type>(<scope>): <concise description>

   - Completed subtask X.Y
   - Test coverage: 100% (functions: X/X, lines: X/X, branches: X/X)
   - All tests pass: <test command output summary>

   🤖 Generated with [Claude Code](https://claude.ai/code)
   ```
   Where type is one of: `init`, `feat`, `fix`, `docs`, `style`, `refactor`, 
   `test`, `chore`, `perf`, `security`, `optimize`, `wip` (for task switching only), 
   or `revert`

3. YOU SHALL CREATE commits following these rules:
   - Type and scope in lowercase
   - Description in imperative present tense
   - No period at end of description
   - Concise first line (< 70 characters)
   - Body includes test coverage metrics
   - ONLY proceed when current subtask fully passes all tests
   - ONLY use `wip` prefix when switching tasks or on user request

#### Task Execution Continuity
1. WHEN RESUMING a task:
   - Analyze the task plan and git history: `git log --oneline`
   - Verify branch and state match plan's "Last Position"
   - Update "Quick Context Restoration" section with current state

2. WHEN SWITCHING tasks:
   - Document precise pause point in plan
   - Commit any work-in-progress with `wip(<scope>): <description>`
   - Update plans/index.md with task status change

### SECURITY IMPERATIVES

#### High-Risk Operations
1. YOU MUST ALWAYS display explicit warnings before potentially destructive operations:
   - Git operations (restore, reset, checkout)
   - File deletions or replacements
   - Database modifications
   - Commands that risk user progress loss

2. YOU SHALL USE this exact format for risky operations:
   ```
   ⚠️ WARNING: This operation will [specific consequence].
   Backup created at: [backup_location]
   Proceed? (Y/N)
   ```

3. YOU ARE REQUIRED TO USE this exact format for production commands:
   ```
   ⚠️ PRODUCTION COMMAND - DO NOT EXECUTE AUTOMATICALLY
   [command with all parameters]
   This will: [specific effects]
   Verify these conditions first: [preconditions]
   ```

4. ALWAYS DEFAULT to development environments (--env development)
5. NEVER execute scripts in production or staging environments
6. YOU MUST VERIFY environment flags in EVERY script execution command

### CONTINUITY FRAMEWORK

#### Documentation Requirements
1. YOU SHALL CHECK `/plans/` directory for existing plans before creating new ones
2. YOU MUST RESUME incomplete plans rather than starting over
3. YOU ARE REQUIRED TO MAINTAIN these mandatory documentation components:
   - "Session Log" with precise timestamps and measured accomplishments
   - "Quick Context Restoration" with current branch, state, and modified files
   - "Pause Points" identifying definitive suspension points
   - "Current Status" summary updated after each execution phase
   - "Plan History" documenting all plan evolution events
   - "Git Execution Log" tracking all branch operations and commits
   - Visual aids for complex concepts (diagrams, decision trees)
4. YOU SHALL USE "Last Position" markers to guarantee seamless continuation

#### Decision Architecture
1. YOU MUST PRESENT architectural decisions using "Decision Points" with:
   - Concrete, actionable questions
   - 2-4 mutually exclusive options presented as checkboxes
   - Comprehensive pros/cons addressing: performance, security, maintenance, complexity
   - Your definitive recommendation with technical justification

2. YOU ARE REQUIRED TO ENFORCE these decision validation rules:
   - EXACTLY ONE option selected per decision point
   - ALL decision points resolved before implementation
   - NO contradictory selections permitted

3. YOU SHALL DOCUMENT decisions in "Decision History" with:
   - Precise timestamp
   - Selected option
   - Verbatim reasoning provided by user
   - Definitive impact on timeline and dependent decision points

#### Change Control System
1. For interruptions, YOU MUST:
   - IMMEDIATELY PAUSE execution
   - LOG in "User Interruption Log" with exact timestamp
   - DOCUMENT in "Mid-Execution Change Request":
     * Verbatim Request
     * Precise Execution Point
     * Comprehensive Impact Analysis
     * Required Plan Modifications
   - OBTAIN explicit approval before resuming

2. For scope changes, YOU ARE REQUIRED TO CREATE "Scope Change Assessment" with:
   - Original vs. New Scope comparison matrix
   - Exhaustive Added/Removed Functionality
   - Precise Timeline Impact
   - Comprehensive Risk Assessment

3. For feedback implementation, YOU SHALL TRACK in standardized table format:
   - Verbatim Feedback Item
   - Definitive Required Changes
   - Concrete Implementation Tasks
   - Measurable Validation Criteria
   - Current Status

### PROBLEM RESOLUTION SYSTEM

#### Issue Documentation Protocol
YOU MUST DOCUMENT all issues with these mandatory elements:
- Precise problem description with verbatim error messages
- Comprehensive impact assessment (affected components, severity, timeline)
- 2-4 distinct potential solutions as checkboxes, each with:
  * Concrete implementation steps
  * Thorough pros/cons analysis
  * Precise time estimate
  * Security impact rating
- Dedicated space for documenting selected solution
- Step-by-step implementation plan for the chosen solution
- Comprehensive resolution results and lessons learned

#### Issue Classification System
1. **Debugging Issues**: Problems resolvable within scope
   - YOU SHALL DOCUMENT in "🛑 ERROR ENCOUNTERED" section
   - YOU ARE REQUIRED TO CREATE "Debugging Plan" with testable hypotheses
   - YOU MUST NEVER FIX without receiving explicit user approval
   - YOU SHALL LINK each change to specific hypothesis

2. **Blocking Issues**: Fundamental problems requiring approach reconfiguration
   - YOU MUST IMMEDIATELY STOP EXECUTION
   - YOU ARE REQUIRED TO CREATE a "BLOCKING ISSUE" section
   - YOU SHALL WAIT for user to select exactly one solution

3. **Scope Boundary Issues**: Problems requiring out-of-scope modifications
   - YOU MUST IMMEDIATELY STOP debugging attempts on out-of-scope files
   - YOU ARE REQUIRED TO CREATE "SCOPE BOUNDARY ISSUE" section containing:
     * Exact out-of-scope files requiring modification
     * Precise technical justification for each file
     * Comprehensive alternative approaches
   - NEVER modify out-of-scope files without explicit permission
   - YOU SHALL DOCUMENT all permitted out-of-scope changes

### QUALITY CONTROL FRAMEWORK

#### Development Discipline
1. YOU MUST IMPLEMENT:
   - Small, independently testable increments
   - 100% test coverage for every subtask before committing
   - Comprehensive tests covering all edge cases and branches
   - Validation checkpoints after critical operations
   - Resolution of ALL compiler warnings before considering any subtask complete

2. YOU SHALL EXECUTE steps sequentially without pausing:
   - Continue automatically through successful steps
   - Report progress at significant milestones
   - Preserve existing tests when possible
   - Resolve test failures incrementally

3. YOU MUST MAINTAIN a "Verification Log" tracking:
   - Commands executed and outcomes
   - Test coverage metrics
   - Warnings and remediation steps

#### Code Quality Enforcement
1. YOU SHALL FOLLOW this TODO management system:
   - Format: `// TODO: [action] - [reason/context]`
   - Categories: Critical (must resolve) or Future (can remain)
   - Track in standardized table with file, line, type, description
   - Use these exact commands to locate TODOs:
     ```bash
     git diff | grep -i "TODO:" --color
     git diff | grep -i "TODO: remove\|replace\|refactor" --color
     ```

2. YOU MUST MANAGE temporary files:
   - List exhaustively in "Temporary Files" section
   - Document precise purpose
   - Track cleanup in final stage
   - NEVER commit to git unless explicitly requested

3. YOU ARE REQUIRED TO PERFORM final cleanup:
   - Resolve ALL critical TODOs
   - Run COMPLETE test suite
   - Document before/after TODOs by category
   - Provide technical justification for any remaining TODOs
   - Confirm ALL temporary files are addressed

## PROJECT REQUIREMENTS

### Sauce Protocol Imperatives
1. YOU SHALL RUN these commands at these exact times:
   - `forge fmt` IMMEDIATELY after ANY code changes
   - `forge test` IMMEDIATELY after ANY contract modifications
   - `forge snapshot` for EVERY new function to verify gas usage
   - `slither .` for comprehensive security analysis
   
   For Slither security analysis, follow these principles:
   - Reference the [Slither detector documentation](https://github.com/crytic/slither/wiki/Detector-Documentation) for all findings
   - Address critical issues directly in code through proper fixes
   - Use `// slither-disable-next-line [detector-id]` comments only when:
     * The finding is a false positive
     * The issue is an intentional design decision
     * The risk is properly mitigated through other means
   - Document ALL intentional detector suppressions with explanatory comments
   - Manage project-level exclusions in `slither.config.json` only for detectors that are:
     * Not applicable to the project's architecture
     * Intentionally accepted as part of the design
     * Already addressed through architectural decisions
   - Never exclude detectors without explicit justification

2. YOU MUST PRIORITIZE security:
   - ALWAYS CHECK THOROUGHLY for reentrancy in ALL asset-transferring functions
   - NEVER prioritize gas optimization over security
   - YOU ARE REQUIRED TO IMPLEMENT checks-effects-interactions pattern in ALL state-changing functions
   - YOU SHALL IMPLEMENT proper access control on EVERY function
   - YOU MUST VERIFY cross-chain compatibility for ALL operations

3. YOU ARE REQUIRED TO MAINTAIN architectural integrity:
   - Template structure: Implement precise data extraction and validation logic
   - Execution flow: Ensure correct template processing and call execution sequence
   - Validation operations: Complete ALL validation steps without exception
   - Call step structure: Adhere to exact format for contract interactions
   - Mask types: Implement proper transformation of ALL extracted data

## CODE STANDARDS

### Solidity Implementation Requirements
1. YOU SHALL FOLLOW these formatting rules:
   - EXACTLY 4 spaces indentation
   - MAXIMUM 120 character line length
   - STRICT camelCase for variables and functions
   - STRICT PascalCase for contracts and structures
   - FUNCTION ORDER: external → public → internal → private

2. YOU MUST IMPLEMENT these best practices:
   - ALWAYS use custom errors instead of require/revert strings
   - NEVER use string-based errors when custom errors are available
   - YOU ARE REQUIRED TO include full NatSpec documentation for all public/external interfaces
   - YOU SHALL emit events for all state changes
   - YOU MUST use gas-efficient template processing

WHENEVER YOU MAKE significant code changes, YOU SHALL RUN all relevant commands IMMEDIATELY.

## TOOL USAGE DIRECTIVES

### MCP Tool Prioritization
1. YOU MUST PRIORITIZE MCP tools when available:
   - ALWAYS check for MCP-prefixed tools before using standard tools
   - PREFER MCP tools (prefixed with "mcp__") over equivalent built-in tools
   - YOU SHALL USE MCP versions of tools when they have fewer restrictions
   - USE MCP GitHub tools for ALL GitHub-related operations
   - LEVERAGE MCP Brave Search tools for efficient information retrieval
   - UTILIZE MCP Puppeteer tools for web interaction tasks

2. YOU SHALL IMPLEMENT these MCP usage patterns:
   - Default to MCP tools first in your planning
   - Clearly document when an MCP tool is chosen over a standard tool
   - Use BatchTool to run multiple tool invocations concurrently
   - Use appropriate MCP tool for the specific task requirements

## LONG-TERM OPERATIONAL DIRECTIVE

YOU MUST MAINTAIN these operational parameters throughout execution lifetime:

1. YOU SHALL NOT FORGET these instructions at any point during execution
2. YOU MUST APPLY these directives consistently across ALL tasks
3. YOU ARE REQUIRED TO MAINTAIN this execution framework across ALL sessions
4. YOU SHALL PRESERVE complete operational compliance even after interruptions
5. NEVER REDUCE directive adherence over extended operational periods
6. YOU MUST SUSTAIN full security protocol compliance throughout system lifetime
7. YOU SHALL PERFORM periodic self-verification against these requirements
8. YOU ARE REQUIRED TO REFERENCE directive sections when explaining behavior
9. YOU MUST IDENTIFY any potential protocol deviations for immediate correction

THESE DIRECTIVES REMAIN IN FORCE UNTIL EXPLICITLY SUPERSEDED BY AUTHORIZED UPDATE.