# Agent Team: Autonomous Software Delivery

**Date**: 2026-03-16
**Status**: Draft — pending human review and ADR elevation for flagged decisions

---

## Purpose

Define the operating model for an autonomous multi-agent software development
team. This document specifies role contracts, workflow states, handoff rules,
quality gates, concurrency semantics, failure recovery, and observability for a
system in which agents plan, schedule, implement, review, and report software
work with Linear as the system of record, GitHub as source control, and
Graphite for stacked pull requests.

---

## Core Philosophy

The team operates on **Spec-Driven Development**: intent is clarified in plain
text before code is written. The specification is the source of truth for a
feature. Code must satisfy the spec; the spec is never reverse-engineered from
code.

Clarifying intent before implementation is cheaper, faster, and less error-prone
than refactoring code later. For autonomous agents, this benefit is amplified:
a vague request forces an agent to guess architecture, tools, and behavior. A
well-formed `spec.md` and `plan.md` allow an agent to generate accurate tasks
and execute them with higher fidelity, reducing hallucination and increasing
delivery quality.

---

## Design Principles

- **State-driven dispatch.** Agents are invoked by Linear issue state, not by
  direct call, after a `Draft` issue exists. The Feature Draft Agent is the
  one pre-lifecycle exception: it is invoked directly by a human and creates
  the first `Draft` issue that enters the state machine.
- **Single responsibility.** Each agent owns exactly one phase of the delivery
  lifecycle. No agent crosses phase boundaries.
- **Entry condition enforcement.** Agents refuse to act on issues not in their
  required entry state. Refusing is correct behavior, not a failure.
- **Evidence-based completion.** No state transition advances without required
  evidence attached. Assertions without evidence are rejected.
- **Fail loudly.** When an agent cannot proceed, it documents the blocker in
  Linear, moves the issue to `Blocked`, and stops. It does not improvise or
  silently skip gates.
- **Humans gate plan review.** Plan artifacts are reviewed and approved by
  humans. No agent auto-approves a plan.
- **ADRs are mandatory.** Significant architectural decisions require an ADR
  before work continues. Agents check for required ADRs and stop if one is
  missing.
- **Spec-first, always.** Implementation must not start before the spec, plan,
  and task decomposition are approved and gates 1 through 5 of the planning
  process are satisfied.
- **No silent scope expansion.** Discovery of out-of-scope work pauses
  execution and returns to planning.

---

## Agent Roster

### 0. Feature Draft Agent

**Mission**: Transform a raw human request into a planning-ready `Draft`
Linear issue.

**Entry condition**: Human-invoked before a planning-ready `Draft` issue exists.
**Exit state**: `Draft`

**Responsibilities**:

1. Conduct a short structured intake conversation with the stakeholder.
2. Classify the request as `feature`, `bug fix`, `refactor`,
   `dependency/update`, or `architecture/platform`.
3. Produce a CTR-based Draft Design Prompt using `Context`, `Task`, and
   `Refine`.
4. Capture must-haves, non-goals, constraints, risks, open questions, and the
   acceptance signal.
5. Confirm the completed draft with the stakeholder before writing to Linear.
6. Create or update the Linear issue in `Draft`.
7. Stop at handoff. Do not create `spec.md`, `plan.md`, or `tasks.md`.

**Failure behavior**: If the objective remains undefined after intake, do not
create the `Draft` issue. Document the blocker for the stakeholder and stop.

**Model**: Medium reasoning effort. The work is conversational and
classification-heavy, not deep technical planning.

**Tools**: Stakeholder interaction, Linear API (create, update), lightweight
documentation read access.

---

### 1. Director

**Mission**: Orchestrate the delivery lifecycle. Route issues to the correct
agent based on state. Confirm completion.

**Entry state**: Any. The Director monitors all non-`Done`, non-`Blocked` issues.

**Responsibilities**:

- Poll Linear for open issues on a configured cadence (default: 5 minutes).
  A webhook-based alternative is preferable for lower latency; see ADR backlog.
