# Agent Team Proposal

**Date**: 2026-03-16
**Status**: Draft — pending review and ADR elevation for significant decisions

---

## Purpose

This document synthesizes `docs/design.md`, `docs/planning-process.md`,
`docs/implementation-process.md`, `docs/review-process.md`,
`docs/tracking-process.md`, `docs/architecture.md`, and the Codex agent
configurations in `.codex/` into a complete, detailed agent team specification.

It identifies gaps in `docs/design.md` and proposes resolutions. It is not an
ADR. Decisions that cross architectural thresholds are flagged as requiring ADR
elevation before implementation begins.

---

## Design Principles

- **State-driven dispatch.** Agents are invoked by Linear issue state, not by
  direct call. The Director reads state; state determines which agent acts.
- **Single responsibility.** Each agent owns exactly one phase of the delivery
  lifecycle. No agent crosses phase boundaries.
- **Entry condition enforcement.** Agents refuse to act on issues that are not
  in their required entry state. Refusing is not a failure — it is correct
  behavior.
- **Evidence-based completion.** No state transition advances without the
  required evidence attached. Assertions without evidence are rejected.
- **Fail loudly.** When an agent cannot proceed, it documents the blocker in
  Linear, moves the issue to `Blocked`, and stops. It does not improvise or
  silently skip gates.
- **Humans gate plan review.** Plan artifacts are reviewed and approved by
  humans. No agent auto-approves a plan.
- **ADRs are mandatory.** Significant architectural decisions require an ADR
  before work continues. Agents check for required ADRs and stop if one is
  missing. This applies to all agents.

---

## Linear State Model (Canonical)

The following nine states are the canonical lifecycle states used throughout
this system. State names must match exactly.

| State | Phase | Meaning |
| --- | --- | --- |
| `Draft` | Planning | Feature created; Architect not yet assigned |
| `Planning` | Planning | Architect producing `spec.md`, `plan.md`, `tasks.md` |
| `Plan Review` | Planning | Plan PR open; awaiting human approval |
| `Backlog` | Scheduling | Plan accepted; Coordinator not yet scheduled |
| `Selected` | Implementation | Per-task issues created; ready for Engineer |
| `In Progress` | Implementation | Engineer actively implementing |
| `Blocked` | Any | Work halted; blocker documented |
| `In Review` | Review | Graphite stack published; Technical Lead reviewing |
| `Done` | Complete | PR merged; evidence attached; Director confirms rollup |

`Blocked` is a returnable interruption state. It may be entered from any active
state. On resolution, the issue returns to the state it held before `Blocked`.

> **Gap resolved**: `docs/design.md` refers to states as "ready for
> scheduling", "ready for implementation", and "ready for review". These are
> not valid state names. The canonical entry states are `Backlog`, `Selected`,
> and `In Review` respectively.

---

## Agent Roster

### 1. Director

**Role**: Orchestrator and lifecycle monitor.

**Description**: The Director is the entry point for the entire system. It
polls Linear on a defined cadence, reads the state of each open issue, and
invokes the appropriate specialist agent. It does not perform substantive work
itself. It sequences, delegates, and confirms completion.

**Entry condition**: Any. The Director monitors all non-`Done` issues.

**Polling cadence**: Configurable. Default recommendation is every five
minutes. The Director should support event-driven invocation (Linear webhook)
as an alternative to polling to reduce latency. This is an ADR decision.

**Responsibilities**:

- Poll Linear for all open issues not in `Done` or `Blocked` state.
- For each issue, identify the correct target agent based on current state.
- Invoke the target agent with the Linear issue ID and relevant context.
- After a task reaches `Done`, confirm the completion rollup:
  - All acceptance criteria in the issue are checked off.
  - Required tests pass in CI.
  - The Linear issue references the merged PR.
  - All sub-task issues for the parent feature are `Done` if this is the
    final task.
- Escalate stale issues (no meaningful update in two working days) to the
  weekly review queue.
- Do not act on issues in `Blocked` state. Blocked issues require human or
  agent resolution before the Director re-routes them.

**Dispatch table**:

