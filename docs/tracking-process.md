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
that work.

## Process Summary

1. Use `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts.
2. Use one GitHub Issue per approved task as the live execution record.
3. Move each task through a compact shared state model:
   `ready` → `in_progress` → `in_review` → `done`, with `blocked` as a
   returnable interruption state.
4. Require explicit ownership, blocker handling, traceability, and completion
   evidence at each state transition.
5. Require agents to leave resumable execution notes when they materially
   advance or block a task.

## Design Principles

- Track execution, not ideation.
- Only track work that has approved planning artifacts.
- Keep planning artifacts and execution records tightly linked.
- Default to one task, one owner, one branch, and one pull request.
- Make blockers visible immediately.
- Require verification evidence before marking a task complete.
- Keep the state model small and durable.
- Preserve enough execution history for a human or agent to resume safely.
- Do not absorb scope changes silently during implementation.

## Separation of Responsibilities

| Artifact | Responsibility |
| --- | --- |
| `spec.md` | Defines behavior, scope, and acceptance criteria |
| `plan.md` | Defines implementation approach, constraints, and validation strategy |
| `tasks.md` | Defines the approved implementation task breakdown and dependencies |
| GitHub Issue | Holds live execution state, ownership, blockers, branch, PR, and evidence |
| Pull request | Holds the concrete implementation and review discussion |

The governing rule is:

- if something changes execution status, it belongs in the issue tracker
- if something changes scope, design, acceptance criteria, or sequencing, it
  belongs in the planning artifacts first

## Source of Truth Model

This process uses a split source-of-truth model:

- `tasks.md` is the source of truth for approved task decomposition
- GitHub Issues are the source of truth for live execution state

After tasks are promoted into tracker records, `tasks.md` should not be edited
to reflect day-to-day execution progress. It should change only when planning
changes.

## Task Unit and Mapping

The default execution unit is one task from `tasks.md`.

Each task maps to:

- one task identifier in `tasks.md`
- one GitHub Issue
- one branch
- one pull request

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

Each live GitHub Issue should contain:

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match the planning artifact |
| Title | Yes | Same outcome as the planned task |
| Status | Yes | Must use the standard state model |
| Owner | Yes | Exactly one directly responsible engineer or agent |
| Parent spec | Yes | Link to `spec.md` |
| Parent plan | Yes | Link to `plan.md` |
| Parent task list | Yes | Link to `tasks.md` |
| Dependencies | Yes | Task links or blocker references |
| Branch | When started | Branch implementing the task |
| Pull request | When opened | PR link |
| Validation evidence | Before done | Tests, screenshots, logs, rollout proof |
| Last meaningful update | Yes | Most recent real status change |
| Execution notes | For agent-run or complex work | Resume context and handoff trail |

Optional fields:

- reviewer
- milestone or release
- subsystem label
- risk level

## State Model

Use the same status values for all live execution work.

| State | Meaning | Exit Condition |
| --- | --- | --- |
| `ready` | Approved task is available to start | Owner begins work |
| `in_progress` | Task is actively being implemented | Work blocks, PR opens, or implementation completes |
| `blocked` | Work cannot proceed because of a specific blocker | Blocker is resolved and work resumes |
| `in_review` | PR is open and awaiting review or final validation | Review and validation complete |
| `done` | PR is merged and required evidence is attached | None |

States not in this process: `todo`, `backlog`, `qa`, `done pending`, or any
custom team-specific variant. Pre-execution scheduling and dependency
sequencing are handled by planning artifacts, not by additional tracker states.
`backlog` may exist at the portfolio level but is not part of the live
execution workflow for approved tasks.

### State Transition Rules

- `ready` → `in_progress`: Owner claims the task, assigns themselves, and
  opens a branch.
- `in_progress` → `blocked`: A blocker is identified and formally documented.
- `blocked` → `in_progress`: Blocker is resolved and a resolution comment is
  added to the issue.
- `in_progress` → `in_review`: Pull request is opened with spec traceability.
- `in_review` → `in_progress`: Review finds defects; assignee addresses them.
- `in_review` → `done`: Review passes, all acceptance criteria verified,
  evidence attached, PR merged.

A task may never move from `blocked` directly to `done`. The blocker must be
resolved and the task must re-enter `in_progress` before it can proceed to
review.

## Gate Rules

These gates enforce the minimum conditions for each state transition.
Transition without satisfying the gate is not permitted.

| Gate | Condition |
| --- | --- |
| T-1 | `/speckit.analyze` passes before any issue is created |
| T-2 | All dependency tasks are `done` before a task enters `ready` |
| T-3 | Branch opened and issue updated before work begins |
| T-4 | Blocker formally documented before task enters `blocked` |
| T-5 | PR traces to spec, plan, and task before review begins |
| T-6 | All acceptance criteria verified and evidence attached before task is `done` |

## Entry Criteria

A task may enter the live tracker only when:

- it exists in `tasks.md`
- the parent `spec.md` and `plan.md` are approved
- dependencies are identified
- acceptance criteria are explicit
- required tests are identified
- the task is scoped tightly enough to review in one PR under normal
  circumstances

If any of these are missing, the work should return to planning instead of
entering execution in a fuzzy state.

## Workflow

### 1. Create tracker records from `tasks.md`

Once planning is approved, run `/speckit.taskstoissues` to create one issue
per task. Each issue title follows the format:

```
[T-##] [Feature Name] Short task description
```

Copy only the execution-relevant metadata into each issue: task ID and title,
dependency references, parent artifact links, acceptance criteria summary,
required tests summary, and scope notes. Do not copy the full plan into the
issue. The issue should reference planning, not duplicate it.

Only tasks whose dependency tasks are `done` receive the `status:ready` label.
All others are created without a status label and labeled `status:ready`
progressively as upstream tasks complete.

### 2. Keep the queue in `ready`

A task should sit in `ready` only when it is actually startable.

- unresolved dependencies keep a task out of active work
- ownership should not be used to reserve work that cannot yet begin
- stale `ready` tasks should be reviewed for dependency or planning problems

### 3. Start work

When work begins:

1. Confirm all dependency tasks carry `status:done` (Gate T-2).
2. Assign yourself to the GitHub Issue.
3. Create the branch, named `<task-id>-<short-slug>` (e.g., `t-03-add-auth`).
4. Move the tracker record to `in_progress` (Gate T-3).
5. Add the branch name to the issue body.
6. Add a short execution note if there is relevant context for handoff.

Do not start work without completing all steps. Untracked in-progress work is
invisible to the team and to agents resuming the work.

Each commit must reference the task ID in its message:

```
feat: implement user model (T-12)
```

If the task reveals a material change in design or scope, stop and follow the
scope change protocol before continuing.

### 4. Report blockers immediately

When progress stops, move the task to `blocked` and add a comment documenting
(Gate T-4):

- the blocking condition
- what is needed to unblock
- who owns the next decision or action, if known
- who has been notified
- the date the blocker was identified

Blocked work must not remain silently in `in_progress`. Stop and do not
accumulate partial changes while blocked.

If a blocker lasts more than one working day, escalate it at the next team
review or equivalent coordination point.

When the blocker is resolved, add a resolution comment documenting what
changed, then return the task to `in_progress`.

### 5. Open review

When implementation is ready for review (Gate T-5):

1. Open a pull request from the task branch to the main integration branch.
2. The PR description must include:
   - link to the GitHub Issue
   - link to `spec.md` and the relevant acceptance criteria
   - link to `plan.md`
   - link to the specific task in `tasks.md`
   - summary of what was implemented
   - validation evidence available so far (test output, screenshots, logs)
   - any deviation from the plan and its justification
3. Link the PR from the tracker record.
4. Move the task to `in_review`.

A PR that cannot be traced to an approved spec and plan task will be returned
for clarification before review begins. If review finds that the change exceeds
task scope, the task returns to planning or is split into additional approved
tasks.

### 6. Close on evidence

A task moves to `done` only when (Gate T-6):

- the PR is merged
- all acceptance criteria in the issue are checked off
- required tests are complete and passing in CI
- required screenshots, logs, rollout notes, or manual checks are attached or
  linked
- the tracker record references the merged PR

`done` means complete and evidenced, not nearly complete.

## Agent Execution Protocol

Agent-run work requires stronger resumability than human-only work. For any
task where an agent materially advances work, encounters uncertainty, or leaves
work partially complete, the tracker must include an `## Execution Log` section
in the issue body with entries sufficient for a human or another agent to
resume safely.

Each log entry should capture:

- timestamp
- action taken
- outcome (success, failure, partial)
- relevant files or commands
- next step or handoff instruction

This requirement is proportional. Routine, low-risk tasks do not require a
verbose transcript. Complex, blocked, or partially completed tasks do.

At the start of each session, an agent must report the current state of the
relevant GitHub Issues and identify the target task before beginning work.

Agents must not resolve architectural or product ambiguity autonomously. If a
task requires a new architectural decision, work must pause until the ADR or
planning artifacts are updated. When an agent encounters a blocker, it
documents the blocker in the issue, transitions to `status:blocked`, stops
work, and surfaces the blocker to a human reviewer.

An agent that completes a task updates issue state identically to a human
developer: attach validation evidence, verify acceptance criteria, and move the
label to `status:done` after merge.

## Scope Change Rules

If execution reveals work outside the approved task:

1. Stop expanding scope.
2. Document the discovery in the tracker record.
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

The exact evidence required is defined in `plan.md`. The tracker records where
the evidence lives and confirms that it exists.

At the end of each user story phase, verify that the increment is functional
and stable before moving to the next independent story. Do not carry forward
unverified state.

## Operating Cadence

| Trigger | Action |
| --- | --- |
| Planning approval | Create tracker records from `tasks.md` |
| Daily | Update any task whose status, blockers, or evidence changed |
| Blocker discovered | Update the issue immediately |
| PR opened | Move the task to `in_review` |
| PR merged | Move the task to `done` and attach final evidence |
| Weekly | Review blocked tasks, stale `in_progress` work, and dependency flow |

A stale task is any `in_progress` task with no meaningful update in two working
days. Stale tasks are reviewed at the weekly cadence and either unblocked or
escalated.

## WIP Limits

To reduce half-finished work and context fragmentation:

- each owner should have one primary `in_progress` task by default
- a second active task requires an explicit reason documented in both issues
- blocked work is not automatic permission to start unlimited replacement work
- finish `in_review` work before pulling more `ready` work when possible

The goal is flow completion, not apparent activity.

## Tooling

### GitHub Issues

Issues are the canonical location for live execution state. Run
`/speckit.taskstoissues` to create one issue per task after planning is
approved.

Use the following label taxonomy consistently across all tracked work.

**Status labels** — exactly one applies to every active issue:

| Label | Meaning |
| --- | --- |
| `status:ready` | Dependencies met, unassigned |
| `status:in-progress` | Actively being worked |
| `status:blocked` | Blocked; blocker documented in issue body |
| `status:in-review` | PR open, awaiting review or validation |
| `status:done` | Merged and verified |

**Type labels** — describes the nature of the work:

| Label | Meaning |
| --- | --- |
| `type:feature` | New user-visible behavior |
| `type:bug` | Defect fix |
| `type:refactor` | Internal restructuring, no behavior change |
| `type:chore` | Dependency, tooling, or infrastructure work |

**Priority labels** — used to sequence work across features:

| Label | Meaning |
| --- | --- |
| `priority:p1` | MVP; must ship before any P2 work begins |
| `priority:p2` | High value; ships after MVP is verified |
| `priority:p3` | Nice to have; ships after P2 is verified |

### GitHub Project board

Use a GitHub Project in kanban view, filtered by feature label, to visualize
task flow across states. Project board columns should mirror the state model.
The board reflects tracker state — it does not define a separate workflow.

### Portability

The state model and process are portable to other tracker systems if they
support explicit states, assignment, comments, links to branches and PRs, and
evidence attachment or linking.

## Adoption Notes

This process does not update `tasks.md` as the live execution tracker. That
pattern is attractive because it is simple for a single developer working
locally, but it creates collaboration and synchronization problems once work is
shared across people, agents, branches, and reviews. GitHub Issues remain the
canonical execution record.

This process also applies its stronger controls proportionally. The agent
execution log, traceability requirements, and gate rules exist where they
materially improve handoff quality and review confidence. They are not applied
uniformly at the same level of formality to every routine task.

If this process is adopted as the repository standard, it should be captured in
an ADR, because it defines a significant workflow choice governing how all work
is executed and governed.

## Conclusion

The process is a deliberate synthesis:

- planning artifacts define approved work
- tracker records hold live execution state
- pull requests carry implementation and review discussion
- evidence closes the loop between plan and delivery

The gate rules enforce the conditions for each transition. The label taxonomy
makes state visible and queryable. The proportional agent protocol keeps
auditability requirements practical rather than ceremonial.