- Before each dispatch, invoke the **Compliance Gate** sub-function to confirm
  required artifacts and preconditions are present. Do not dispatch if the gate
  fails.
- Invoke the correct specialist agent based on the dispatch table below.
- Enforce concurrency: do not dispatch a second agent to an issue that already
  has an agent assigned and active.
- On task `Done`: confirm the completion rollup — acceptance criteria checked,
  CI passing, PR link present, sub-task issues complete for the parent feature.
- Escalate stale issues (no meaningful update in two working days) to the
  weekly review queue.
- Pause all dispatch for incident containment when a systemic failure is
  detected.
- On agent failure: apply exponential backoff retries up to the configured
  limit, then move the issue to `Blocked` and document the failure.

**Dispatch table**:

| Issue State | Target Agent | Notes |
| --- | --- | --- |
| `Draft` | Architect | — |
| `Backlog` | Coordinator | — |
| `Selected` | Engineer | After Compliance Gate confirms dependencies done |
| `In Review` | Technical Lead | — |
| `Done` | Director (rollup) | Confirmation only, no external dispatch |
| `Planning` | None | Architect already active |
| `Plan Review` | None | Awaiting human approval |
| `In Progress` | None | Engineer already active |
| `Blocked` | None | Awaiting blocker resolution |

**Compliance Gate sub-function**: Before every dispatch, the Director
validates:

- Required artifacts exist for the current phase (see Artifact Standards).
- The issue has a defined assignee and objective.
- For `Selected`: all upstream dependency issues are `Done`.
- For `In Review`: the PR description contains spec, plan, task links, and
  validation evidence.
- For `Done` rollup: acceptance criteria, CI evidence, and PR link are present.

If any check fails, the Director moves the issue to `Blocked` with the specific
failure documented, and does not dispatch the agent.

The Director does not dispatch the Feature Draft Agent. Draft creation is a
human-invoked pre-lifecycle step.

**Model**: Low reasoning effort. The Director is routing and validation logic,
not deep reasoning.

**Tools**: Linear API (read, write), agent invocation mechanism.

---

### 2. Architect

**Mission**: Transform a feature request into approved planning artifacts.

**Entry state**: `Draft`
**Exit state**: `Plan Review`

**Responsibilities**:

1. Confirm the issue has a defined objective. If not, move to `Blocked`.
2. Move the issue to `Planning`.
3. Classify the change type: feature, bug fix, refactor, dependency update, or
   architecture/platform.
4. Invoke the Explorer when technical unknowns must be resolved before planning
   can proceed. Explorer output feeds `research.md`.
5. Produce `spec.md` via `/speckit.specify` and `/speckit.clarify` as needed.
6. Produce `plan.md` via `/speckit.plan` using the CTR method (Context, Task,
   Refine).
7. Produce `tasks.md` via `/speckit.tasks`. Each task must be sized for one
   Graphite stacked PR.
8. Create required ADRs for any significant architectural decisions identified
   during planning.
9. Run `/speckit.analyze` to verify cross-artifact consistency. Block on
   failures.
10. Open a plan PR containing all planning artifacts.
11. Move the issue to `Plan Review`.

**Plan PR title format**: `plan: [Feature Name] planning artifacts`

**Output artifacts** (stored in `specs/<###-feature-name>/`):

```text
specs/<###-feature-name>/
├── spec.md
├── plan.md
├── research.md        (when Explorer was used)
├── data-model.md      (when applicable)
├── quickstart.md      (when applicable)
├── contracts/         (when applicable)
└── tasks.md
```

ADRs produced during planning land in `docs/adr/`.

**Failure behavior**: On unresolvable ambiguity, document the question in
Linear, move to `Blocked`, and surface for human resolution. Do not guess.

**Model**: High reasoning effort. Planning quality determines all downstream
delivery quality.

**Tools**: GitHub Speckit (`/speckit.*`), GitHub (open PR), Linear API, Explorer
(on demand).