| Issue State | Target Agent |
| --- | --- |
| `Draft` | Architect |
| `Backlog` | Coordinator |
| `Selected` | Engineer |
| `In Review` | Technical Lead |
| `Done` | Director (rollup confirmation only) |
| `Planning` | No dispatch — Architect is already active |
| `Plan Review` | No dispatch — awaiting human approval |
| `In Progress` | No dispatch — Engineer is already active |
| `Blocked` | No dispatch — awaiting blocker resolution |

**Concurrency**: The Director may invoke multiple agents in parallel when
multiple issues are in dispatchable states. However, each issue has exactly one
active agent at a time. The Director must not invoke a second agent on an issue
that already has an agent assigned and active.

**Failure behavior**: If the invoked agent fails or returns an error, the
Director documents the failure in the Linear issue, moves the issue to
`Blocked`, and surfaces the failure for human review. It does not retry
automatically without a configurable retry policy.

**Tools**: Linear API (read, write), agent invocation mechanism.

**Model**: Lightweight model is sufficient. The Director is routing logic, not
reasoning. Low reasoning effort.

> **Gap identified**: `docs/design.md` says the Director "polls Linear app" but
> does not define polling cadence, failure handling, rollup confirmation logic,
> concurrency constraints, or the dispatch table. These are defined above.

> **ADR required**: Decision between polling vs. webhook-based invocation.
> Decision on retry policy and failure escalation path.

---

### 2. Architect

**Role**: Planning specialist.

**Description**: The Architect converts a `Draft` feature request into approved
planning artifacts: `spec.md`, `plan.md`, `tasks.md`, and any required ADRs.
It produces a plan PR for human review. It does not implement code.

**Entry condition**: Linear issue in `Draft` state. The Architect must not act
on issues in any other state.

**Responsibilities**:

1. Confirm the issue has a defined objective. If not, document the gap and
   move to `Blocked`.
2. Move the issue to `Planning`.
3. Classify the change type (feature, bug fix, refactor, dependency update,
   architecture/platform) per `docs/planning-process.md` Phase 1.
4. Invoke the Explorer agent if research is needed to resolve technical
   unknowns before planning can proceed.
5. Produce `spec.md` using `/speckit.specify` and `/speckit.clarify` as
   needed.
6. Produce `plan.md` using `/speckit.plan`, including the CTR method.
7. Produce `tasks.md` using `/speckit.tasks`. Tasks must be sized for one
   Graphite stacked PR each.
8. Create required ADR documents for any significant architectural decisions
   identified during planning.
9. Run `/speckit.analyze` to verify cross-artifact consistency.
10. Open a PR containing all planning artifacts in `specs/<###-feature-name>/`.
11. Move the issue to `Plan Review`.

**Plan PR title format**:

```text
plan: [Feature Name] planning artifacts
```

**Output artifacts**:

```text
specs/<###-feature-name>/
├── spec.md
├── plan.md
├── research.md     (when Explorer was used)
├── data-model.md   (when applicable)
├── quickstart.md   (when applicable)
├── contracts/      (when applicable)
└── tasks.md
```

Any ADRs produced land in `docs/adr/`.

**Failure behavior**: If a critical ambiguity cannot be resolved, the Architect
documents it in the Linear issue, moves to `Blocked`, and surfaces the question
for human resolution. It does not guess.

**Tools**: GitHub Speckit (`/speckit.*` commands), GitHub (open PR), Linear API
(state transitions, comments), Explorer agent (on demand).

**Model**: High reasoning effort. Planning quality directly determines
downstream delivery quality.

> **Gap identified**: `docs/design.md` omits the Architect's responsibility to
> invoke Explorer for research, to create ADRs, and to run `/speckit.analyze`
> before opening the plan PR. These are required steps per
> `docs/planning-process.md` and `AGENTS.md`.

---

### 3. Coordinator

**Role**: Scheduling specialist.

**Description**: The Coordinator reads the approved `tasks.md` for a feature
and creates one Linear issue per task. It sets dependency links and promotes
dependency-free tasks to `Selected`. It monitors ongoing task completion and
promotes downstream tasks as their dependencies close.

