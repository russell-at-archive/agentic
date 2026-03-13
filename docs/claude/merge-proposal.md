# Task Tracking Process — Merge Proposal

## Philosophy

Task tracking is the operational layer that sits between planning and delivery.
Planning answers what should be built and how. Task tracking answers what is
actively being executed, what is blocked, what is under review, and what
evidence proves a task is done.

Tracking is not a status-reporting ceremony and it is not a second planning
system. It is a coordination mechanism that prevents duplicate work, surfaces
blockers early, and creates a continuous record of where a feature stands in
its lifecycle. A well-tracked task tells the next person — or agent — who
picks it up exactly what has happened, what remains, and what constraints they
are working under.

AI agents change the tracking calculus. An agent executing a task must leave
an auditable trail sufficient for a human to resume from any point without
re-reading full session history. The tracking process must be designed with
that requirement in mind from the start, not retrofitted after the fact.

---

## Core Principles

- Track execution, not ideation. Only track work that has an approved planning
  artifact.
- Every task has exactly one owner at any point in time.
- Status transitions are explicit, timestamped, and follow the defined state
  model.
- Blockers are surfaced immediately and documented in writing. They are never
  absorbed silently.
- No task is marked done unless acceptance criteria are verified and completion
  evidence is attached.
- Scope changes return to planning. They do not expand silently into the
  current task.
- Agents leave an auditable execution log sufficient for a human to resume at
  any point.
- The canonical task state during execution is the GitHub Issue, not a local
  file.
- Optimize for flow completion, not apparent activity.

---

## Separation of Responsibilities

| Artifact | Purpose |
| --- | --- |
| `spec.md` | Defines required behavior, scope, and acceptance criteria |
| `plan.md` | Defines engineering approach, constraints, and validation strategy |
| `tasks.md` | Defines the ordered implementation tasks — read-only after issues are created |
| GitHub Issues | Show execution state, ownership, blockers, and links to delivery evidence |
| Pull request | Shows the concrete implementation for one task |

Rule: if a detail changes execution status, it belongs in the issue tracker.
If a detail changes scope, behavior, design, or sequencing, it belongs in the
planning artifacts first.

---

## Scope

This process starts after the planning process has produced an approved
`spec.md`, an approved `plan.md`, and a sequenced `tasks.md`. It ends when
all tasks for the feature carry `status:done` and the end-to-end acceptance
scenario passes.

No task may enter `in-progress` before all planning gates are satisfied. No
task may be marked `done` without verified acceptance criteria.

---

## State Model

Each task moves through a defined set of states. Skipping states is not
allowed. Returning to a prior state when a blocker is discovered is required.

| State | Meaning | Exit condition |
| --- | --- | --- |
| `ready` | Dependencies met, task available to start | Owner claims the task |
| `in-progress` | Actively being implemented | PR opened, task blocked, or work completed |
| `blocked` | Cannot proceed without external input | Blocker resolved and documented |
| `in-review` | Pull request open, awaiting review and validation | Review and validation complete |
| `done` | Merged, acceptance criteria verified, evidence attached | None |

States not used in this process: `todo`, `backlog`, `qa`, `done pending`, or
any custom team-specific variant. Pre-execution scheduling and dependency
sequencing are handled by the planning artifacts, not by additional tracker
states.

### State Transition Rules

- `ready` → `in-progress`: Owner claims the task, assigns themselves, and
  opens a branch.
- `in-progress` → `blocked`: A blocker is identified and formally documented.
- `blocked` → `in-progress`: Blocker is resolved and a resolution comment is
  added.
- `in-progress` → `in-review`: Pull request is opened with spec traceability.
- `in-review` → `in-progress`: Review finds defects; assignee addresses them.
- `in-review` → `done`: Review passes, all acceptance criteria verified,
  evidence attached, PR merged.

A task may never move from `blocked` directly to `done`. The blocker must be
resolved and the task must re-enter `in-progress` before it can go to review.

