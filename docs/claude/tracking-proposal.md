# Task Tracking Process

## Purpose

This document defines the task tracking process for the Archive Agentic
workflow.

The intent is a process that is:

- simple enough to use consistently
- rigorous enough to preserve traceability and execution quality
- explicit enough for both human developers and AI agents to collaborate safely

The guiding principle is that planning and execution are distinct. Planning
artifacts define approved work. Task tracking records the live execution of
that work. Linear is the single authoritative source for all issue state
across the full lifecycle — from initial feature draft through to delivered
increment.

## Process Summary

1. Use `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts.
2. Use one Linear Issue per approved task as the live execution record.
3. Move each issue through the full nine-state lifecycle:
   `Draft` → `Planning` → `Plan Review` → `Backlog` → `Selected` →
   `In Progress` → `In Review` → `Done`, with `Blocked` as a returnable
   interruption state available from any active state.
4. Require explicit ownership, blocker handling, traceability, and completion
   evidence at each state transition.
5. Require agents to leave resumable execution notes when they materially
   advance or block a task.

## Agent Team

The workflow is executed by a team of specialized agents. Each agent is
responsible for a defined portion of the lifecycle and only acts on issues
whose state signals that agent's entry condition.

| Agent | Role | Entry State |
| --- | --- | --- |
| Director | Polls Linear and invokes the appropriate agent based on issue state | Any |
| Architect | Produces planning artifacts and opens a plan review PR | `Draft` |
| Coordinator | Schedules accepted plans by creating per-task Linear issues | `Backlog` |
| Engineer | Implements tasks via Graphite stacked PRs | `Selected` |
| Technical Lead | Reviews submitted pull requests | `In Review` |
| Explorer | Performs research and produces sourced reports | On demand |

The Director is the entry point. It observes Linear state and delegates to the
correct agent. Agents must not act on issues that are not in their required
entry state.

## Design Principles

- Track execution, not ideation.
- Only track work that has approved planning artifacts.
- Keep planning artifacts and execution records tightly linked.
- Default to one task, one owner, one branch, and one pull request.
- Make blockers visible immediately.
- Require verification evidence before marking a task complete.
- Keep the state model minimal and durable.
- Preserve enough execution history for a human or agent to resume safely.
- Do not absorb scope changes silently during implementation.

## Separation of Responsibilities

| Artifact | Responsibility |
| --- | --- |
| `spec.md` | Defines behavior, scope, and acceptance criteria |
| `plan.md` | Defines implementation approach, constraints, and validation strategy |
| `tasks.md` | Defines the approved implementation task breakdown and dependencies |
| Linear Issue | Holds live execution state, ownership, blockers, branch, PR, and evidence |
| Pull request | Holds the concrete implementation and review discussion |

The governing rule is:

- if something changes execution status, it belongs in Linear
- if something changes scope, design, acceptance criteria, or sequencing, it
  belongs in the planning artifacts first

## Source of Truth Model

This process uses a split source-of-truth model:

- `tasks.md` is the source of truth for approved task decomposition
- Linear Issues are the source of truth for live execution state

After tasks are promoted into Linear by the Coordinator, `tasks.md` should not
be edited to reflect day-to-day execution progress. It should change only when
planning changes.

## Task Unit and Mapping

The default execution unit is one task from `tasks.md`.

Each task maps to:

- one task identifier in `tasks.md`
- one Linear Issue
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

## Tracker Schema

Each live Linear Issue should contain:

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match the planning artifact (e.g., `T-01`) |
| Title | Yes | Same outcome as the planned task |
| State | Yes | Must use the standard state model |
| Assignee | Yes | Exactly one directly responsible engineer or agent |
| Parent spec | Yes | Link to `spec.md` |
| Parent plan | Yes | Link to `plan.md` |
| Parent task list | Yes | Link to `tasks.md` |
| Dependencies | Yes | Linear issue links or blocker references |
| Branch | When started | Branch implementing the task |
| Pull request | When opened | PR link added to issue |
| Validation evidence | Before done | Tests, screenshots, logs, rollout proof |
| Last meaningful update | Yes | Most recent real status change |
| Execution notes | For agent-run or complex work | Resume context and handoff trail |

Optional fields:

- reviewer
- cycle (sprint)
- project milestone
- team label
- priority

## State Model

All issues move through the same nine states. These states are configured at
the Linear team level and must match the names below exactly.

| State | Owner | Meaning | Exit Condition |
| --- | --- | --- | --- |
| `Draft` | Architect | Feature created; planning work has not yet begun | Architect begins planning |
| `Planning` | Architect | Architect is actively producing `spec.md` and `plan.md` | Plan PR is opened |
| `Plan Review` | Architect | Plan PR is open and awaiting approval | Plan PR is merged |
| `Backlog` | Coordinator | Plan accepted; awaiting scheduling by Coordinator | Coordinator creates per-task issues |
| `Selected` | Engineer | Per-task issues created; ready for implementation | Engineer begins work |
| `Blocked` | Assignee | Work cannot proceed; blocker documented | Blocker resolved |
| `In Progress` | Engineer | Engineer is actively implementing | PR submitted or blocker found |
| `In Review` | Technical Lead | Stacked PR open; awaiting Technical Lead review | Review complete |
| `Done` | Director | PR merged and evidence attached | None |

`Blocked` is a returnable interruption state. It may be entered from
`Planning`, `Selected`, `In Progress`, or `In Review`. On resolution, the
issue returns to the state it held before entering `Blocked`.

### State Transition Rules

**Planning track:**

- `Draft` → `Planning`: Architect is assigned and begins producing planning
  artifacts.
- `Planning` → `Blocked`: Architect encounters an unresolvable dependency or
  ambiguity.
- `Planning` → `Plan Review`: Architect opens a pull request containing
  `spec.md`, `plan.md`, and `tasks.md` for human review.
- `Plan Review` → `Planning`: Review finds deficiencies; Architect revises
  artifacts.
- `Plan Review` → `Backlog`: Plan PR is approved and merged; issue awaits
  scheduling.

**Scheduling track:**

- `Backlog` → `Selected`: Coordinator creates one Linear issue per task from
  `tasks.md` and marks the feature issue `Selected` to signal readiness for
  implementation.

**Implementation track:**

- `Selected` → `In Progress`: Engineer is assigned, creates a worktree and
  branch, and begins implementation.
- `In Progress` → `Blocked`: A blocker is identified and formally documented.
- `Blocked` → `In Progress`: Blocker is resolved and a resolution comment is
  added.
- `In Progress` → `In Review`: Engineer submits a Graphite stacked PR and
  notifies the Technical Lead.
- `In Review` → `In Progress`: Technical Lead finds defects; Engineer addresses
  them.
- `In Review` → `Done`: Technical Lead approves; all acceptance criteria
  verified, evidence attached, PR merged.

A task may never move from `Blocked` directly to `Done`. The blocker must be
resolved and the issue must re-enter its prior active state before it can
proceed.

## Gate Rules

These gates enforce the minimum conditions for each state transition.
Transition without satisfying the gate is not permitted.

| Gate | Condition |
| --- | --- |
| T-1 | `spec.md`, `plan.md`, and `tasks.md` exist before issue enters `Plan Review` |
| T-2 | `/speckit.analyze` passes before plan PR is opened |
| T-3 | Plan PR is approved and merged before issue enters `Backlog` |
| T-4 | All dependency tasks are `Done` before a task enters `Selected` |
| T-5 | Branch opened and issue updated before issue enters `In Progress` |
| T-6 | Blocker formally documented before issue enters `Blocked` |
| T-7 | PR traces to spec, plan, and task before issue enters `In Review` |
| T-8 | All acceptance criteria verified and evidence attached before issue is `Done` |

## Entry Criteria

An issue may enter `Selected` only when:

- it exists in `tasks.md`
- the parent `spec.md` and `plan.md` are approved and merged
- dependencies are identified
- acceptance criteria are explicit
- required tests are identified
- the task is scoped tightly enough to review in one Graphite stacked PR under
  normal circumstances

If any of these are missing, the work should return to `Planning` instead of
entering execution in a fuzzy state.

## Workflow

### 1. Draft and plan (Architect)

A new feature enters Linear as a `Draft` issue. The Director detects the
`Draft` state and invokes the Architect.

The Architect:

1. Moves the issue to `Planning`.
2. Produces `spec.md`, `plan.md`, and `tasks.md` using GitHub Speckit.
3. Creates any required ADR documents.
4. Structures `tasks.md` so each task is appropriately sized for a single
   Graphite stacked PR.
5. Runs `/speckit.analyze` to verify cross-artifact consistency (Gate T-2).
6. Opens a pull request containing all planning artifacts.
7. Moves the issue to `Plan Review`.

The plan PR title follows the format:

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

1. Creates one Linear issue per task defined in `tasks.md`.
2. Each issue title follows the format:

   ```text
   [T-##] [Feature Name] Short task description
   ```

3. Sets the Linear identifier in each issue description so the `tasks.md`
   task ID and the Linear identifier (e.g., `ARC-42`) are both visible.
4. Copies only execution-relevant metadata: task ID and title, dependency
   references, parent artifact links, acceptance criteria summary, required
   tests summary, and scope notes. Does not duplicate full plan content.
5. Sets issues whose dependency tasks are already `Done` to `Selected`. All
   others are created in `Backlog` and promoted to `Selected` progressively as
   upstream tasks complete (Gate T-4).
6. Moves the parent feature issue to `Selected`.

### 4. Implement (Engineer)

The Director detects `Selected` state and invokes the Engineer.

When work begins:

1. Confirm all dependency task issues are `Done` (Gate T-4).
2. Assign the Engineer to the Linear issue.
3. Create a git worktree and branch named `<task-id>-<short-slug>`
   (e.g., `t-03-add-auth`).
4. Move the issue to `In Progress` (Gate T-5).
5. Add the branch name to the issue description.
6. Add a short execution note if there is relevant context for handoff.

Do not begin implementation without completing all steps. Untracked
in-progress work is invisible to the team and to agents resuming the work.

Each commit must reference both the task ID and the Linear issue identifier:

```text
feat: implement user model (T-12, ARC-42)
```

The Engineer submits each task as a Graphite stacked pull request against the
main integration branch. After submitting, the Engineer moves the issue to
`In Review` and notifies the Technical Lead.

If the task reveals a material change in design or scope, the Engineer stops
and follows the scope change protocol before continuing.

### 5. Report blockers immediately

When any agent cannot proceed, move the issue to `Blocked` and add a comment
documenting (Gate T-6):

- the blocking condition
- what is needed to unblock
- who owns the next decision or action, if known
- who has been notified
- the date the blocker was identified

Blocked work must not remain silently in its prior state. Stop and do not
accumulate partial changes while blocked.

If a blocker persists more than one working day, escalate it at the next team
review or equivalent coordination point.

When the blocker is resolved, add a resolution comment documenting what
changed, then return the issue to the state it held before entering `Blocked`.

### 6. Review (Technical Lead)

The Director detects `In Review` state and invokes the Technical Lead.

The pull request description must include (Gate T-7):

- link to the Linear issue
- link to `spec.md` and the relevant acceptance criteria
- link to `plan.md`
- link to the specific task in `tasks.md`
- summary of what was implemented
- validation evidence available so far (test output, screenshots, logs)
- any deviation from the plan and its justification

Linear auto-links PRs when the issue identifier appears in the branch name or
PR title.

If review finds defects, the issue returns to `In Progress` and the Engineer
addresses them. If review finds that the change exceeds task scope, the issue
returns to planning or is split into additional approved tasks.

### 7. Close on evidence

A task moves to `Done` only when (Gate T-8):

- the PR is merged
- all acceptance criteria in the issue are checked off
- required tests are complete and passing in CI
- required screenshots, logs, rollout notes, or manual checks are attached or
  linked
- the Linear issue references the merged PR

`Done` means complete and evidenced, not nearly complete.

## Agent Execution Protocol

Agent-run work requires stronger resumability than human-only work. For any
task where an agent materially advances work, encounters uncertainty, or leaves
work partially complete, the Linear issue must include an `## Execution Log`
section in the issue description with entries sufficient for a human or another
agent to resume safely.

Each log entry should capture:

- timestamp
- agent role
- action taken
- outcome (success, failure, partial)
- relevant files or commands
- next step or handoff instruction

This requirement is proportional. Routine, low-risk tasks do not require a
verbose transcript. Complex, blocked, or partially completed tasks do.

At the start of each session, the Director must report the current state of
relevant Linear issues and identify the target task and agent before beginning
work.

Agents must not resolve architectural or product ambiguity autonomously. If a
task requires a new architectural decision, work must pause until the ADR or
planning artifacts are updated. When an agent encounters a blocker, it
documents the blocker in the issue, transitions the state to `Blocked`, stops
work, and surfaces the blocker to a human reviewer.

An agent that completes a task updates issue state identically to a human
developer: attach validation evidence, verify acceptance criteria, and move the
issue to `Done` after merge.

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

Silent scope expansion weakens planning, review, and delivery predictability.
It is a planning failure, not a delivery success.

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
and stable before moving to the next independent story. Do not carry forward
unverified state.

## Operating Cadence

| Trigger | Action |
| --- | --- |
| Feature created | Create `Draft` issue; Director invokes Architect |
| Plan PR opened | Move issue to `Plan Review` |
| Plan PR merged | Move issue to `Backlog`; Director invokes Coordinator |
| Tasks created | Move task issues to `Selected`; Director invokes Engineer |
| Blocker discovered | Update Linear issue immediately |
| PR opened | Move issue to `In Review`; Director invokes Technical Lead |
| PR merged | Move issue to `Done`; attach final evidence |
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
lifecycle from draft to done.

#### Workflow States

Configure the following nine states at the Linear team level. State names must
match exactly.

| State | Phase | Meaning |
| --- | --- | --- |
| `Draft` | Planning | Feature created; Architect not yet started |
| `Planning` | Planning | Architect is producing planning artifacts |
| `Plan Review` | Planning | Plan PR open; awaiting human approval |
| `Backlog` | Scheduling | Plan accepted; awaiting Coordinator scheduling |
| `Selected` | Implementation | Tasks created; ready for Engineer |
| `Blocked` | Any | Active work halted; blocker documented |
| `In Progress` | Implementation | Engineer actively implementing |
| `In Review` | Review | Stacked PR open; Technical Lead reviewing |
| `Done` | Complete | PR merged and evidence attached |

#### Labels

Use labels for type classification. Linear's built-in priority field (Urgent,
High, Medium, Low, No Priority) should be used for priority rather than a
custom label.