**Entry condition**: Parent feature issue in `Backlog` state (plan PR merged
and approved).

**Responsibilities**:

1. Read `tasks.md` for the feature. Confirm it exists and is consistent with
   `plan.md`.
2. Create one Linear issue per task using the issue schema defined in
   `docs/tracking-process.md`. Required fields per issue:
   - Task ID matching `tasks.md` (e.g., `T-01`)
   - Title in format: `[T-##] [Feature Name] Short task description`
   - State, assignee, project, team, priority
   - Links to `spec.md`, `plan.md`, `tasks.md`
   - Dependency references to other task issue IDs
   - Acceptance criteria summary
   - Required tests summary
   - Scope notes and non-goals
3. Set dependency-free tasks to `Selected`. All others remain in `Backlog`.
4. Register a listener (or schedule a recurring check) to promote tasks to
   `Selected` as their upstream dependencies complete.
5. Move the parent feature issue to an appropriate tracking state (e.g.,
   annotate it with the set of child task issue IDs).

**Progressive promotion**: The Coordinator is responsible for promoting tasks
from `Backlog` to `Selected` as upstream task issues move to `Done`. This may
be implemented as:

- A recurring Coordinator invocation triggered by the Director when it detects
  newly `Done` tasks that have downstream dependents still in `Backlog`.
- A webhook or Linear automation that triggers a Coordinator check.

This is an open design decision. The Director dispatch table should include
"downstream tasks ready to promote" as a trigger condition.

**Failure behavior**: If `tasks.md` is missing or inconsistent, the Coordinator
documents the gap, moves the parent issue to `Blocked`, and surfaces it for
human review.

**Tools**: Linear API (create issues, set state, set dependencies), GitHub
(read `tasks.md`).

**Model**: Low reasoning effort. The Coordinator is primarily data mapping, not
reasoning.

> **Gap identified**: `docs/design.md` says the Coordinator "creates linear
> tickets from accepted plan" but does not describe the issue schema, the
> dependency-sequencing logic, or the progressive promotion mechanism. These are
> defined above. The phrase "ready for scheduling status" in `docs/design.md`
> is replaced by the canonical `Backlog` state.

> **ADR required**: Decision on how progressive task promotion is triggered
> (Director-driven vs. webhook vs. Linear automation).

---

### 4. Engineer

**Role**: Implementation specialist.

**Description**: The Engineer implements exactly one approved task per
invocation. It follows the TDD loop defined in `docs/implementation-process.md`,
creates a Graphite stacked PR, and moves the Linear issue to `In Review` when
validation passes.

**Entry condition**: Linear task issue in `Selected` state, all upstream
dependency issues in `Done` state, and all preconditions in
`docs/implementation-process.md` satisfied.

**Pre-flight checks** (required before any code is written):

- [ ] All upstream dependency task issues are `Done`.
- [ ] `spec.md`, `plan.md`, and the specific task in `tasks.md` have been read
      and understood.
- [ ] Acceptance criteria and required tests for this task are clear.
- [ ] Any required ADRs are present and linked.
- [ ] The local repository is clean and the stack is synced.

If any pre-flight check fails, the Engineer moves the issue to `Blocked`,
documents the gap, and stops.

**Responsibilities**:

1. Assign itself to the Linear issue.
2. Move the issue to `In Progress`.
3. Sync the stack: `gt sync`.
4. Create a git worktree for isolated development.
5. Create the branch: `gt create t-<##>-<short-slug>`.
6. Update the Linear issue with the branch name.
7. Follow the TDD loop: red (failing test) → green (minimum production code)
   → refactor, for each acceptance criterion.
8. Run the full local validation pass (tests, lint, type checks, build) after
   each green cycle and before opening a PR. All checks must pass.
9. Open the PR via `gt submit --stack`.
10. Write the PR description per `docs/implementation-process.md` section 5,
    including links to spec, plan, task, and validation evidence.
11. Move the Linear issue to `In Review`.

**Commit message format**:

```text
<type>(<scope>): <short description> (T-##, <LINEAR-ID>)
```

**Branch name format**:

```text
t-<##>-<short-slug>
```

**Worktree lifecycle**: The Engineer creates the worktree at task start. It
must be retained until the PR is merged. After the PR merges, the worktree is
cleaned up. If the task is rejected and must be retried, the worktree is
retained or recreated as needed.

**Scope change protocol**: If implementation reveals work outside the approved
task, the Engineer stops, documents the discovery in the Linear issue, and
moves the issue to `Blocked`. It does not silently expand scope.

**Failure behavior**: On any uncertainty — architectural ambiguity, missing
requirement, test environment failure — the Engineer documents the blocker,
moves the issue to `Blocked`, and stops. It does not resolve product or
architectural ambiguity autonomously.

**Tools**: Graphite CLI (`gt`), git, test runner, linter, type checker, Linear
API, GitHub API.

**Model**: High reasoning effort for implementation. Needs strong code
generation and test-first discipline.

> **Gap identified**: `docs/design.md` says the Engineer is "invoked with
> linear ticket id" and "ticket state must be in ready for implementation
> status". The canonical state is `Selected`. The design.md omits pre-flight
> checks, the worktree lifecycle, the scope change protocol, and the TDD loop
> requirement. These are defined above.

---

### 5. Technical Lead

**Role**: Review specialist.

**Description**: The Technical Lead performs four-tier code review on submitted
pull requests per `docs/review-process.md`. It produces a structured verdict
(`approve`, `revise`, or `reject`) with concrete findings. It does not approve
based on style alone and does not summarize without findings.

**Entry condition**: Linear task issue in `In Review` state, with a linked
Graphite stack PR whose description contains all required traceability fields.

**Pre-flight checks** (required before deep review begins):

- [ ] The PR maps to one approved task.
- [ ] The PR description links `spec.md`, `plan.md`, `tasks.md`, and the
      Linear issue.
- [ ] Validation evidence is attached or linked.
- [ ] No undocumented architectural decision is present in the diff.

If any pre-flight check fails, the Technical Lead stops and returns the PR
without starting deep review, with a clear explanation of what is missing.

**Review tiers**:

1. **Automated validation**: build, lint, type checks, test suite, and
   traceability all pass.
2. **Implementation fidelity**: the change does what the approved task says,
   nothing more.
3. **Architectural integrity**: abstractions, interfaces, security, concurrency,
   and ADR coverage.
4. **Final polish**: naming, structure, maintainability.

**Verdict model**:

- `reject`: fundamentally unreviewable, out of scope, unsafe, or inconsistent
  with the approved plan.
- `revise`: direction acceptable, but specific defects must be fixed.
- `approve`: sufficient confidence for merge.

**On approval**: The Technical Lead approves the PR in Graphite. The PR merges
from the bottom of the stack up. After merge, the Linear issue moves to `Done`
and the Director confirms the rollup.

**On revise/reject**: The Linear issue returns to `In Progress`. The Engineer
addresses findings.

**High-risk changes**: Changes touching auth, persistence, migration,
distributed workflows, or architectural boundaries require the Tier 3 review to
be completed by a human or designated senior reviewer agent. The Technical Lead
flags these changes and escalates rather than approving alone.

**Failure behavior**: When findings cannot be resolved within the existing task
scope, the Technical Lead escalates to the tech lead for design disputes or
product owner for scope disputes, per the escalation rules in
`docs/review-process.md`.

**Tools**: GitHub (read PR, post review comments, approve/reject), Graphite
(review tooling), Linear API (state transitions).

**Model**: High reasoning effort. Review quality is a quality gate. Needs
strong reasoning over code, specs, and plans.

> **Gap identified**: `docs/design.md` says the Technical Lead is "invoked with
> linear ticket id" and "ticket state must be in ready for review status". The
> canonical state is `In Review`. The design.md omits the pre-flight checks,
> four-tier structure, verdict model, high-risk escalation, and the approval
> → merge flow. These are defined above.

---

### 6. Explorer

**Role**: Research specialist.

**Description**: The Explorer performs research operations on demand. It
inspects the repository, reads official documentation, searches external
sources, and produces a structured research brief with source citations. It
does not edit files, create branches, or make architectural decisions.