---

## Task Anatomy

Every GitHub Issue must carry the following fields before it enters
`in-progress`.

| Field | Required | Description |
| --- | --- | --- |
| Task ID | Yes | Identifier matching `tasks.md` (e.g., `T-01`) |
| Title | Yes | One-line imperative statement of the outcome |
| Objective | Yes | Two to five sentences explaining the purpose |
| Parent spec | Yes | Link to `spec.md` |
| Parent plan | Yes | Link to `plan.md` |
| Parent task list | Yes | Link to `tasks.md` |
| Dependencies | Yes | Task IDs that must be done before this task can begin |
| Acceptance criteria | Yes | Numbered list of verifiable outcomes |
| Files in scope | Yes | Paths or subsystems likely touched |
| Required tests | Yes | Categories and what each validates |
| Non-goals | Yes | Explicit exclusions to prevent scope creep |
| Assignee | When started | Set when the task moves to `in-progress` |
| Branch | When started | Set when the task moves to `in-progress` |
| PR link | When opened | Set when the task moves to `in-review` |
| Validation evidence | Before done | Tests, screenshots, logs, or rollout confirmation |
| Blockers | When blocked | Populated when the task moves to `blocked` |

---

## Tooling

### `tasks.md` — planning artifact

`tasks.md` is generated by `/speckit.tasks` and lives in
`specs/<###-feature-name>/`. It is the authoritative source during task
decomposition. After `/speckit.analyze` passes and `/speckit.taskstoissues`
runs, `tasks.md` is read-only. Do not update it to reflect execution progress.
GitHub Issues carry live state.

### GitHub Issues — execution state

Issues are the canonical location for current status, assignee, branch and PR
links, blocker notes, and agent execution logs. Run `/speckit.taskstoissues`
to create one issue per task after planning is approved.

Label taxonomy:

| Label | Meaning |
| --- | --- |
| `status:ready` | Dependencies met, unassigned |
| `status:in-progress` | Actively being worked |
| `status:blocked` | Blocked; blocker documented in issue body |
| `status:in-review` | PR open |
| `status:done` | Merged and verified |
| `type:feature` | New user-visible behavior |
| `type:bug` | Defect fix |
| `type:refactor` | Internal restructuring, no behavior change |
| `type:chore` | Dependency, tooling, or infrastructure work |
| `priority:p1` | MVP; must ship before any P2 work begins |
| `priority:p2` | High value; ships after MVP is verified |
| `priority:p3` | Nice to have; ships after P2 is verified |

### GitHub Project board

Use a GitHub Project in kanban view, filtered by feature label, to visualize
the flow of tasks across states. Individual task progress is visible through
issue labels and comments. Do not maintain a separate spreadsheet or task list.

---

## Gate Rules

| Gate | Condition |
| --- | --- |
| T-1 | `/speckit.analyze` passes before any issue is created |
| T-2 | All dependency tasks are `done` before a task enters `ready` |
| T-3 | Branch opened and issue updated before work begins |
| T-4 | Blocker formally documented before task enters `blocked` |
| T-5 | PR traces to spec, plan, and task before review begins |
| T-6 | All acceptance criteria verified and evidence attached before task is `done` |

---

## Workflow

### 1. Create tracking records from `tasks.md`

When `tasks.md` is approved, run `/speckit.taskstoissues` to create one issue
per task. Each issue title follows the format:
`[T-##] [Feature Name] Short task description`

Copy only the minimum execution metadata into each issue: task ID and title,
dependency references, parent artifact links, acceptance criteria, and required
tests. Do not copy the full plan into the tracker.

Only tasks whose dependency tasks are `done` receive the `status:ready` label.
All others are created without a status label and labeled `status:ready`
progressively as upstream tasks complete.

### 2. Claim a task

Before starting work:

1. Confirm all dependency tasks carry `status:done`.
2. Assign yourself to the GitHub Issue.
3. Replace `status:ready` with `status:in-progress`.
4. Open a branch named `<task-id>-<short-slug>` (e.g., `t-03-add-auth`).
5. Add the branch name to the issue body.

