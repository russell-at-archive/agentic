# Task Tracking Process

## Purpose

This document defines the task tracking process for the Archive Agentic
workflow.

The intent is a process that is:

- simple enough to use consistently
- rigorous enough to preserve traceability and execution quality
- explicit enough for both human developers and AI agents to collaborate safely
- designed to be operated autonomously by agents while remaining transparent
  to humans

The guiding principle is that planning and execution are distinct. Planning
artifacts define approved work. Linear records the live execution of that work
across the full nine-state lifecycle from initial feature draft through to
delivered increment.

## Process Summary

1. Use `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts
   managed via GitHub Speckit.
2. Use one Linear issue per approved task as the live execution record.
3. Move each issue through the full nine-state lifecycle:
   `Draft` → `Planning` → `Plan Review` → `Backlog` → `Selected` →
   `In Progress` → `In Review` → `Done`, with `Blocked` as a returnable
   interruption state from any active state.
4. Require explicit ownership, blocker handling, traceability, and completion
   evidence at each state transition.
5. Require agents to leave resumable execution notes when they materially
   advance or block a task.
6. Use Graphite for stacked pull requests to maintain high throughput and clean
   review boundaries.

## Agent Team

The workflow is executed by a team of specialized agents. Each agent is
responsible for a defined portion of the lifecycle and only acts on issues
whose state signals that agent's entry condition. The Director is the entry
point once a `Draft` issue exists — it polls Linear and delegates to the
correct agent. Before that, a human may invoke the Feature Draft Agent to
create the initial `Draft` issue.

| Agent | Role | Entry State |
| --- | --- | --- |
| Feature Draft Agent | Conducts human intake and creates a planning-ready `Draft` issue | Human invoked |
| Director | Polls Linear; invokes the appropriate agent based on issue state | Any |
| Architect | Produces planning artifacts; opens plan review PR | `Draft` |
| Coordinator | Schedules accepted plans by creating per-task Linear issues | `Backlog` |
| Engineer | Implements tasks via Graphite stacked PRs | `Selected` |
| Technical Lead | Reviews submitted pull requests | `In Review` |
| Explorer | Performs research and produces sourced reports | On demand |

Agents must not act on issues that are not in their required entry state.

## Design Principles

- **Track execution, not ideation.** Linear tickets represent actionable,
  approved work units only once they reach `Draft`.
- **Agent-First.** The process is designed to be operated autonomously by
  agents while remaining legible to humans.
- **Link everything.** Tickets must link back to `spec.md`, `plan.md`, and
  `tasks.md`.
- **One task, one owner.** Every issue has exactly one directly responsible
  agent or human.
- **Small batches.** Tasks are sized for review in a single Graphite stacked
  PR.
- **Visibility first.** Blockers and status changes must be reflected in Linear
  immediately.
- **Evidence-based completion.** A task is not `Done` until verification
  evidence is attached.
- **No silent scope expansion.** Discovery of out-of-scope work pauses
  execution and returns to planning.

## Separation of Responsibilities

| Artifact or Tool | Responsibility |
| --- | --- |
| `spec.md` | Defines behavior, scope, and acceptance criteria |
| `plan.md` | Defines implementation approach, constraints, and validation strategy |
| `tasks.md` | Defines the approved implementation task breakdown and dependencies |
| Linear | Holds live execution state, ownership, blockers, branch, PR, and evidence |
| Graphite | Manages stacked pull requests and implementation review |
| GitHub | Canonical source control and final PR merge destination |

The governing rule is:

- if execution status changes, update Linear
- if scope, design, acceptance criteria, or sequencing changes, update planning
  artifacts first

## Source of Truth Model

- `tasks.md` is the source of truth for approved task decomposition.
- Linear is the source of truth for live execution state.

After tasks are promoted into Linear by the Coordinator, `tasks.md` is not
edited to reflect day-to-day execution progress. It changes only when planning
changes.

## Task Unit and Mapping

The default execution unit is one task from `tasks.md`. Each task maps to:

- one task identifier in `tasks.md`
- one Linear issue
- one branch
- one Graphite stacked pull request

Exceptions are allowed only when they improve clarity rather than reduce it:

- a very small follow-up may share a PR if review scope remains clear
- a large task may be split, but `tasks.md` and related planning artifacts must
  be updated first

## Task Definition Requirements

Before a task becomes executable, it must have enough planning detail to
prevent avoidable ambiguity during implementation.

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match `tasks.md` (e.g., `T-01`) |
| Title | Yes | One-line imperative statement of the outcome |
| Objective | Yes | Two to five sentences explaining the purpose |
| Dependencies | Yes | Upstream task IDs or external prerequisites |
| Acceptance criteria | Yes | Numbered list of verifiable outcomes |
| Files or scope area | Yes | Likely code paths or subsystems |
| Required tests | Yes | Validation expectations |
| Non-goals | Yes | Explicit scope boundaries |

## Linear Issue Schema

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match the planning artifact (e.g., `T-01`) |
| Title | Yes | Same outcome as the planned task |
| State | Yes | Must use the standard state model |
| Assignee | Yes | Exactly one directly responsible engineer or agent |
| Project | Yes | Feature or initiative container |
| Team | Yes | Owning engineering team |
| Priority | Yes | Sequencing signal |
| Parent links | Yes | Links to `spec.md`, `plan.md`, and `tasks.md` |
| Dependencies | Yes | Linked blocking issues |
| Branch | When started | Branch implementing the task |
| Pull request | When opened | Graphite stack URL |
| Validation evidence | Before `Done` | Tests, screenshots, logs, rollout proof |
| Last meaningful update | Yes | Most recent real status change |
| Execution notes | For agent-run or complex work | Resume context and handoff trail |

Optional fields: Cycle, Estimate, Milestone, Subsystem labels, Risk level.

## Draft Issue Intake Schema

The initial `Draft` issue created by the Feature Draft Agent should include:

| Field | Required | Notes |
| --- | --- | --- |
| Title | Yes | Outcome-oriented feature title |
| State | Yes | `Draft` |
| Project | Yes | `Agentic Harness` |
| Team | Yes | `Platform & Infra` |
| Requestor | Yes | Human or team asking for the work |
| Classification | Yes | `feature`, `bug fix`, `refactor`, `dependency/update`, or `architecture/platform` |
| Objective | Yes | One-paragraph summary of desired outcome |
| Draft Design Prompt | Yes | CTR-based intake artifact |
| Open Questions | When applicable | Ambiguities to be resolved during planning |
| Acceptance Signal | Yes | How the stakeholder will know the request is satisfied |

The Feature Draft Agent is human-invoked and pre-lifecycle. Once the issue is
in `Draft`, the normal Director-Architect flow begins.

## State Model

All issues move through the same nine states configured at the Linear team
level. State names must match exactly.

| State | Owner | Phase | Meaning | Exit Condition |
| --- | --- | --- | --- | --- |
| `Draft` | Architect | Planning | Feature created; Architect not yet assigned | Architect assigned; objective defined |
| `Planning` | Architect | Planning | Architect producing `spec.md`, `plan.md`, `tasks.md` | Plan PR opened |
| `Plan Review` | Architect | Planning | Plan PR open; awaiting human approval | Plan PR merged |
| `Backlog` | Coordinator | Scheduling | Plan accepted; awaiting Coordinator scheduling | Coordinator creates per-task issues |
| `Selected` | Engineer | Implementation | Per-task issues created; ready for Engineer | Engineer begins work |
| `In Progress` | Engineer | Implementation | Engineer actively implementing | PR submitted or blocker found |
| `Blocked` | Assignee | Any | Work cannot proceed; blocker documented | Blocker resolved |
| `In Review` | Technical Lead | Review | Graphite stack published; Technical Lead reviewing | Review complete |
| `Done` | Director | Complete | PR merged; evidence attached; Director confirms rollup | None |

`Blocked` is a returnable interruption state. It may be entered from any
active state. On resolution, the issue returns to the state it held before
entering `Blocked`.

A task may never move from `Blocked` directly to `Done`.

### State Transition Rules

**Planning track:**

- `Draft` → `Planning`: Architect is assigned, objective is defined, planning
  begins.
- `Planning` → `Blocked`: Architect encounters an unresolvable dependency or
  ambiguity.
- `Planning` → `Plan Review`: Architect opens a PR containing all planning
  artifacts and `/speckit.analyze` passes.
- `Plan Review` → `Planning`: Review finds deficiencies; Architect revises.
- `Plan Review` → `Backlog`: Plan PR is approved and merged.

**Scheduling track:**

- `Backlog` → `Selected`: Coordinator creates one Linear issue per task and
  marks dependency-free issues `Selected`.

**Implementation track:**

- `Selected` → `In Progress`: Engineer is assigned, creates a worktree,
  initializes a Graphite stack, and begins implementation.
- `In Progress` → `Blocked`: A blocker is identified and formally documented.
- `Blocked` → prior state: Blocker is resolved and a resolution comment is
  added.
- `In Progress` → `In Review`: Engineer publishes Graphite stack with
  traceability links.
- `In Review` → `In Progress`: Technical Lead finds defects; Engineer
  addresses them.
- `In Review` → `Done`: Technical Lead approves; all acceptance criteria
  verified; evidence attached; PR merged; Director confirms rollup.

## Gate Rules

These gates enforce the minimum conditions for each state transition.
Transition without satisfying the gate is not permitted.

| Gate | Transition | Condition |
| --- | --- | --- |
| T-1 | `Draft` → `Planning` | Architect assigned; issue objective defined |
| T-2 | `Planning` → `Plan Review` | `spec.md`, `plan.md`, and `tasks.md` exist; `/speckit.analyze` passes |
| T-3 | `Plan Review` → `Backlog` | Plan PR approved and merged |
| T-4 | `Backlog` → `Selected` | All dependency tasks are `Done` |
| T-5 | `Selected` → `In Progress` | Worktree created; Graphite stack initialized; issue updated |
| T-6 | `In Progress` → `Blocked` | Blocker formally documented with owner and date |
| T-7 | `In Progress` → `In Review` | Graphite stack published; PR links to spec, plan, and task |
| T-8 | `In Review` → `Done` | All acceptance criteria verified; evidence attached; PR merged; Director confirms rollup |

## Entry Criteria

An issue may enter `Selected` only when:

- it exists in `tasks.md`
- the parent `spec.md` and `plan.md` are approved and merged
- dependencies are identified
- acceptance criteria are explicit
- required tests are identified
- the task is scoped tightly enough to review in one Graphite stacked PR

If any of these are missing, the work returns to `Planning` instead of
entering execution in a fuzzy state.

## Workflow

### 1. Draft and plan (Architect)

A new feature may be created in Linear by a human directly or by the Feature
Draft Agent. Once the issue exists in `Draft`, the Director detects `Draft`
state and invokes the Architect (Gate T-1).

The Architect:

1. Accepts assignment; confirms the objective is defined.
2. Moves the issue to `Planning`.
3. Produces `spec.md`, `plan.md`, and `tasks.md` using GitHub Speckit.
4. Creates any required ADR documents.
5. Structures `tasks.md` so each task is appropriately sized for a single
   Graphite stacked PR.
6. Runs `/speckit.analyze` to verify cross-artifact consistency (Gate T-2).
7. Opens a PR containing all planning artifacts.
8. Moves the issue to `Plan Review`.

Plan PR title format:

```text
plan: [Feature Name] planning artifacts
```

### 2. Review the plan (human)

Human reviewers examine the plan PR. If deficiencies are found, the issue
returns to `Planning` and the Architect revises. When the PR is approved and
merged, the issue advances to `Backlog` (Gate T-3).

### 3. Schedule work (Coordinator)

The Director detects `Backlog` state and invokes the Coordinator.

The Coordinator:

1. Creates one Linear issue per task from `tasks.md`.
2. Uses the issue title format:

   ```text
   [T-##] [Feature Name] Short task description
   ```

3. Sets the Linear identifier in each issue description so the `tasks.md`
   task ID (e.g., `T-01`) and the Linear identifier (e.g., `ARC-42`) are
   both visible.
4. Copies only execution-relevant metadata: task ID and title, dependency
   references, parent artifact links, acceptance criteria summary, required
   tests summary, and scope notes. Does not duplicate full plan content.
5. Sets issues whose dependency tasks are already `Done` to `Selected`
   (Gate T-4). All others remain in `Backlog` and are promoted progressively
   as upstream tasks complete.

### 4. Implement (Engineer)

The Director detects `Selected` state and invokes the Engineer.

When work begins (Gate T-5):

1. Confirm all dependency issues are `Done`.
2. Assign the Engineer to the Linear issue.
3. Create a git worktree and initialize a Graphite stack. Branch name format:
   `<linear-id>-t-<##>-<short-slug>` (e.g., `arc-42-t-03-add-auth`).
4. Move the issue to `In Progress`.
5. Add the branch name to the issue description.
6. Add a short execution note if there is relevant context for handoff.

Each commit must reference both the task ID and the Linear issue identifier:

```text
feat: implement user model (T-12, ARC-42)
```

The Engineer submits each task as a Graphite stacked pull request and moves
the issue to `In Review` after publishing.

If the task reveals a material change in design or scope, the Engineer stops
and follows the scope change protocol before continuing.

### 5. Report blockers immediately

When any agent cannot proceed, move the issue to `Blocked` and add a comment
documenting (Gate T-6):

- the blocking condition
- what is needed to unblock
- who owns the next decision or action
- who has been notified
- the date the blocker was identified

Blocked work must not remain silently in its prior state. If a blocker persists
more than one working day, escalate at the next team review.

When the blocker is resolved, add a resolution comment and return the issue to
the state it held before entering `Blocked`.

### 6. Review (Technical Lead)

The Director detects `In Review` state and invokes the Technical Lead.

The Graphite stack PR description must include (Gate T-7):

- link to the Linear issue
- link to `spec.md` and the relevant acceptance criteria
- link to `plan.md`
- link to the specific task in `tasks.md`
- summary of what was implemented
- validation evidence available so far (test output, screenshots, logs)
- any deviation from the plan and its justification

If review finds defects, the issue returns to `In Progress` and the Engineer
addresses them. If the change exceeds task scope, the issue returns to planning
or is split into additional approved tasks.

### 7. Close on evidence (Director)

A task moves to `Done` only when (Gate T-8):

- the PR is merged
- all acceptance criteria in the issue are checked off
- required tests are complete and passing in CI
- required screenshots, logs, rollout notes, or manual checks are attached or
  linked
- the Linear issue references the merged PR
- the Director confirms the completion rollup is consistent

`Done` means complete and evidenced, not nearly complete.

## Agent Execution Protocol

For any task where an agent materially advances work, encounters uncertainty,
or leaves work partially complete, the Linear issue must include an
`## Execution Log` section in the issue description with entries sufficient for
a human or another agent to resume safely.

Default reporting tempo: every four hours of active work or at each significant
milestone, whichever comes first.

Each log entry must capture:

- timestamp
- agent role
- action taken
- outcome (success, failure, partial)
- relevant files or commands
- next step or handoff instruction

This requirement is proportional. Routine, low-risk tasks do not require a
verbose transcript. Complex, blocked, or partially completed tasks do.

At the start of each session, the Director must confirm the current state of
relevant Linear issues and identify the target agent before delegating.

Agents must not resolve architectural or product ambiguity autonomously. If a
task requires a new architectural decision, work must pause until the ADR or
planning artifacts are updated. When an agent encounters a blocker, it
documents the blocker, moves the issue to `Blocked`, stops work, and surfaces
the blocker to a human reviewer.

## Scope Change Rules

If execution reveals work outside the approved task:

1. Stop expanding scope.
2. Document the discovery in the Linear issue.
3. Determine whether the change affects scope, design, acceptance criteria, or
   sequencing.
4. If an architectural decision is needed, create or update an ADR before
   continuing.
5. Update the relevant planning artifact (`plan.md`, then re-run
   `/speckit.tasks` if the change is significant).
6. Create or revise tasks as needed.
7. Resume execution only once the revised work is approved.

Silent scope expansion is a planning failure, not a delivery success.

## Validation and Evidence

Every task must close with explicit evidence that it met the plan. Evidence may
include:

- automated test results
- manual verification notes
- screenshots or recordings
- migration output
- rollout confirmation
- monitoring or alert checks

The exact evidence required is defined in `plan.md`. The Linear issue records
where the evidence lives and confirms that it exists.

At the end of each user story phase, verify that the increment is functional
and stable before moving to the next story. Do not carry forward unverified
state.

## Operating Cadence

| Trigger | Action |
| --- | --- |
| Feature created | Create `Draft` issue; Director invokes Architect |
| Plan PR opened | Move issue to `Plan Review` |
| Plan PR merged | Move issue to `Backlog`; Director invokes Coordinator |
| Tasks created | Move task issues to `Selected`; Director invokes Engineer |
| Blocker discovered | Update Linear issue immediately |
| PR published | Move issue to `In Review`; Director invokes Technical Lead |
| PR merged | Director verifies rollup; move issue to `Done`; attach final evidence |
| Daily | Update any issue whose state, blockers, or evidence changed |
| Weekly | Review blocked issues, stale `In Progress` work, and dependency flow |

A stale issue is any `In Progress` issue with no meaningful update in two
working days. Stale issues are reviewed at the weekly cadence and either
unblocked or escalated.

## WIP Limits

To reduce half-finished work and context fragmentation:

- each assignee should have one primary `In Progress` issue by default
- a second active issue requires an explicit reason documented in both issues
- blocked work is not automatic permission to start unlimited replacement work
- finish `In Review` work before pulling more `Selected` work when possible

The goal is flow completion, not apparent activity.

## Tooling

### Linear

Linear is the canonical location for live execution state across the full
lifecycle. Agents interact with Linear via the Linear CLI/API for status
updates, issue creation, and state transitions.

#### Workflow States

Configure the following nine states at the Linear team level. State names must
match exactly.

| State | Phase | Meaning |
| --- | --- | --- |
| `Draft` | Planning | Feature created; Architect not yet started |
| `Planning` | Planning | Architect producing planning artifacts |
| `Plan Review` | Planning | Plan PR open; awaiting human approval |
| `Backlog` | Scheduling | Plan accepted; awaiting Coordinator scheduling |
| `Selected` | Implementation | Tasks created; ready for Engineer |
| `Blocked` | Any | Active work halted; blocker documented |
| `In Progress` | Implementation | Engineer actively implementing |
| `In Review` | Review | Graphite stack published; Technical Lead reviewing |
| `Done` | Complete | PR merged; evidence attached; rollup confirmed |

#### Labels

Use labels for type classification. Use Linear's native priority field
(Urgent, High, Medium, Low, No Priority) for sequencing.

**Type labels:**

| Label | Meaning |
| --- | --- |
| `feature` | New user-visible behavior |
| `bug` | Defect fix |
| `refactor` | Internal restructuring, no behavior change |
| `chore` | Dependency, tooling, or infrastructure work |

**Priority — Linear native priority field:**

| Priority | Meaning |
| --- | --- |
| Urgent | MVP; must ship before any High work begins |
| High | High value; ships after MVP is verified |
| Medium | Nice to have; ships after High is verified |
| Low | Future consideration |

#### Projects and Cycles

Use Linear Projects for feature-level grouping and progress rollup. Use Cycles
for team-level scheduling and throughput tracking. Keep workflow state on
issues — do not use ad hoc labels to duplicate state information.

#### Recommended Views

| View | Filter |
| --- | --- |
| My In Progress | Assignee = me; State = `In Progress` |
| Blocked | State = `Blocked` |
| Selected by Priority | State = `Selected`; sorted by priority |
| In Review | State = `In Review` |
| Done This Cycle | State = `Done`; Cycle = current |

#### Git Integration

Linear's native GitHub integration auto-links branches and pull requests when
the Linear issue identifier (e.g., `ARC-42`) appears in the branch name or PR
title. Always include the issue identifier in branch names.

### GitHub Speckit

Used by the Architect to produce `spec.md`, `plan.md`, and `tasks.md`. Run
`/speckit.analyze` before opening a plan PR to verify cross-artifact
consistency.

### Graphite

Used by the Engineer to submit implementation work as stacked pull requests.
Each task produces one Graphite stack submitted for review by the Technical
Lead.

## Adoption Notes

This process does not use `tasks.md` as the live execution tracker. That
pattern is attractive because it is simple for a single developer working
locally, but it creates collaboration and synchronization problems once work is
shared across people, agents, branches, and reviews. Linear is the canonical
execution record.

Stronger controls — execution log, traceability requirements, gate rules —
exist where they materially improve handoff quality and review confidence. They
are not applied uniformly to every routine task.

If this process is adopted as the repository standard, capture the decision in
an ADR, because it defines a significant workflow choice governing how all work
is executed and governed.

## Conclusion

- Planning artifacts define approved work.
- Linear issues hold live execution state across the full nine-state lifecycle.
- Graphite stacked PRs carry implementation and review discussion.
- GitHub is the canonical merge destination.
- Evidence closes the loop between plan and delivery.

## Open Questions

See [docs/open-questions.md](open-questions.md) for the consolidated
and deduplicated question backlog. Questions originating here are tracked as OQ-12,
OQ-20, OQ-21, OQ-24, OQ-25, OQ-26, OQ-32.

The eight gate rules enforce the conditions for each transition. The nine
workflow states make progress visible and queryable across the team. The agent
role model ensures each phase is handled by the specialist best suited to it.
The proportional execution log protocol keeps auditability requirements
practical rather than ceremonial.