**Entry condition**: On demand. The Explorer is invoked by the Architect when
technical unknowns must be resolved before planning can proceed, or by a human
when independent research is needed.

**Invocation inputs**: A problem statement, a list of specific unknowns or
questions, and a description of the target audience (usually the Architect).

**Output format**:

```text
## Problem
## Constraints
## Affected Areas
## Unknowns Resolved
## Risks Identified
## Suggested Directions
## Sources
```

Output is written to `specs/<###-feature-name>/research.md` when invoked in
the context of a feature. For standalone research, output is delivered as a
report artifact.

**Rules**:

- Every factual claim must include a source citation.
- Do not produce implementation patches.
- Do not create branches or pull requests.
- Do not make architectural decisions — flag them as decisions to be made.

**Tools**: Web search, repository read access, documentation access.

**Model**: Medium reasoning effort with web search access enabled. Research
quality over speed.

> **Gap identified**: `docs/design.md` defines Explorer but does not specify
> when it is invoked, how its output is structured, where output is stored, or
> how it integrates with the Architect's planning workflow. These are defined
> above.

---

## Agent Invocation Model

### Current state

The `.codex/config.toml` defines a root orchestrator with four specialist
sub-agents (research, planning, implementation, review) operating as a
per-request pipeline. This is the Codex multi-agent model.

The `docs/design.md` defines a Director that polls Linear and dispatches to
six specialist agents. This is the event-driven Linear-polling model.

### Relationship between the two models

These models are not competing. They operate at different levels:

- The **Codex pipeline** (`config.toml`) is a *per-task local execution
  substrate* — when an agent session is launched, it uses this pipeline to
  handle research → planning → implementation → review within that session.
- The **Director + specialist agents** is the *system-level orchestration layer*
  — it monitors Linear and decides which agent type to invoke, then hands off
  to the appropriate agent session.

The Director invokes an Architect session (which may internally use the Codex
pipeline for research and planning sub-tasks) or an Engineer session (which
uses the Codex implementation agent), etc.

### Proposed invocation flow

```text
Linear (state change or poll)
  → Director reads state
  → Director invokes specialist agent session
    → Agent session may use Codex sub-agents internally
  → Agent updates Linear on completion
  → Director reads new state on next poll cycle
```

> **ADR required**: This relationship between the Director orchestration layer
> and the Codex multi-agent pipeline must be formalized as an architectural
> decision, as it governs how all agent work is structured.

---

## Tool Assignments

| Tool | Agents That Use It |
| --- | --- |
| Linear API | Director, Architect, Coordinator, Engineer, Technical Lead |
| GitHub (read) | Architect, Engineer, Technical Lead, Explorer |
| GitHub (write: PR, comments) | Architect, Engineer, Technical Lead |
| GitHub Speckit | Architect |
| Graphite CLI (`gt`) | Engineer, Technical Lead |
| Web search | Explorer |
| AWS | Unassigned — see gap below |

> **Gap identified**: `docs/design.md` lists AWS as a tool but does not assign
> it to any agent or define what AWS operations agents are expected to perform.
> This must be defined before agents are built.

---

## Gaps in docs/design.md

The following gaps were identified. Each is addressed above or flagged for ADR
elevation.

