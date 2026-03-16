# Unified Task Tracking Proposal (Linear-First)

## Purpose

Define a single tracking process for Archive Agentic where Linear is the
authoritative system of record for task lifecycle and execution status.

This proposal preserves a strict separation:

- planning artifacts define approved work
- Linear issues define live execution state
- pull requests define implementation and review outcomes

## Source of Truth Model

- `spec.md`, `plan.md`, and `tasks.md`: approved planning artifacts
- Linear issues: canonical execution state and coordination
- GitHub/Graphite pull requests: implementation and review record

`tasks.md` is not a live status board. Once issues are created, execution status
changes are recorded in Linear only.

## Agent Team and Responsibilities

| Agent | Primary responsibility | Expected entry state |
| --- | --- | --- |
| Director | Monitors Linear and dispatches work to specialist agents | Any |
| Architect | Produces planning artifacts and plan PR | `Draft` |
| Coordinator | Creates task-level issues from approved plans | `Backlog` |
| Engineer | Implements tasks using branch/worktree and stacked PRs | `Selected` |
| Technical Lead | Reviews PRs and drives review closure | `In Review` |
| Explorer | Performs research and produces sourced inputs | On demand |

Agents should only act when the issue is in their expected entry state.

## Linear Workflow States

Use the following states exactly:

| State | Meaning | Exit condition |
| --- | --- | --- |
| `Draft` | Intake state for new feature/work item | Assigned for planning |
| `Planning` | `spec.md`, `plan.md`, `tasks.md` are being produced | Plan PR opened |
| `Plan Review` | Planning PR under review | Approved to backlog or returned to planning |
| `Backlog` | Approved work awaiting scheduling and dependency readiness | Promoted to selected queue |
| `Selected` | Ready-to-start execution task | Owner starts implementation |
| `In Progress` | Active implementation | Review-ready or blocked |
| `Blocked` | Work halted due to explicit blocker | Blocker resolved |
| `In Review` | PR open and under review | Approved and merged or returned to implementation |
| `Done` | Merged and evidenced completion | Final |

`Blocked` is returnable and may be entered from active states. A blocked issue
must return to its prior active state after unblock.

## Required Linear Issue Fields

Each execution issue should include:

- Task ID (matches `tasks.md`)
- clear title
- state
- assignee
- project
- priority
- dependencies
- links to `spec.md`, `plan.md`, and `tasks.md`
- branch (once started)
- PR link (once opened)
- validation evidence links (before `Done`)
- latest meaningful update

## Transition Gates

| Gate | Transition | Condition |
| --- | --- | --- |
| T-1 | `Draft` -> `Planning` | Objective is clear and Architect assigned |
| T-2 | `Planning` -> `Plan Review` | `spec.md`, `plan.md`, `tasks.md` complete; `/speckit.analyze` passes |
| T-3 | `Plan Review` -> `Backlog` | Planning PR approved and merged |
| T-4 | `Backlog` -> `Selected` | Task issue exists and all dependencies are `Done` |
| T-5 | `Selected` -> `In Progress` | Owner assigned, branch/worktree created, issue updated |
| T-6 | `In Progress` -> `Blocked` | Blocker documented with owner and unblock condition |
| T-7 | `In Progress` -> `In Review` | PR opened with links to issue/spec/plan/task |
| T-8 | `In Review` -> `Done` | PR merged, acceptance criteria checked, evidence attached |

## Operating Workflow

### 1. Plan

1. Feature enters `Draft`.
2. Architect moves to `Planning` and produces planning artifacts.
3. Architect opens planning PR and moves issue to `Plan Review`.
4. On approval/merge, issue moves to `Backlog`.

### 2. Schedule

1. Coordinator creates one Linear issue per task in `tasks.md`.
2. Issues with complete dependencies move to `Selected`.
3. Remaining issues stay in `Backlog` until dependencies complete.

### 3. Implement

1. Engineer claims a `Selected` issue.
2. Creates worktree and branch `<task-id>-<slug>`.
3. Moves issue to `In Progress` and records branch.
4. Implements via focused commits and Graphite stacked PRs when needed.

### 4. Review

1. Engineer opens PR and links issue + planning artifacts.
2. Issue moves to `In Review`.
3. Technical Lead reviews and either:
   - returns issue to `In Progress` for changes
   - approves and merges

### 5. Close

1. Attach or link validation evidence in Linear.
2. Confirm acceptance criteria completion.
3. Move issue to `Done`.

## Blocker Protocol

When blocked:

1. Move issue to `Blocked` immediately.
2. Record blocker details:
   - blocking condition
   - unblock requirement
   - responsible resolver
   - notification/escalation owner
   - date identified
3. Stop forward work on that issue until unblocked.
4. On resolution, add a resolution note and return to prior state.

## Scope Change Protocol

If work exceeds approved task scope:

1. Stop scope expansion.
2. Document variance in Linear.
3. Route back to planning if scope, sequencing, or acceptance criteria change.
4. If architectural impact exists, create or update an ADR before proceeding.
5. Resume only after updated plan/tasks are approved.

## Evidence and Definition of Done

An issue is `Done` only when all are true:

- PR merged
- acceptance criteria checked
- required tests passing
- required evidence attached/linked (logs, screenshots, notes, rollout proof)
- Linear issue links to final PR and evidence

## Cadence and Flow Controls

- Daily: update issues with meaningful state, blocker, or evidence changes
- Weekly: review blocked and stale `In Progress` issues
- Stale threshold: no meaningful update for two working days
- WIP guideline: one primary `In Progress` issue per assignee

## Tooling Guidance

- Linear: lifecycle state, dependencies, assignee, and execution record
- GitHub Speckit: planning artifacts and consistency checks
- Graphite: stacked PR workflow for incremental review
- GitHub: code hosting and merge system of record

## Adoption

This document is a proposal for standardization. Final adoption should be
recorded in an ADR before being treated as mandatory repository process.