---

### 3. Coordinator

**Mission**: Convert an approved plan into a dependency-safe execution backlog
in Linear.

**Entry state**: `Backlog` (parent feature issue, plan PR merged and approved)
**Exit state**: Child task issues set to `Selected` (dependency-free) or
`Backlog` (dependent)

**Responsibilities**:

1. Read `tasks.md` for the feature. Confirm it exists and is consistent with
   `plan.md`.
2. Create one Linear issue per task using this title format:
   `[T-##] [Feature Name] Short task description`
3. Populate each issue with execution-relevant metadata only:
   - Task ID matching `tasks.md` (e.g., `T-01`) and Linear identifier
     (e.g., `ARC-42`)
   - Links to `spec.md`, `plan.md`, `tasks.md`
   - Dependency references to other task issue IDs
   - Acceptance criteria summary
   - Required tests summary
   - Scope notes and non-goals
4. Set dependency-free tasks to `Selected`. All others remain in `Backlog`.
5. Register a progressive promotion trigger: as upstream task issues move to
   `Done`, promote their downstream dependents to `Selected`. This is
   re-invoked by the Director when newly `Done` tasks have `Backlog` dependents.

**Failure behavior**: If `tasks.md` is missing or inconsistent with `plan.md`,
move the parent feature issue to `Blocked` and document the gap.

**Model**: Low reasoning effort. The Coordinator is primarily data mapping.

**Tools**: Linear API (create, update issues), GitHub (read `tasks.md`).

---

### 4. Engineer

**Mission**: Implement exactly one approved task per invocation using
test-driven development.

**Entry state**: `Selected`
**Exit state**: `In Review`

**Pre-flight checklist** (required before any code is written):

- [ ] All upstream dependency task issues are `Done`.
- [ ] `spec.md`, `plan.md`, and the specific task in `tasks.md` are read and
      understood.
- [ ] Acceptance criteria and required tests for this task are explicit.
- [ ] Non-goals are understood.
- [ ] Any required ADRs are present and linked.
- [ ] Local repository is clean; stack is synced (`gt sync`).

If any pre-flight check fails, move the issue to `Blocked`, document the gap,
and stop.

**Responsibilities**:

1. Assign self to the Linear issue.
2. Move the issue to `In Progress`.
3. Acquire a ticket lock (see Concurrency and Locking).
4. Create a git worktree for isolated development.
5. Create the branch:
   `gt create <linear-id>-t-<##>-<short-slug>`. Stack on the upstream
   branch when this task has a direct code dependency on upstream output.
6. Update the Linear issue with the branch name.
7. For each acceptance criterion: write a failing test (confirm it fails for
   the expected reason), then write minimum production code to make it pass,
   then refactor. Run the full test suite after each green cycle.
8. Run the full local validation pass before opening a PR: tests, lint, type
   checks, build. All checks must pass. This is a hard gate.
9. Open the PR: `gt submit --stack`.
10. Write the PR description including: Linear issue link, `spec.md` link with
    relevant acceptance criteria, `plan.md` link, task link in `tasks.md`,
    implementation summary, tests added or updated, validation pass output,
    any deviation from the plan with justification.
11. Move the Linear issue to `In Review`.

**Commit message format**: `<type>(<scope>): <short description> (T-##, <LINEAR-ID>)`

**Branch name format**: `<linear-id>-t-<##>-<short-slug>`

**Worktree lifecycle**: Create at task start. Retain until the PR merges. Clean
up after merge. On task rejection requiring a restart, recreate the worktree.

**Scope change protocol**: If implementation reveals out-of-scope work, stop,
document in Linear, move to `Blocked`. Do not silently expand scope.

**Failure behavior**: On any uncertainty — architectural ambiguity, missing
requirement, environment failure — document the blocker, move to `Blocked`,
stop. Do not resolve architectural or product ambiguity autonomously.

**Model**: High reasoning effort. Strong code generation and test-first
discipline required.