Do not start work without completing all five steps. Untracked in-progress
work is invisible to the team and to agents resuming the work.

### 3. Implement

Execute the implementation according to `plan.md`. If the task reveals a
material change in design or scope, stop immediately and follow the scope
change protocol before continuing.

Each commit must reference the task ID in its message:

```
feat: implement user model (T-12)
```

### 4. Surface blockers

When a task cannot proceed:

1. Replace `status:in-progress` with `status:blocked`.
2. Add a blocker comment to the issue documenting:
   - What is blocking progress (concrete description)
   - What is needed to unblock (owner, decision, information)
   - Who has been notified
   - Date the blocker was identified
3. Stop work on the blocked task. Do not silently accumulate partial changes.
4. When the blocker is resolved, add a resolution comment, then return the
   task to `status:in-progress`.

If a blocker lasts more than one working day, escalate it at the next team
review.

### 5. Open a pull request

When the task is ready for review:

1. Open a PR from the task branch to the main integration branch.
2. The PR description must include:
   - Link to the GitHub Issue
   - Link to `spec.md` and the relevant acceptance criteria
   - Link to the specific task in `tasks.md`
   - Summary of what was implemented
   - Validation evidence available so far (test output, screenshots, logs)
   - Any deviations from the plan and their justification
3. Replace `status:in-progress` with `status:in-review`.
4. Add the PR link to the issue body.

A PR that cannot be traced to an approved spec and plan task will be returned
for clarification before review begins. If review finds that the change
exceeds task scope, the task returns to planning or is split into additional
approved tasks.

### 6. Close on evidence

A task moves to `done` only when:

- The PR is merged to the integration branch.
- All acceptance criteria in the issue are checked off.
- Required tests are present and passing in CI.
- Validation evidence is attached or linked (test results, screenshots,
  migration output, rollout confirmation, monitoring checks).
- The reviewer has explicitly approved traceability (spec → plan → task → PR).

Replace `status:in-review` with `status:done` after merge. `done` means
complete, not nearly complete.

### 7. User story checkpoints

At the end of each user story phase, verify that the increment is functional
and stable before moving to the next independent story. Do not carry forward
unverified state.

---

## WIP Limits

- Each owner should have one primary `in-progress` task at a time.
- Opening a second active task requires an explicit reason documented in both
  issues.
- A blocked task does not justify starting unlimited replacement work.
- Prioritize finishing `in-review` work before starting new `ready` work.

These limits exist to optimize for flow completion, not apparent activity.

---

## Agent Execution Protocol

When an AI agent is executing a task, it must maintain a running log in the
GitHub Issue body under an `## Execution Log` section. Each entry contains:

- timestamp
- action taken
- outcome (success, failure, partial)
- next step or handoff instruction

The execution log must be sufficient for a human to resume the task from any
point without re-reading the agent session.

At the start of each session, an agent must report the current state of
`tasks.md` and identify the target task before beginning work.

If an agent encounters a blocker:

1. Document the blocker in the issue using the same format as human blocker
   reporting.
2. Transition the issue to `status:blocked`.
3. Stop work and surface the blocker to a human reviewer.
4. Do not attempt to resolve architectural or product ambiguity autonomously.

An agent that completes a task must update issue state identically to a human
developer, including attaching validation evidence and verifying acceptance
criteria before marking the task `done`.

---

## Scope Changes During Execution

If implementation reveals that a task requires changes beyond its defined
scope:

1. Stop. Do not expand scope silently.
2. Document the discovery in the issue.
3. If an architectural decision is needed, create or update an ADR before
   continuing.
4. Return to planning: amend `plan.md` and re-run `/speckit.tasks` if the
   change is significant.
5. Create a new task for the expanded scope.
6. Resume the original task at its original scope.

Scope expansion absorbed into an existing task is a planning failure, not a
delivery success.

