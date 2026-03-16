# Task Tracking Process (Linear-First Standard)

## Purpose

This document defines the unified task tracking process for Archive Agentic.
Linear is the authoritative system of record for task lifecycle and execution
state.

The process is designed to be:

- traceable from planning through delivery
- operable by both humans and agents
- strict on quality gates and completion evidence
- lightweight enough for day-to-day execution

## Source of Truth

- `spec.md`, `plan.md`, `tasks.md`: approved planning artifacts
- Linear issues: live execution state, ownership, blockers, and handoffs
- Pull requests (GitHub/Graphite): implementation and review record

After task issues are created, execution status must be updated in Linear, not
in `tasks.md`.

## Agent Responsibilities

| Agent | Responsibility | Entry state |
| --- | --- | --- |
| Director | Monitors Linear and dispatches specialist agents | Any |
| Architect | Produces planning artifacts and planning PR | `Draft` |
| Coordinator | Creates task issues from approved planning | `Backlog` |
| Engineer | Implements tasks and opens PRs | `Selected` |
| Technical Lead | Reviews PRs and drives review closure | `In Review` |
| Explorer | Research and analysis support | On demand |

Agents should only act when an issue is in the required entry state.

## Linear Workflow States

Use these states exactly:

| State | Meaning | Exit condition |
| --- | --- | --- |
| `Draft` | New feature/work item intake | Assigned for planning |
| `Planning` | `spec.md`, `plan.md`, `tasks.md` are being prepared | Planning PR opened |
| `Plan Review` | Planning PR is under review | Approved to `Backlog` or returned to `Planning` |
| `Backlog` | Approved work awaiting scheduling | Promoted to `Selected` when ready |
| `Selected` | Ready to start implementation | Owner begins implementation |
| `In Progress` | Active implementation | Moved to `In Review` or `Blocked` |
| `Blocked` | Work paused by explicit blocker | Blocker resolved |
| `In Review` | PR under review | Merged to `Done` or returned to `In Progress` |
| `Done` | Completed, merged, and evidenced | Final |

`Blocked` is a returnable interruption state. On resolution, return to the
prior active state.

## Required Issue Fields

Each execution issue in Linear must include:

- Task ID (matching `tasks.md`)
- Title
- State
- Assignee
- Project
- Priority
- Dependency links
- Links to `spec.md`, `plan.md`, `tasks.md`
- Branch (once work starts)
- PR link (once opened)
- Validation evidence links (before `Done`)
- Latest meaningful update

## Transition Gates

| Gate | Transition | Required condition |
| --- | --- | --- |
| T-1 | `Draft` -> `Planning` | Objective clear and Architect assigned |
| T-2 | `Planning` -> `Plan Review` | Planning artifacts complete and `/speckit.analyze` passes |
| T-3 | `Plan Review` -> `Backlog` | Planning PR approved and merged |
| T-4 | `Backlog` -> `Selected` | Task issue exists and dependencies are `Done` |
| T-5 | `Selected` -> `In Progress` | Owner assigned, branch/worktree created, issue updated |
| T-6 | `In Progress` -> `Blocked` | Blocker documented with resolver and unblock condition |
| T-7 | `In Progress` -> `In Review` | PR opened with links to issue/spec/plan/task |
| T-8 | `In Review` -> `Done` | PR merged, criteria checked, evidence attached |

## Workflow

### 1. Plan

1. Create feature issue in `Draft`.
2. Architect moves issue to `Planning` and produces planning artifacts.
3. Architect opens planning PR and moves issue to `Plan Review`.
4. On approval and merge, move issue to `Backlog`.

### 2. Schedule

1. Coordinator creates one issue per task from `tasks.md`.
2. Move dependency-ready issues to `Selected`.
3. Keep other issues in `Backlog` until dependencies complete.

### 3. Implement

1. Engineer claims a `Selected` issue.
2. Create worktree and branch `<task-id>-<slug>`.
3. Move issue to `In Progress` and record branch.
4. Implement in focused commits and open PR (or stack) for review.

### 4. Review

1. Engineer links PR to issue and planning artifacts.
2. Move issue to `In Review`.
3. Technical Lead reviews.
4. If changes are requested, return issue to `In Progress`.
5. If approved, merge PR.

### 5. Close

1. Attach/link validation evidence.
2. Verify acceptance criteria are complete.
3. Move issue to `Done`.

## Blocker Protocol

When blocked:

1. Move issue to `Blocked` immediately.
2. Document:
   - blocking condition
   - unblock requirement
   - responsible resolver
   - notification/escalation owner
   - date identified
3. Pause forward work on the blocked issue.
4. On resolution, add resolution note and return to prior active state.

## Scope Change Protocol

If execution exceeds approved scope:

1. Stop scope expansion.
2. Document variance in Linear.
3. Return to planning if scope, acceptance criteria, or sequencing changes.
4. If architecture is affected, create or update an ADR before continuing.
5. Resume only after revised planning is approved.

## Definition of Done

Move an issue to `Done` only when all conditions are met:

- PR is merged
- acceptance criteria are checked off
- required tests pass
- required evidence is attached or linked
- Linear issue links to merged PR and evidence

## Cadence and WIP Controls

- Daily: update any issue with meaningful state, blocker, or evidence change
- Weekly: review blocked and stale `In Progress` issues
- Stale threshold: two working days without meaningful update
- WIP guideline: one primary `In Progress` issue per assignee

## Tooling

- Linear: execution tracking and lifecycle state
- GitHub Speckit: planning artifacts and consistency checks
- Graphite: stacked PR submission when needed
- GitHub: source control and merge system of record

## Adoption Note

This process should be ratified in an ADR before being enforced as a mandatory
repository standard.
