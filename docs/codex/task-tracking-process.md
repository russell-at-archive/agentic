# Task Tracking Process Proposal

## Purpose

This proposal defines how work should be tracked after planning is complete in
a spec-driven development workflow.

Planning answers what should be built and how it should be built. Task tracking
answers what is actively being executed, what is blocked, what is under review,
and what evidence shows a task is done.

The goal is to make execution status visible without turning the tracker into a
second planning system.

## Core Principles

- Track execution, not ideation.
- Only track work that has an approved planning artifact.
- Keep the task tracker tightly linked to `spec.md`, `plan.md`, and `tasks.md`.
- Use one tracked task as the default unit of execution.
- Default to one task per branch and pull request.
- Make blocked work visible immediately.
- Require completion evidence, not status-only updates.
- Prefer a small number of durable states over custom workflow variants.

## Scope

This process starts after the planning process has produced:

- an approved `spec.md`
- an approved `plan.md`
- a sequenced `tasks.md`

This process ends when the tracked task is merged and the task record is closed
with links to the validation evidence.

## Separation of Responsibilities

| Artifact | Purpose |
| --- | --- |
| `spec.md` | Defines required behavior, scope, and acceptance criteria |
| `plan.md` | Defines engineering approach, constraints, and validation strategy |
| `tasks.md` | Defines the ordered implementation tasks |
| Issue tracker | Shows execution state, ownership, blockers, and links to delivery evidence |
| Pull request | Shows the concrete implementation for one task |

Rule:

- If a detail changes execution status, it belongs in the issue tracker.
- If a detail changes scope, behavior, design, or sequencing, it belongs in the
  planning artifacts first.

## Recommended Unit of Tracking

The default tracked item is one implementation task from `tasks.md`.

Each tracked task should map to:

- one task identifier in `tasks.md`
- one issue or tracker card
- one branch
- one pull request

Allowed exceptions:

- a tiny follow-up task may be grouped into the same pull request if it cannot
  stand on its own and does not change review scope
- a large task may be split into child tasks, but the plan must be updated
  first so the tracker reflects approved work instead of ad hoc execution

## Tracker Schema

Each tracked task should contain the following fields.

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match the identifier in `tasks.md` |
| Title | Yes | Short action-oriented summary |
| Status | Yes | Must use the standard state model in this document |
| Owner | Yes | Single directly responsible engineer or agent |
| Parent spec | Yes | Link to the relevant `spec.md` |
| Parent plan | Yes | Link to the relevant `plan.md` |
| Parent task list | Yes | Link to the relevant `tasks.md` |
| Dependencies | Yes | Upstream tasks or external blockers |
| Branch | When started | Branch implementing the task |
| Pull request | When opened | PR for the task |
| Validation evidence | Before done | Tests, screenshots, logs, or rollout proof |
| Last meaningful update | Yes | Date of the last real status change |

Optional fields:

- target milestone or release
- reviewer
- risk level
- service or subsystem label

## State Model

Use the same status values for all tracked work.

| State | Meaning | Exit Condition |
| --- | --- | --- |
| `ready` | Approved task is available to start | Owner begins execution |
| `in_progress` | Task is actively being implemented | PR opened, blocked, or work completed |
| `blocked` | Work cannot proceed because of a specific blocker | Blocker removed and task resumes |
| `in_review` | Implementation is in pull request review or awaiting validation | Review and validation complete |
| `done` | Code is merged and completion evidence is attached | None |

States not allowed:

- `todo`
- `backlog`
- `qa`
- `done pending`
- custom team-specific states for the same workflow step

Those states are excluded to keep the tracker small and to avoid mixing intake,
sprint management, and execution tracking into one board.

## Entry Criteria

A task may enter the tracker only if all of the following are true:

- the task exists in `tasks.md`
- any required dependency tasks are identified
- the parent spec and plan are approved
- the task has explicit completion criteria
- the task has an owner or an explicit unassigned state in the queue

If one of these is missing, the work is not ready for tracking. It should
return to planning instead of being added as fuzzy execution work.

## Workflow

### 1. Create Tracking Records from `tasks.md`

When `tasks.md` is approved, create one issue or card per task. Copy only the
minimum execution metadata:

- task ID and title
- dependency references
- parent artifact links
- completion criteria summary
- required tests summary

Do not copy the full plan into the tracker.

### 2. Keep the Queue in `ready`

Only tasks with cleared prerequisites should sit in `ready`.

If a dependency is unresolved, the task stays unstarted but linked to the
upstream dependency. Do not move it to `in_progress` just to reserve ownership.

### 3. Start Work

When implementation begins:

- assign the task to one owner
- create the branch
- move the task to `in_progress`
- add a brief execution note if the branch or approach differs in a minor way
  from expectation

If the task reveals a material change in design or scope, stop and update the
planning artifacts before continuing.

### 4. Surface Blockers Immediately

A blocked task must include:

- the blocking condition
- the blocker owner, if known
- the next decision or action required
- the date the task became blocked

Blocked tasks should never remain in `in_progress` without a written blocker.

### 5. Open Review

When a pull request is opened:

- link the PR in the task record
- move the task to `in_review`
- attach the validation evidence available so far

If review finds that the change exceeds task scope, the task should move back
to planning or be split into additional approved tasks.

### 6. Close on Evidence

A task moves to `done` only when:

- the pull request is merged
- planned validation is complete
- any required screenshots, logs, or rollout notes are attached or linked
- the tracker record references the merged PR

`done` means complete, not nearly complete.

## Rules for Blocked and Changed Work

- If a blocker lasts more than one working day, escalate it in the next team
  review.
- If the task needs a new architectural decision, create or update the ADR
  before continuing.
- If acceptance criteria change, update the spec first.
- If sequencing changes, update `tasks.md` first.
- If a task repeatedly reopens, the completion criteria were likely too vague
  and should be corrected in the planning artifacts.

## Cadence

Use the following operating rhythm:

- On task creation: create the full set of tracking records from `tasks.md`
- Daily: update any task whose status, blocker state, or evidence changed
- On PR open: move the task to `in_review`
- On merge: move the task to `done` and attach final evidence
- Weekly: review blocked tasks, stale `in_progress` tasks, and dependency flow

A stale task is any task with no meaningful update in two working days.

## WIP Limits

To reduce drift and half-finished work:

- each owner should have one primary `in_progress` task by default
- opening a second active task should require an explicit reason
- blocked work does not justify starting unlimited replacement work
- prioritize finishing `in_review` work before starting new `ready` work

The tracker should optimize for flow completion, not apparent activity.

## Completion Evidence

Every completed task should link to the evidence that proves it met the plan.

Examples:

- automated test results
- manual verification notes
- screenshots or recordings
- migration output
- rollout confirmation
- monitoring or alert checks

The exact evidence should come from `plan.md`. The tracker records that the
evidence exists and where to find it.

## Metrics That Matter

The tracker should support a small set of operational metrics:

- lead time from `ready` to `done`
- review time from `in_review` to `done`
- blocker count and blocker age
- stale `in_progress` task count
- completion rate by milestone or release

Metrics to avoid:

- raw issue count
- status churn without delivery context
- individual activity measures based on comment volume or task touches

## Anti-Patterns

- Creating tracker items before planning approval
- Letting the issue tracker become a second spec or design document
- Tracking vague epics instead of executable tasks
- Marking tasks `in_progress` before real implementation begins
- Leaving blocked tasks without an explicit blocker note
- Closing tasks when code is open in review but not merged
- Creating new execution work in the tracker without updating `tasks.md`

## Recommended Rollout

1. Adopt this process for one planned feature first.
1. Create tracker issues directly from approved `tasks.md`.
1. Require every PR to reference exactly one task unless an approved exception
   exists.
1. Review blocked and stale tasks weekly for one month.
1. Adjust templates and automation only after the manual workflow is stable.

## Proposed Standard

The recommended standard for this repository is:

- planning remains in repository artifacts
- execution state lives in the issue tracker
- one approved task maps to one tracked item by default
- one tracked item maps to one branch and one PR by default
- `done` requires merge plus validation evidence
- changes to scope or design go back to planning, not sideways into task
  comments

This keeps planning durable, execution visible, and status reporting lightweight
enough to stay accurate.
