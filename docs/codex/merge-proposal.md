# Unified Task Tracking Process

## Purpose

This document proposes a single task-tracking process that merges the strongest
aspects of the existing Codex, Claude, and Gemini proposals into one cohesive
approach.

The intent is to create a process that is:

- simple enough to use consistently
- rigorous enough to preserve traceability and execution quality
- explicit enough for both human developers and AI agents to collaborate safely

The guiding principle is that planning and execution are distinct. Planning
artifacts define approved work. Task tracking records the live execution of that
work.

## Process Summary

The unified approach is:

1. Use `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts.
2. Use one GitHub Issue or equivalent tracker item per approved task as the
   live execution record.
3. Use a compact shared state model:
   `ready`, `in_progress`, `blocked`, `in_review`, `done`.
4. Require explicit ownership, blocker handling, traceability, and completion
   evidence.
5. Require agents to leave resumable execution notes when they materially
   advance or block a task.

This keeps the process operationally strong without turning task tracking into a
second planning system.

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
| GitHub Issue or tracker card | Holds live execution state, ownership, blockers, branch, PR, and evidence |
| Pull request | Holds the concrete implementation and review discussion |

The governing rule is:

- if something changes execution status, it belongs in the issue tracker
- if something changes scope, design, acceptance criteria, or sequencing, it
  belongs in planning artifacts first

## Source of Truth Model

This merged process adopts a split source-of-truth model:

- `tasks.md` is the source of truth for approved task decomposition
- GitHub Issues are the source of truth for live execution state

This preserves Gemini's useful clarity around structured task definitions while
avoiding the dual-write problem created by updating both `tasks.md` and GitHub
Issues during execution.

After tasks are promoted into tracker records, `tasks.md` should not be edited
to reflect day-to-day execution progress. It should change only if planning
changes.

## Task Unit and Mapping

The default execution unit is one task from `tasks.md`.

Each task should map to:

- one task identifier in `tasks.md`
- one GitHub Issue or equivalent tracker record
- one branch
- one pull request

Exceptions are allowed only when they improve clarity rather than reduce it:

- a very small follow-up may share a PR if review scope remains clear
- a large task may be split, but `tasks.md` and related planning artifacts must
  be updated first

## Task Definition Requirements

Before a task becomes executable, it should already have enough planning detail
to prevent avoidable ambiguity. The task definition should include:

| Field | Required | Notes |
| --- | --- | --- |
| Task ID | Yes | Must match `tasks.md` |
| Title | Yes | Short action-oriented outcome |
| Objective | Yes | Why the task exists |
| Dependencies | Yes | Upstream tasks or external prerequisites |
| Acceptance criteria | Yes | Verifiable outcomes |
| Files or scope area | Yes | Likely code paths or subsystems |
| Required tests | Yes | Validation expectations |
| Non-goals | Yes | Explicit scope boundaries |

This keeps Gemini's practical task readability while adopting Claude's stronger
task anatomy.

## Tracker Schema

Each live tracker record should contain:

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
- priority

## State Model

Use the same status values for all live execution work.

| State | Meaning | Typical Exit Condition |
| --- | --- | --- |
| `ready` | Approved task is available to start | Owner begins work |
| `in_progress` | Task is actively being implemented | Work blocks, PR opens, or implementation completes |
| `blocked` | Work cannot proceed because of a specific blocker | Blocker is resolved and work resumes |
| `in_review` | PR is open and awaiting review or final validation | Review and validation complete |
| `done` | PR is merged and required evidence is attached | None |

This keeps Codex's compact state model and rejects the larger workflow tax that
comes from duplicative or ambiguous states.

`backlog` may exist at the portfolio or planning-board level, but it is not
required as part of the live execution workflow for approved tasks.

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

## 1. Create Tracker Records from `tasks.md`

Once planning is approved, create one issue or tracker card per task. Each
record should copy only the execution-relevant metadata:

- task ID and title
- dependencies
- artifact links
- acceptance criteria summary
- required tests summary
- scope notes and non-goals

Do not copy the full plan into the issue. The issue should reference planning,
not duplicate it.

## 2. Keep the Queue in `ready`

A task should sit in `ready` only when it is actually startable.

- unresolved dependencies keep a task out of active work
- ownership should not be used to reserve work that cannot yet begin
- stale `ready` tasks should be reviewed for dependency or planning problems

## 3. Start Work

When work begins:

1. confirm dependencies are satisfied
2. assign the task to one owner
3. create the branch
4. move the tracker record to `in_progress`
5. add the branch name to the issue
6. add a short execution note if there is relevant context for handoff

Branch naming should include the task ID and a short slug, for example:
`t-03-add-auth`.

## 4. Report Blockers Immediately

When progress stops, the task must move to `blocked` and include:

- the blocking condition
- what is needed to unblock
- who owns the next decision or action, if known
- who has been notified
- the date the blocker was identified

Blocked work should not remain silently in `in_progress`.

If a blocker lasts more than one working day, it should be escalated in the
next team review or equivalent coordination point.

## 5. Open Review

When implementation is ready for review:

1. open a pull request
2. link the PR from the tracker record
3. move the task to `in_review`
4. attach the validation evidence available so far

The PR description should include:

- link to the tracker issue
- link to `spec.md`
- link to `plan.md`
- link to the relevant task in `tasks.md`
- summary of what was implemented
- test evidence
- any deviation from the plan and its justification

This adopts Claude's strong traceability requirements without requiring a
separate heavyweight review process.

## 6. Close on Evidence

A task moves to `done` only when:

- the PR is merged
- acceptance criteria are verified
- required tests are complete and passing
- required screenshots, logs, rollout notes, or manual checks are attached or
  linked
- the tracker record references the merged PR

`done` means complete and evidenced, not nearly complete.

## Agent Execution Protocol

Agent-run work needs stronger resumability than human-only work. For any task
where an agent materially advances work, encounters uncertainty, or leaves work
partially complete, the tracker should include execution notes sufficient for a
human or another agent to resume safely.

Execution notes should capture:

- timestamp
- action taken
- outcome
- relevant files or commands
- next step or handoff instruction

This borrows Claude's auditability requirement, but applies it proportionally.
Routine, low-risk tasks do not need a verbose transcript. Complex, blocked, or
partially completed tasks do.

Agents must not resolve architectural or product ambiguity autonomously. If a
task requires a new architectural decision, the work must pause until the ADR
or planning artifacts are updated.

## Scope Change Rules

If execution reveals work outside the approved task:

1. stop expanding scope
2. document the discovery in the tracker record
3. determine whether the change affects scope, design, acceptance criteria, or
   sequencing
4. update the relevant planning artifact first
5. create or revise tasks as needed
6. resume execution only once the work is approved again

This is one of the most important protections in the merged process. Silent
scope expansion weakens planning, review, and delivery predictability.

## Validation and Evidence

Every task should close with explicit evidence that it met the plan. Evidence
may include:

- automated test results
- manual verification notes
- screenshots or recordings
- migration output
- rollout confirmation
- monitoring or alert checks

The exact evidence should be driven by `plan.md`. The tracker records where the
evidence lives and confirms that it exists.

## Operating Cadence

Use the following cadence:

- on planning approval: create tracker records from `tasks.md`
- daily: update tasks whose status, blockers, or evidence changed
- on blocker discovery: update immediately
- on PR open: move to `in_review`
- on merge: move to `done` and attach final evidence
- weekly: review blocked tasks, stale `in_progress` work, and dependency flow

A stale task is any `in_progress` task with no meaningful update in two working
days.

## WIP Limits

To reduce half-finished work and context fragmentation:

- each owner should have one primary `in_progress` task by default
- a second active task should require an explicit reason
- blocked work is not automatic permission to start unlimited replacement work
- finish `in_review` work before pulling more `ready` work when possible

This preserves Codex's flow-oriented discipline while staying lightweight.

## Tooling Guidance

The merged process assumes GitHub Issues, but the model is portable to other
tracker systems if they support:

- explicit states
- assignment
- comments
- links to branches and PRs
- evidence attachment or linking

If GitHub is used, labels should reflect the standard state model and optional
task attributes such as type, priority, or subsystem.

Project boards may be used for visibility, but they should reflect tracker
state rather than invent a separate workflow.

## Adoption Notes

This unified process intentionally does not adopt Gemini's proposal to update
`tasks.md` as the live execution tracker. That pattern is attractive because it
is simple, but it creates collaboration and synchronization problems once work
is shared across people, agents, branches, and reviews.

It also intentionally does not adopt the full weight of Claude's workflow for
every task. The stronger controls are kept where they materially improve
traceability, handoff quality, and review confidence.

## Conclusion

The merged process is a deliberate synthesis:

- Codex provides the clearest overall execution model
- Claude provides the strongest traceability, blocker handling, and agent
  resumability rules
- Gemini contributes a bias toward readable task definitions and operational
  simplicity

The result is a single thoughtstream:

- planning artifacts define approved work
- tracker records hold live execution state
- pull requests carry implementation and review
- evidence closes the loop

If this process is adopted as the repository standard, it should likely be
captured in an ADR because it defines a significant workflow choice for how work
is executed and governed.