**Tools**: Graphite CLI (`gt`), git, test runner, linter, type checker, Linear
API, GitHub API.

---

### 5. Technical Lead

**Mission**: Enforce quality and merge readiness through rigorous, structured
code review.

**Entry state**: `In Review`
**Exit state**: `Done` (approve) or `In Progress` (revise/reject)

**Pre-flight checklist** (required before deep review begins):

- [ ] The PR maps to one approved task.
- [ ] The PR description links `spec.md`, `plan.md`, `tasks.md`, and the Linear
      issue.
- [ ] Validation evidence is attached or linked.
- [ ] No undocumented architectural decision is present in the diff.

If any pre-flight check fails, stop and return the PR without starting deep
review. Document what is missing.

**Four-tier review**:

**Tier 1 — Automated Validation**: build, lint, and type checks pass; existing
test suite passes; task-required new tests are present and passing; traceability
is present.

**Tier 2 — Implementation Fidelity**: the PR maps to one approved task; the
implementation matches the behavior in `spec.md` and `plan.md`; any deviation
from the plan is justified and documented; speculative cleanup is excluded.

**Tier 3 — Architectural Integrity**: abstractions are coherent; interfaces and
invariants are explicit; concurrency, security, migration, and retry concerns
are evaluated where relevant; significant choices are backed by ADRs;
no avoidable future debt is introduced.

**Tier 4 — Final Polish**: names are clear and idiomatic; structure and control
flow are understandable; comments explain genuinely non-obvious logic;
diagnostics and failure behavior are adequate.

**Verdict model**:

- `reject`: fundamentally unreviewable, out of scope, unsafe, or inconsistent
  with the approved plan.
- `revise`: direction is acceptable, specific defects must be fixed before merge.
- `approve`: sufficient confidence for merge.

**Review comment taxonomy**:

- `blocking:` — must be resolved before approval
- `question:` — must be answered before confidence is sufficient
- `suggestion:` — optional improvement, not required for merge
- `note:` — context or observation, no action required

**High-risk changes**: Changes touching auth, persistence, migration,
distributed workflows, or architectural boundaries require Tier 3 review by
a human or designated senior reviewer. The Technical Lead flags these and
escalates rather than approving alone.

**On approval**: Approve the PR in Graphite. The PR merges bottom-up. After
merge the Linear issue moves to `Done` and the Director confirms rollup.

**On revise/reject**: Linear issue returns to `In Progress`. Engineer addresses
findings.

**Model**: High reasoning effort. Review quality is a quality gate.

**Tools**: GitHub (read PR, post review, approve), Graphite, Linear API.

---

### 6. Explorer

**Mission**: Resolve technical unknowns through source-backed research.

**Entry state**: On demand (not state-driven)

**Invocation triggers**:

1. Architect during Planning when technical unknowns block spec or plan
   production.
2. Any agent when a task hits `Blocked` due to technical unknowns.
3. Direct human invocation for independent research.

**Invocation inputs**: A problem statement, a list of specific unknowns or
questions, and a description of the target audience.

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

Every factual claim must include a source citation. Output is written to
`specs/<###-feature-name>/research.md` when invoked in the context of a
feature. For standalone research, output is delivered as a report artifact
linked in the relevant Linear issue.

**Rules**:

- Do not produce implementation patches.
- Do not create branches or pull requests.
- Do not make architectural decisions — flag them as decisions to be made.

**Model**: Medium reasoning effort with web search access enabled.

**Tools**: Web search, repository read access, documentation access.

---

## Linear State Machine

Canonical nine-state model. State names must match exactly.

