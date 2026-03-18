# Proposal: Canonical ADR Backlog

## Status

Proposed for review. This document is intended to replace the competing ADR
backlog drafts with a single canonical proposal for the repository.

## Purpose

The repository's process documents already depend on a significant number of
architectural decisions, but `docs/adr/` is still empty. This proposal defines
the ADR backlog that should be created to bring the documented system under
explicit architectural governance.

The goal is not simply to create ADRs because the process says so. The goal is
to record the specific cross-cutting decisions that the current workflows,
roles, state machine, and operational assumptions already rely on.

## Design Principles

- One ADR should capture one durable architectural boundary.
- Separate ADRs should exist only when the decisions are likely to evolve
  independently.
- The backlog should distinguish implementation blockers from follow-on
  governance work.
- The ADR set should reflect the repository as it exists today, not an imagined
  future system.

## Proposed ADR Program

### Tier 1: Governance and Operating-Model Blockers

These ADRs should exist before the repository treats the current process docs
as a ratified architecture.

#### 0001: Record Architectural Decisions

Define ADRs as the repository's architectural record, including:

- `docs/adr/` as the storage location
- the ADR format
- append-only and supersession rules

This ADR is the baseline for every other ADR in the system.

#### 0002: Adopt Agentic Team Operating Model

Ratify the multi-agent operating model in `docs/agentic-team.md`, including:

- the agent roster
- role boundaries
- state-driven dispatch
- compliance gate expectations
- failure behavior and stopping rules

This is the broadest architectural decision in the repository and should be
recorded explicitly.

#### 0003: Linear State Machine as Canonical Tracking Standard

Ratify Linear as the system of record for live execution state and adopt the
canonical state machine and gate model in `docs/tracking-process.md`.

This ADR should cover:

- canonical state names
- transition gates
- `Blocked` semantics
- Linear as the source of truth for live workflow state

#### 0004: Feature Draft Agent as Pre-Lifecycle Intake Exception

Ratify the Feature Draft Agent and the decision to treat it as the one
pre-lifecycle, human-invoked exception to the otherwise state-driven system.

This ADR should cover:

- human-invoked draft creation
- Draft Design Prompt as the intake artifact
- no-new-state decision for initial adoption

#### 0005: Spec-Driven Development and Planning Method

Ratify the repository's spec-first methodology and planning model in
`docs/planning-process.md`.

This ADR should cover:

- specification as the source of truth
- planning before implementation
- artifact model (`spec.md`, `plan.md`, `tasks.md`, and related files)
- CTR as the canonical planning method

### Tier 2: Implementation Blockers

These ADRs should exist before implementation is treated as production-grade.

#### 0006: Software Review and Merge Readiness Model

Ratify the review model in `docs/review-process.md`, including:

- four-tier review
- verdict taxonomy
- blocker semantics
- traceability expectations

#### 0007: Graphite Stacked Pull Requests as Implementation Transport

Ratify Graphite stacks as the implementation and review transport.

This ADR should cover:

- one task to one branch to one PR as the default
- stack ordering
- branch naming conventions
- when to stack and when to split

#### 0008: Concurrency, Locking, and Worktree Management

Define the operational model for safe concurrent implementation.

This ADR should cover:

- ticket locks
- branch namespace locks
- worktree creation and cleanup
- lock recovery and reconciliation

These elements should stay in one ADR because they operate as one system.

#### 0009: Canonical Validation Command and Merge Gate Policy

Define the standard validation contract for both humans and agents.

This ADR should cover:

- one canonical local validation command
- how local validation and CI interact as merge gates
- exception approval and recording rules

### Tier 3: Autonomy and Infrastructure Blockers

These ADRs are required before the system can operate autonomously at scale.

#### 0010: Director Invocation and Dispatch Strategy

Decide whether the Director runs on polling, webhooks, or a hybrid model.

This ADR affects:

- latency
- infrastructure complexity
- cost
- operational observability

#### 0011: Retry, Failure Recovery, and Escalation Policy

Define the system-wide recovery model for agent failures and operational faults.

This ADR should cover:

- retry bounds
- backoff strategy
- blocked-state escalation
- session crash recovery

#### 0012: Progressive Task Promotion Mechanism

Define how dependent tasks move from `Backlog` to `Selected` as upstream work
completes.

This is a real automation contract, not just a coordinator convenience.

#### 0013: Agent Authentication and Secrets Management

Define how agents authenticate to external systems and how credentials are
handled.

This ADR should cover at minimum:

- Linear
- GitHub
- Graphite
- AWS
- secret storage and access boundaries

#### 0014: AWS Tool Scope and Agent Ownership

Define what AWS actions agents may perform and which roles own those actions.

This ADR is separate from authentication because it governs operational
authority and scope, not just credentials.

#### 0015: Execution Substrate and Runtime Integration Model

Define the relationship between:

- Director orchestration
- runtime-specific agent definitions
- Codex, Claude, and Gemini execution layers

This ADR should make explicit how the repository's system-level architecture
maps to its runtime-specific agent implementations.

### Tier 4: Governance Completion ADRs

These ADRs are not immediate blockers, but the current docs already depend on
them conceptually.

#### 0016: Constitution Governance and Minimum Contents

Define the governance model for `.specify/memory/constitution.md`.

This ADR should cover:

- who ratifies the Constitution
- required sections
- update process
- how exceptions are handled

#### 0017: Pull Request Template and Traceability Standard

Define the required PR structure that the review and planning system already
assumes.

This ADR should cover:

- links to spec, plan, tasks, and Linear
- validation evidence
- deviation disclosure
- reviewer verdict structure

## What Should Not Be Separate ADRs

To keep the backlog coherent, the following should remain inside broader ADRs
rather than become standalone records:

- CTR intake standards separate from planning methodology
- one-task-one-branch-one-PR separate from Graphite transport
- compliance gate semantics separate from the operating model
- ADR requirement policy separate from the foundational ADR adoption decision

These are important, but they are better treated as scoped parts of larger
decision surfaces.

## Recommended Final Backlog

1. `0001-record-architectural-decisions.md`
2. `0002-adopt-agentic-team-operating-model.md`
3. `0003-linear-state-machine-as-canonical-tracking-standard.md`
4. `0004-feature-draft-agent-as-pre-lifecycle-intake-exception.md`
5. `0005-spec-driven-development-and-planning-method.md`
6. `0006-software-review-and-merge-readiness-model.md`
7. `0007-graphite-stacked-pull-requests-as-implementation-transport.md`
8. `0008-concurrency-locking-and-worktree-management.md`
9. `0009-canonical-validation-command-and-merge-gate-policy.md`
10. `0010-director-invocation-and-dispatch-strategy.md`
11. `0011-retry-failure-recovery-and-escalation-policy.md`
12. `0012-progressive-task-promotion-mechanism.md`
13. `0013-agent-authentication-and-secrets-management.md`
14. `0014-aws-tool-scope-and-agent-ownership.md`
15. `0015-execution-substrate-and-runtime-integration-model.md`
16. `0016-constitution-governance-and-minimum-contents.md`
17. `0017-pull-request-template-and-traceability-standard.md`

## Recommended Sequencing

### Before treating the process docs as a ratified architecture

- `0001` through `0005`

### Before production-grade implementation

- `0006` through `0009`

### Before autonomous operation at scale

- `0010` through `0015`

### To complete governance coverage

- `0016` and `0017`

## Recommendation

Adopt this 17-ADR backlog as the canonical ADR program for the repository.

The original nine-item backlog in `docs/agentic-team.md` was directionally
correct but incomplete. The current documentation already assumes more than
nine architectural decisions. This proposal brings the ADR set into alignment
with the actual scope of the documented system.
