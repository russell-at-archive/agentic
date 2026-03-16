# Task Tracking Process (Linear-First Proposal)

## Purpose

This document realigns task tracking for Archive Agentic around Linear as the
system of record for execution status.

The intent is a process that is:

- simple enough to use consistently
- rigorous enough to preserve traceability and execution quality
- explicit enough for both human developers and AI agents to collaborate safely

The guiding principle is that planning and execution are distinct. Planning
artifacts define approved work. Linear records live execution.

## Process Summary

1. Use `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts.
2. Use one Linear issue per approved task as the live execution record.
3. Move each task through the expanded Linear state model:
   `Draft` -> `Planning` -> `Plan Review` -> `Backlog` -> `Selected` ->
   `In Progress` -> `In Review` -> `Done`, with `Blocked` as an interruption
   state from active execution states.
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
| `tasks.md` | Defines approved implementation task breakdown and dependencies |
| Linear issue | Holds live state, ownership, blockers, branch, PR, and evidence links |
| Pull request | Holds implementation diff and review discussion |

Governing rule:

- if execution status changes, update Linear
- if scope, design, acceptance criteria, or sequencing changes, update planning
  artifacts first

## Source of Truth Model

This process uses a split source-of-truth model:

- `tasks.md` is the source of truth for approved task decomposition
- Linear is the source of truth for live execution state

After tasks are promoted into Linear, `tasks.md` should not be edited for
routine execution progress. Update it only when planning changes.

## Task Unit and Mapping

The default execution unit is one task from `tasks.md`.

Each task maps to:

- one task identifier in `tasks.md`
- one Linear issue
- one branch
- one pull request

Exceptions are allowed only when they improve clarity rather than reduce it:

- a very small follow-up may share a PR if review scope remains clear
- a large task may be split, but planning artifacts must be updated first

## Task Definition Requirements

Before a task becomes executable, it must have enough detail to avoid
implementation ambiguity.

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match `tasks.md` (for example, `T-01`) |
| Title | Yes | One-line imperative outcome |
| Objective | Yes | Two to five sentences of purpose |
| Dependencies | Yes | Upstream task IDs or external prerequisites |
| Acceptance criteria | Yes | Numbered list of verifiable outcomes |
| Files or scope area | Yes | Likely code paths or subsystems |
| Required tests | Yes | Validation expectations |
| Non-goals | Yes | Explicit scope boundaries |

## Linear Issue Schema

Each execution issue in Linear should contain:

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match planning artifact |
| Title | Yes | Same outcome as planned task |
| State | Yes | Must use the standard state model |
| Assignee | Yes | Exactly one directly responsible owner |
| Project | Yes | Feature or initiative container |
| Team | Yes | Owning engineering team |
| Priority | Yes | Sequencing signal |
| Parent links | Yes | Links to `spec.md`, `plan.md`, and `tasks.md` |
| Dependencies | Yes | Linked blocking issues |
| Branch | When started | Branch implementing the task |
| Pull request | When opened | PR URL |
| Validation evidence | Before `Done` | Tests, screenshots, logs, rollout proof |
| Last meaningful update | Yes | Most recent real status change |
| Execution notes | For agent-run or complex work | Resume context and handoff trail |

Optional fields:

- Cycle
- Estimate
- Milestone
- Subsystem labels
- Risk level

## State Model

Use these exact workflow states in Linear:

| State | Meaning | Exit condition |
| --- | --- | --- |
| `Draft` | Initial intake; not yet shaped into implementation work | Ticket is refined for planning |
| `Planning` | Being mapped to spec/plan/tasks artifacts | Planning work is complete and submitted for review |
| `Plan Review` | Plan quality and scope are under review | Plan is accepted or sent back to planning |
| `Backlog` | Approved work, not yet selected for execution | Prioritized into active queue |
| `Selected` | Approved and startable execution task | Owner begins work |
| `In Progress` | Actively being implemented | Blocked, ready for review, or complete |
| `Blocked` | Cannot proceed due to specific blocker | Blocker resolved |
| `In Review` | PR open and awaiting review or validation | Review complete |
| `Done` | PR merged and evidence attached | None |

State transition rules:

- `Draft` -> `Planning`: ticket is accepted for planning.
- `Planning` -> `Plan Review`: planning artifacts are ready for review.
- `Plan Review` -> `Planning`: plan changes are requested.
- `Plan Review` -> `Backlog`: plan is approved and task is queued.
- `Backlog` -> `Selected`: task is prioritized for active execution.
- `Selected` -> `In Progress`: owner claims task and opens branch.
- `In Progress` -> `Blocked`: blocker identified and documented.
- `Blocked` -> `In Progress`: blocker resolved with resolution note.
- `In Progress` -> `In Review`: PR opened with traceability links.
- `In Review` -> `In Progress`: review finds defects.
- `In Review` -> `Done`: review passes, criteria verified, evidence linked,
  PR merged.

A task may not move from `Blocked` directly to `Done`.

## Gate Rules

These gates are required for each transition.

| Gate | Condition |
| --- | --- |
| T-1 | Planning artifacts are approved before creating Linear issues |
| T-2 | Dependencies are `Done` before issue enters `Selected` |
| T-3 | Branch exists and issue is updated before coding starts |
| T-4 | Blocker is explicitly documented before issue enters `Blocked` |
| T-5 | PR links to spec, plan, and task before entering `In Review` |
| T-6 | Acceptance criteria verified and evidence linked before `Done` |

## Workflow

### 1. Create Linear issues from `tasks.md`

After planning approval, create one Linear issue per task.

Issue title format:

```text
[T-##] [Feature Name] Short task description
```

Include execution-relevant metadata only: task ID, dependencies, planning links,
acceptance criteria summary, required tests summary, and scope notes.

### 2. Keep the queue truly `Selected`

A task should be `Selected` only when it is startable now.

- unresolved dependencies keep it out of `Selected`
- ownership should not reserve work that cannot start
- stale `Selected` tasks should be reviewed for planning or dependency problems

### 3. Start work

When work begins:

1. Confirm all dependency issues are `Done`.
2. Assign the Linear issue to one owner.
3. Create branch `<task-id>-<short-slug>`.
4. Move issue to `In Progress`.
5. Add branch name and current execution note to the issue.

Each commit should reference the task ID.

```text
feat: implement user model (T-12)
```

### 4. Report blockers immediately

When blocked, move issue to `Blocked` and document:

- blocking condition
- what is needed to unblock
- owner of next decision or action
- who was notified
- date identified

When resolved, add a resolution note and move back to `In Progress`.

### 5. Open review

When implementation is ready:

1. Open a PR.
2. Include links to Linear issue, `spec.md`, `plan.md`, and task entry.
3. Add validation evidence available so far.
4. Link PR back to Linear issue.
5. Move issue to `In Review`.

### 6. Close on evidence

Move issue to `Done` only when:

- PR is merged
- acceptance criteria are checked off
- required tests pass
- required evidence is attached or linked
- issue references merged PR

## Agent Execution Protocol

For agent-run work, use an `Execution Log` section in the Linear issue
description or comments when work is complex, blocked, or partially complete.

Each entry should capture:

- timestamp
- action taken
- outcome (success, failure, partial)
- relevant files or commands
- next step or handoff instruction

Agents must not resolve architectural or product ambiguity autonomously. If a
new architectural decision is required, pause work until an ADR exists or is
updated.

## Scope Change Rules

If execution reveals work outside approved scope:

1. Stop scope expansion.
2. Record the discovery in the Linear issue.
3. Determine impact on scope, design, acceptance criteria, or sequencing.
4. If architectural impact exists, create or update an ADR before proceeding.
5. Update planning artifacts and task breakdown as needed.
6. Resume only after revised work is approved.

## Validation and Evidence

Every task closes with explicit evidence, such as:

- automated test results
- manual verification notes
- screenshots or recordings
- migration output
- rollout confirmation
- monitoring checks

The required evidence type is defined in `plan.md`. Linear records where that
proof is stored.

## Operating Cadence

| Trigger | Action |
| --- | --- |
| Planning approval | Create Linear issues from `tasks.md` |
| Daily | Update any issue with real status, blocker, or evidence changes |
| Blocker discovered | Update issue immediately and move to `Blocked` |
| PR opened | Move issue to `In Review` |
| PR merged | Move issue to `Done` and attach final evidence |
| Weekly | Review blocked and stale `In Progress` issues |

A stale issue is any `In Progress` issue with no meaningful update in two
working days.

## Tooling in Linear

### Issues

Linear issues are the canonical location for live execution state.

Recommended labels:

- `type:feature`
- `type:bug`
- `type:refactor`
- `type:chore`

### Projects and Cycles

- Use Linear Projects for feature-level grouping and progress rollup.
- Use Cycles for team-level scheduling where appropriate.
- Keep workflow state on issues, not in custom ad hoc labels.

### Views

Create shared views for:

- `My In Progress`
- `Blocked`
- `Selected by Priority`
- `In Review`
- `Done This Cycle`

## Adoption Notes

This proposal replaces GitHub Issues as the execution tracker with Linear.
GitHub remains the code review system of record through pull requests.

If adopted as repository standard, record this workflow decision in an ADR.

## Conclusion

The execution model remains the same while the tracker changes:

- planning artifacts define approved work
- Linear holds live execution state
- pull requests hold implementation and review discussion
- evidence closes the loop between plan and delivery