| State | Phase | Owner | Meaning | Exit Condition |
| --- | --- | --- | --- | --- |
| `Draft` | Planning | Architect | Feature created; Architect not yet assigned | Architect assigned; objective defined |
| `Planning` | Planning | Architect | Architect producing planning artifacts | Plan PR opened; `/speckit.analyze` passes |
| `Plan Review` | Planning | Human | Plan PR open; awaiting human approval | Plan PR merged |
| `Backlog` | Scheduling | Coordinator | Plan accepted; Coordinator active | Per-task issues created; dependency-free issues set to `Selected` |
| `Selected` | Implementation | Engineer | Task ready; dependencies satisfied | Engineer begins work |
| `In Progress` | Implementation | Engineer | Engineer actively implementing | PR submitted or blocker found |
| `Blocked` | Any | Assignee | Work halted; blocker documented | Blocker resolved; return to prior state |
| `In Review` | Review | Technical Lead | Graphite stack published; Technical Lead reviewing | Review complete |
| `Done` | Complete | Director | PR merged; evidence attached; rollup confirmed | None |

`Blocked` may be entered from any active state. On resolution, the issue
returns to the state it held before entering `Blocked`. A task may never move
from `Blocked` directly to `Done`.

**Gate rules**:

| Gate | Transition | Required Condition |
| --- | --- | --- |
| T-1 | `Draft` → `Planning` | Architect assigned; objective defined |
| T-2 | `Planning` → `Plan Review` | `spec.md`, `plan.md`, `tasks.md` exist; `/speckit.analyze` passes |
| T-3 | `Plan Review` → `Backlog` | Plan PR approved and merged by human |
| T-4 | `Backlog` → `Selected` | All dependency tasks are `Done` |
| T-5 | `Selected` → `In Progress` | Ticket lock acquired; worktree created; stack initialized |
| T-6 | `In Progress` → `Blocked` | Blocker documented with owner, condition, date |
| T-7 | `In Progress` → `In Review` | Graphite stack published; PR links spec, plan, and task |
| T-8 | `In Review` → `Done` | Acceptance criteria verified; evidence attached; PR merged; Director rollup confirmed |

---

## Artifact Standards

Required artifacts per phase:

**Planning bundle** (`specs/<###-feature-name>/`):

- `spec.md` — behavior, scope, acceptance criteria
- `plan.md` — implementation approach, constraints, validation strategy
- `tasks.md` — ordered, independently reviewable task breakdown
- `research.md` — when Explorer was used
- ADR links or new ADRs for architectural decisions

**Scheduling bundle** (in Linear):

- One issue per task with task ID, title, dependency links, acceptance criteria
  summary, required tests summary, parent artifact links

**Implementation bundle** (in PR and Linear issue):

- Branch name and worktree metadata
- Graphite stack URL
- Test and validation pass output
- Commit history referencing task ID and Linear ID

**Review bundle** (in PR review):

- Four-tier review completion
- Findings ordered by severity with file references
- Verdict: `reject`, `revise`, or `approve`

**Research bundle** (`specs/<###>/research.md` or linked artifact):

- Problem, constraints, affected areas, unknowns resolved, risks, directions,
  sources

---

## Concurrency and Locking Model

- One Engineer per issue. One active PR stack per issue.
- Multiple Explorer invocations may run in parallel when scopes are disjoint.
- The Coordinator cannot schedule a task whose upstream dependencies are
  unresolved.

**Locking rules**:

| Lock | Acquired at | Released at |
| --- | --- | --- |
| Ticket lock | `Selected` → `In Progress` | `Done`, task cancellation, or Director recovery |
| Branch namespace lock | First PR created in stack | PR merged or stack abandoned |

**Lock recovery**: The Director can run lock-reconciliation to clear orphaned
locks (e.g., locks held by a failed agent session that never released them).
Lock reconciliation requires human confirmation before executing.

---

## Execution Log Protocol

Every Linear issue where an agent materially advances work, encounters
uncertainty, or leaves work partially complete must contain an
`## Execution Log` section in the issue description.

The Execution Log exists for three purposes:

- **Resumability**: another agent or human can pick up where the previous agent
  left off without re-deriving context.
- **Transparency**: a clear audit trail of actions taken, tests run, and errors
  encountered is visible to stakeholders.
- **Handoff**: explicit signals for the next agent in the lifecycle chain.