---

## Cadence

| Trigger | Action |
| --- | --- |
| Task creation | Create the full set of tracking records from `tasks.md` |
| Daily | Update any task whose status, blocker state, or evidence changed |
| PR opened | Move the task to `in-review` |
| PR merged | Move the task to `done` and attach final evidence |
| Weekly | Review blocked tasks, stale tasks, and dependency flow |

A stale task is any task with no meaningful update in two working days. Stale
tasks are reviewed at the weekly cadence and either unblocked or escalated.

---

## Completion Evidence

Every completed task must link to evidence that proves it met the plan.
Evidence types include:

- automated test results
- manual verification notes
- screenshots or recordings
- migration output
- rollout confirmation
- monitoring or alert checks

The exact evidence required is defined in `plan.md`. The tracker records that
the evidence exists and where to find it.

---

## Metrics

Track a small set of operational metrics:

- lead time from `ready` to `done`
- review time from `in-review` to `done`
- blocker count and blocker age
- stale `in-progress` task count
- completion rate by milestone or release

Metrics to avoid:

- raw issue count
- status churn without delivery context
- individual activity measures based on comment volume or task touches

---

## Anti-Patterns

- Creating tracker items before planning approval
- Letting the issue tracker become a second spec or design document
- Tracking vague epics instead of executable tasks
- Marking tasks `in-progress` before real implementation begins
- Leaving blocked tasks without an explicit written blocker
- Closing tasks when code is open in review but not yet merged
- Creating new execution work in the tracker without first updating `tasks.md`
- Silently accumulating partial work on a blocked task
- Starting unlimited replacement tasks to avoid the appearance of being blocked
- Marking a task `done` without attached validation evidence

---

## Progress Visibility

A feature is considered complete when:

- All tasks for that feature carry `status:done`.
- The end-to-end acceptance scenario in the feature spec has been verified.
- The feature branch is merged and the `specs/<###>/` artifacts are archived.

---

## Integration with the Planning Lifecycle

**Entry point:** After `/speckit.analyze` passes at the end of task
decomposition, run `/speckit.taskstoissues` to create GitHub Issues. This is
the moment tracking begins.

**Exit point:** When all issues for a feature carry `status:done` and the
end-to-end acceptance scenario passes, the feature is complete and the
planning artifacts may be archived.

---

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Tasks marked done before acceptance criteria are verified | Gate T-6 requires explicit checklist sign-off and attached evidence before `done` |
| Agent expands scope silently | Agent protocol requires stopping and documenting when scope is exceeded |
| Blockers absorbed rather than surfaced | `status:blocked` is a required label; work cannot continue on a blocked task |
| Issues become stale while work continues in local branches | PR link in issue body is required before review begins; weekly stale task review |
| Dependency ordering violated | Gate T-2 enforces dependency state before task enters `ready` |
| Scope changes bypass planning | Scope changes during execution trigger a planning return before new tasks begin |
| Agent leaves no resumable trail | Execution log in issue body is required; format is defined and mandatory |
| WIP sprawl obscures actual progress | One primary `in-progress` task per owner; WIP reviewed weekly |

---

## Open Questions

- Who has authority to transition a task to `done` — assignee, reviewer, or
  both must confirm?
- Should sprint cadence or kanban flow govern task scheduling across features?
- Should the execution log format for agents be enforced via an issue template
  or left as a documented convention?
- At what task volume does a GitHub Project board replace label-based
  filtering as the primary visibility mechanism?

---

## Recommended Rollout

1. Adopt this process for one planned feature before applying it broadly.
2. Create tracker issues directly from an approved `tasks.md` using
   `/speckit.taskstoissues`.
3. Require every PR to reference exactly one task unless an approved exception
   exists.
4. Review blocked and stale tasks weekly for one month.
5. Resolve the open questions above based on observed friction before expanding
   to additional features.
6. Adjust issue templates and automation only after the manual workflow is
   stable.