**Type labels** — describes the nature of the work:

| Label | Meaning |
| --- | --- |
| `feature` | New user-visible behavior |
| `bug` | Defect fix |
| `refactor` | Internal restructuring, no behavior change |
| `chore` | Dependency, tooling, or infrastructure work |

**Priority** — use Linear's native priority field:

| Priority | Meaning |
| --- | --- |
| Urgent | MVP; must ship before any High work begins |
| High | High value; ships after MVP is verified |
| Medium | Nice to have; ships after High is verified |
| Low | Future consideration |

#### Projects and Cycles

Use Linear Projects to group issues belonging to the same feature or
initiative. Use Cycles (sprints) to plan and track delivery cadence. The board
view, filtered by project, visualizes task flow across workflow states and
mirrors the state model.

#### Git Integration

Linear's native GitHub integration auto-links branches and pull requests when
the Linear issue identifier (e.g., `ARC-42`) appears in the branch name or PR
title. Always include the issue identifier in branch names to enable this
linking automatically.

### GitHub Speckit

Used by the Architect agent to produce `spec.md`, `plan.md`, and `tasks.md`.
Run `/speckit.analyze` before opening a plan PR to verify cross-artifact
consistency.

### Graphite

Used by the Engineer agent to submit implementation work as stacked pull
requests. Each task produces one stack submitted through Graphite for review
by the Technical Lead.

## Adoption Notes

This process does not use `tasks.md` as the live execution tracker. That
pattern is attractive because it is simple for a single developer working
locally, but it creates collaboration and synchronization problems once work is
shared across people, agents, branches, and reviews. Linear issues remain the
canonical execution record.

This process applies its stronger controls proportionally. The agent execution
log, traceability requirements, and gate rules exist where they materially
improve handoff quality and review confidence. They are not applied uniformly
at the same level of formality to every routine task.

If this process is adopted as the repository standard, it should be captured in
an ADR, because it defines a significant workflow choice governing how all work
is executed and governed.

## Conclusion

The process is a deliberate synthesis:

- planning artifacts define approved work
- Linear issues hold live execution state across the full nine-state lifecycle
- pull requests carry implementation and review discussion
- evidence closes the loop between plan and delivery

The gate rules enforce the conditions for each transition. The nine workflow
states make progress visible and queryable across the team. The agent role
model ensures that each phase is handled by the specialist best suited to it.
The proportional agent protocol keeps auditability requirements practical
rather than ceremonial.