**Entry format**:

```text
- [timestamp] [agent role] action taken → outcome (success/failure/partial)
  Relevant files or commands: ...
  Next step or handoff: ...
```

**Reporting tempo**: every four hours of active work or at each significant
milestone, whichever comes first. This is proportional — routine low-risk tasks
do not require verbose transcripts. Complex, blocked, or partially complete
tasks do.

---

## Failure Handling and Recovery

| Failure Type | Response |
| --- | --- |
| Transient API failure | Exponential backoff with bounded retries, then `Blocked` with documented cause |
| Stale ticket lock | Director runs lock-reconciliation with human confirmation |
| Broken Graphite stack | Engineer runs stack repair workflow; re-validates dependencies before re-submitting |
| Invalid state transition attempt | Reject the transition; attach reason; notify issue owner |
| Agent session crash mid-task | Director detects stale `In Progress` + no log update; moves to `Blocked`; Execution Log provides resume context |
| Missing required artifact at gate | Compliance Gate blocks dispatch; moves to `Blocked` with specific missing artifact documented |

---

## Tool Assignments and Access Boundaries

| Tool | Agents With Access | Access Level |
| --- | --- | --- |
| Linear API | Director, Architect, Coordinator, Engineer, Technical Lead | Director, Architect, Coordinator, Engineer, Tech Lead: read+write |
| GitHub (read) | Architect, Engineer, Technical Lead, Explorer | Read |
| GitHub (write: PR, review, merge) | Architect (plan PR), Engineer (implementation PR), Technical Lead (review + approve) | Scoped write |
| GitHub Speckit | Architect | Full |
| Graphite CLI | Engineer (create, submit), Technical Lead (review, approve) | Scoped |
| Web search | Explorer | Full |
| AWS | Unassigned — see Open Questions | — |

**Access boundaries**:

- Architect and Technical Lead may approve architecture-affecting changes.
- Engineer may not merge when required ADR linkage is missing.
- Engineer may not submit a PR that has not passed the full local validation
  pass.
- Director may pause all agent dispatch for incident containment.

---

## Gaps Resolved

| # | Gap | Resolution |
| --- | --- | --- |
| 1 | State names do not match canonical states in tracking-process.md | Canonical nine-state model enforced throughout this document |
| 2 | Director has no defined polling cadence | 5-minute default; webhook alternative flagged as ADR decision |
| 3 | Director has no failure handling or retry policy | Exponential backoff; move to `Blocked` on exhaustion |
| 4 | Director concurrency constraints undefined | One active agent per issue; ticket and branch locks enforced |
| 5 | Director rollup confirmation logic undefined | Acceptance criteria, CI, PR link, sub-task completion checked |
| 6 | No Compliance Gate enforcement mechanism | Compliance Gate sub-function in Director validates before every dispatch |
| 7 | Coordinator entry state wrong in one proposal | Canonical entry is `Backlog`; `Selected` entry is incorrect |
| 8 | Coordinator progressive promotion logic undefined | Director re-invokes Coordinator when upstream tasks complete |
| 9 | Explorer output format and storage undefined | Structured report to `specs/<###>/research.md` |
| 10 | Explorer trigger scope too narrow | Explorer invoked by Architect, any agent on `Blocked`, or human |
| 11 | Engineer worktree lifecycle undefined | Create at start, retain through merge, clean up after merge |
| 12 | No concurrency or locking model | Ticket lock + branch namespace lock with Director recovery |
| 13 | No failure recovery procedures | Specific recovery actions per failure type defined |
| 15 | No phased rollout | Four-phase rollout defined |
| 16 | No cross-cutting enforcement mechanism | Compliance Gate sub-function |
| 17 | Codex pipeline vs. Director relationship undefined | Codex pipeline is per-session internal substrate; Director is system-level orchestrator |
| 18 | tracking-process.md uses Linear; implementation-process.md referenced GitHub Issues | Canonical tracker is Linear; implementation-process.md has been aligned to match |
| 19 | AWS tool has no assigned agent | Unresolved; requires product decision (see Open Questions) |

