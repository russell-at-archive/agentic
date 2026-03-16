# Unified Team Proposal for Autonomous Software Delivery

## Purpose

Define a single, enforceable operating model for autonomous software delivery agents that is state-driven, evidence-based, and auditable.

This proposal merges the strongest ideas from:

- [docs/claude/team-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/claude/team-proposal.md)
- [docs/codex/team-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/team-proposal.md)
- [docs/gemini/team-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/gemini/team-proposal.md)

## Operating Principles

- State-driven dispatch: role activation is determined by Linear issue state.
- Single responsibility: each role owns exactly one delivery phase.
- Evidence-first transitions: no transition without required artifacts.
- Spec-driven execution: planning artifacts are the source of implementation truth.
- Auditability by default: all agent actions are logged in issue execution logs.
- ADR enforcement: architecture-significant decisions require ADR linkage.

## Canonical Linear State Machine

The lifecycle uses exactly these states:

- `Draft`
- `Planning`
- `Plan Review`
- `Backlog`
- `Selected`
- `In Progress`
- `Blocked`
- `In Review`
- `Done`

`Blocked` is a returnable interruption state. Every blocked transition must include blocker reason, owner, and unblock criteria.

Allowed transitions:

- `Draft` -> `Planning` by Architect.
- `Planning` -> `Plan Review` by Architect.
- `Plan Review` -> `Backlog` by Director or designated human approver.
- `Backlog` -> `Selected` by Coordinator or Director (capacity-aware).
- `Selected` -> `In Progress` by Engineer.
- `In Progress` -> `In Review` by Engineer.
- `In Review` -> `Done` by Technical Lead after approval and merge.
- `In Review` -> `In Progress` by Technical Lead when revisions are required.
- Any active state -> `Blocked` by active role.
- `Blocked` -> prior active state by Director after validation.

Transition gates:

- Planning exit requires plan artifacts and ADR checks.
- Plan Review exit requires explicit human acceptance.
- Selected start requires dependency completion.
- In Review exit requires review verdict plus CI evidence.

## Role Contracts

## Director

Mission:

- Orchestrate lifecycle and dispatch specialists by state.

Inputs:

- All non-done issues and their current states.

Outputs:

- Dispatch records, escalation records, rollup confirmations.

Rules:

- One active specialist per issue at any time.
- No dispatch from `Blocked` until unblock criteria are met.
- Verify completion rollup before confirming final done state.

## Architect

Mission:

- Convert requests into executable plans and decision records.

Entry state:

- `Draft`.

Outputs:

- `spec.md`, `plan.md`, `tasks.md`, optional `research.md`, and required ADR links.

Rules:

- Invoke Explorer when technical unknowns block planning.
- Move ticket to `Plan Review` only after consistency checks complete.

## Coordinator

Mission:

- Transform accepted plans into dependency-safe task queues.

Entry state:

- `Backlog`.

Outputs:

- One Linear issue per task, dependency graph, readiness promotions.

Rules:

- Promote tasks to `Selected` only when dependencies are done.
- Keep task identifiers traceable from plan artifacts to Linear issues.

## Engineer

Mission:

- Implement exactly one approved task and produce review-ready evidence.

Entry state:

- `Selected`.

Outputs:

- Code changes, tests, Graphite PR stack link, validation evidence.

Rules:

- Use isolated worktree and branch per task.
- Follow red-green-refactor loop and full validation pass before review handoff.
- No silent scope expansion; block and escalate if scope is exceeded.

## Technical Lead

Mission:

- Enforce quality, fidelity, and merge safety.

Entry state:

- `In Review`.

Outputs:

- Structured findings and verdict: approve, revise, or reject.

Rules:

- Run four-tier review: automated validation, implementation fidelity, architectural integrity, final polish.
- Return to `In Progress` on unresolved blocking findings.

## Explorer

Mission:

- Resolve technical unknowns with source-backed research.

Trigger:

- On demand by Architect, Engineer, or Technical Lead.

Outputs:

- Structured research brief with citations and recommendation confidence.

Rules:

- No code changes or branch operations.
- Flag architectural choices as decision candidates, not finalized decisions.

## Execution Log Protocol

Each active issue maintains an `Execution Log` section in Linear with dated entries for:

- Actions performed.
- Commands or validation checks run.
- Outcomes and evidence links.
- Handoff notes to the next role.

This log is mandatory for resumability, auditability, and incident recovery.

## Required Artifacts by Phase

1. Planning:
   - Spec, plan, tasks, ADR references, optional research.
1. Scheduling:
   - Child ticket set, dependencies, ownership, estimates.
1. Implementation:
   - Branch/worktree metadata, PR stack link, test outputs.
1. Review:
   - Findings, verdict, required fixes or approval rationale.
1. Completion:
   - Merge confirmation, acceptance-criteria checklist, rollup summary.

## Concurrency and Locking

- One Engineer per task issue.
- One active PR stack per task issue.
- Ticket lock acquired at `Selected` -> `In Progress`.
- Branch namespace lock acquired when first stack PR is created.
- Locks released on `Done`, cancellation, or Director-led recovery.
- Explorer requests may run in parallel when scopes are disjoint.

## Quality Gates and Definition of Done

A task reaches `Done` only when all gates are met:

- Acceptance criteria complete.
- CI-required validations pass.
- Review verdict is `approve`.
- No unresolved blocking findings.
- Required documentation updates merged.
- Required ADR references present for architecture-significant changes.

## Tooling Policy

- Linear: status and assignment source of truth.
- GitHub: code and CI source of truth.
- Graphite: stacked branch and PR management.
- Speckit: mandatory for new feature planning artifacts.
- ADRs in `docs/adr/`: mandatory for architecture-significant decisions.

Implementation hygiene recommendations:

- Provide a canonical `make validate` command for local and review parity.
- Use PR templates that require traceability and validation evidence sections.

## Failure and Incident Handling

- Transient integration failures: bounded retries with backoff.
- Persistent failures: move to `Blocked` with explicit owner and unblock criteria.
- Stale locks: Director runs lock reconciliation.
- Broken PR stacks: Engineer repairs stack and revalidates.
- Invalid transitions: reject transition and log policy violation.

## Metrics and Reporting

Track at minimum:

- Lead time: `Selected` to `Done`.
- Review latency: `In Review` to verdict.
- Reopen rate: `In Review` to `In Progress`.
- Defect escape rate post-done.
- Agent failure rate and retry volume.

Reporting cadence:

- Daily operational dashboard.
- Weekly quality and throughput review.

## ADR-Required Decisions Before Implementation

The following decisions must be captured as ADRs before system build-out:

1. Director runtime mode: polling, webhook, or hybrid.
1. Agent authentication and secrets model.
1. Coordinator downstream-promotion trigger mechanism.
1. Graphite stack depth limit and split policy.
1. Incident severity levels and escalation ownership.

Reference baseline ADR policy:

- [docs/adr/0001-adopt-architecture-decision-records.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/adr/0001-adopt-architecture-decision-records.md)

## Phased Rollout

1. Governance phase:
   - Finalize contracts, state gates, artifact templates, and ADR set.
1. Planning and scheduling automation:
   - Implement Director, Architect, and Coordinator paths.
1. Implementation and review automation:
   - Implement Engineer and Technical Lead paths with Graphite workflows.
1. Reliability and optimization:
   - Add lock recovery, incident workflows, and metric tuning.

## Final Recommendation

Adopt this unified proposal as the canonical team operating model and use it to drive ADR creation and phased implementation.