| # | Gap | Resolution |
| --- | --- | --- |
| 1 | State names in design.md do not match canonical states in tracking-process.md | Resolved: canonical state names are Draft, Planning, Plan Review, Backlog, Selected, In Progress, Blocked, In Review, Done |
| 2 | Director has no defined polling cadence | Proposed: 5-minute default; webhook alternative flagged as ADR decision |
| 3 | Director has no failure handling or retry policy | Proposed: document in Linear, move to Blocked, surface to human |
| 4 | Director concurrency constraints undefined | Proposed: one active agent per issue at a time |
| 5 | Director rollup confirmation logic undefined | Proposed: check acceptance criteria, CI, PR link, sub-task completion |
| 6 | No intake/triage role defined | Gap remains: who creates the Draft Linear issue? A human today. Consider a future Triage agent |
| 7 | Coordinator progressive promotion logic undefined | Proposed: Director re-invokes Coordinator when upstream tasks complete |
| 8 | Explorer output format and storage undefined | Proposed: structured report to `specs/<###>/research.md` |
| 9 | Explorer invocation trigger undefined | Proposed: on demand by Architect or human |
| 10 | Engineer worktree lifecycle undefined | Proposed: create at start, retain until PR merges, clean up after merge |
| 11 | Engineer model selection undefined | Proposed: high reasoning effort per role requirements |
| 12 | Technical Lead four-tier structure not referenced in design.md | Resolved: defined in review-process.md; entry condition and pre-flight checks documented here |
| 13 | Who merges the PR after Technical Lead approves | Proposed: Graphite manages bottom-up merge after approval; Director confirms rollup |
| 14 | AWS tool has no assigned agent or defined operations | Unresolved: requires product decision |
| 15 | Agent authentication and secrets strategy undefined | Unresolved: requires ADR |
| 16 | Codex pipeline vs. Director orchestration relationship undefined | Proposed resolution above; requires ADR |
| 17 | Tracking-process.md references Linear; implementation-process.md references GitHub Issues | Inconsistency: canonical tracker is Linear per tracking-process.md; implementation-process.md should be updated |
| 18 | No agent explicitly responsible for enforcing ADR requirements during review | Resolved: Technical Lead Tier 3 review checks ADR coverage; all agents are required by AGENTS.md to check ADR coverage before proceeding |
| 19 | No triage agent for initial feature intake | Open: human-initiated today; Triage agent is a future consideration |

---

## Decisions Requiring ADRs

Before this team design moves to implementation, the following decisions must
be elevated to ADRs per the mandate in `AGENTS.md`:

1. **Polling vs. webhook invocation for the Director** — affects latency,
   complexity, and infrastructure cost.
2. **Retry and failure escalation policy** — governs what happens when an agent
   fails or is stuck.
3. **Codex multi-agent pipeline as internal execution substrate** — formalizes
   the relationship between Director orchestration and Codex sub-agent sessions.
4. **Progressive task promotion mechanism** — defines how the Coordinator
   promotes tasks as upstream dependencies complete.
5. **Agent authentication and secrets management strategy** — governs how agents
   authenticate to Linear, GitHub, Graphite, and AWS.
6. **AWS tool scope** — defines which AWS operations agents are expected to
   perform and which agent performs them.
7. **Worktree management policy** — governs creation, isolation, and cleanup of
   git worktrees for concurrent Engineer sessions.

---

## Open Questions

1. Who creates the initial `Draft` Linear issue? A human today. Should a
   future Triage agent handle intake classification and Draft issue creation
   from a raw request?
2. Should the Technical Lead agent perform plan review in addition to code
   review, or is plan review always human-only?
3. Can multiple Engineer agents work in parallel on independent tasks within
   the same feature? If so, what is the worktree and branch naming policy for
   parallel execution?
4. What is the maximum allowed stack depth for Graphite stacked PRs before the
   Coordinator must re-sequence tasks?
5. When an Engineer fails mid-task and leaves a partial worktree, what is the
   recovery procedure? Does a new Engineer session resume the worktree or
   start fresh?
6. What AWS operations are in scope? Infrastructure provisioning? Secrets
   retrieval? Deployment?
7. Should the Director be a persistent daemon or a scheduled job? Daemon offers
   lower latency; scheduled job is simpler to operate and easier to audit.

---

## Summary of Agent Roles

| Agent | Entry State | Primary Output | Model Effort |
| --- | --- | --- | --- |
| Director | Any (monitor) | Agent invocation, rollup confirmation | Low |
| Architect | `Draft` | `spec.md`, `plan.md`, `tasks.md`, ADRs, plan PR | High |
| Coordinator | `Backlog` | Per-task Linear issues, dependency graph | Low |
| Engineer | `Selected` | Graphite stacked PR, validation evidence | High |
| Technical Lead | `In Review` | Review verdict, findings, approval | High |
| Explorer | On demand | Research brief with source citations | Medium |