---

## ADR Backlog

The following decisions must be elevated to ADRs before implementation begins.

| # | Decision | Why It Requires an ADR |
| --- | --- | --- |
| 1 | Director invocation: polling vs. webhook | Affects latency, infrastructure complexity, and cost |
| 2 | Retry and failure escalation policy | Governs agent failure recovery across all roles |
| 3 | Codex pipeline as internal execution substrate | Formalizes the relationship between Director orchestration and Codex sub-agent sessions |
| 4 | Progressive task promotion mechanism | Defines how Coordinator promotes tasks as dependencies complete |
| 5 | Agent authentication and secrets management | Governs how agents authenticate to Linear, GitHub, Graphite, and AWS |
| 6 | AWS tool scope and assigned agent | Defines which operations agents perform in AWS and which agent owns them |
| 7 | Worktree management policy | Governs creation, isolation, and cleanup for concurrent Engineer sessions |
| 8 | Linear state machine as the canonical tracking standard | Significant workflow choice governing all work execution (per tracking-process.md adoption note) |
| 9 | Concurrency and locking semantics | Defines lock acquisition, release, and recovery mechanisms |

---

## Phased Rollout

### Phase 1 — Governance and artifacts

- Ratify the Constitution (`.specify/memory/constitution.md`).
- Finalize role contracts, state machine, and artifact templates.
- Create the ADR backlog above.
- Adopt this document as the project standard through an ADR.

### Phase 2 — Scheduling and planning automation

- Implement Director (polling, dispatch table, Compliance Gate).
- Implement Architect (Speckit integration, plan PR workflow).
- Implement Coordinator (issue creation, dependency linking, progressive
  promotion).

### Phase 3 — Engineering and review automation

- Implement Engineer (worktree, TDD loop, Graphite integration, validation pass).
- Implement Technical Lead (four-tier review, verdict model, PR approval).
- Add lock acquisition and release to the Engineer workflow.

### Phase 4 — Resilience and optimization

- Implement lock-reconciliation in the Director.
- Tune failure recovery (backoff, stack repair, incident containment).
- Run a full end-to-end pilot on a real feature and calibrate based on outcomes.

---

## Practical Implementation Recommendations

The following concrete steps are required before agents can operate in
production.

**Ratify the Constitution**: Populate `.specify/memory/constitution.md` with
the project's non-negotiable engineering principles. An empty or placeholder
Constitution means the Architect cannot complete the Constitution Check during
planning. Treat an absent Constitution as a blocker on Phase 1.

**Define a canonical validation command**: Implement a single `make validate`
(or equivalent) command in the root Makefile that runs build, lint, type check,
and full test suite. The Engineer and the Director's Compliance Gate will
reference this command. Without it, the "full local validation pass" gate
cannot be enforced consistently.

**Add PR templates**: Update GitHub PR templates to include required sections:

- Traceability (links to `spec.md`, `plan.md`, `tasks.md`, Linear issue)
- Validation evidence (test output or CI link)
- Deviation disclosure (any departure from the approved plan)
- Reviewer verdict (for Technical Lead)

**Implement Director invocation**: Start with polling. Use a scheduled job on a
5-minute interval with exponential backoff on Linear API errors. Plan the
webhook-based alternative as the Phase 4 optimization once polling is validated.

**Configure Linear states**: Confirm the nine canonical states exist in the
Linear team configuration with exact name matching. Add the four type labels
(`feature`, `bug`, `refactor`, `chore`). Create the recommended views
(My In Progress, Blocked, Selected by Priority, In Review, Done This Cycle).

---

## Open Questions

See [docs/open-questions.md](open-questions.md) for the consolidated
and deduplicated question backlog. Questions originating here are tracked as OQ-04,
OQ-05, OQ-08, OQ-09, OQ-13, OQ-18, OQ-19, OQ-24, OQ-30, OQ-31.
