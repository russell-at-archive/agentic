# ADR Proposal List

## Purpose

This document lists the specific ADRs that should be created to cover the
architectural and workflow decisions already encoded in the repository's
process documents.

The current process docs depend on these decisions, but `docs/adr/` is still
empty. This list is intended to provide an ordered ADR creation plan.

## Foundational ADRs

### 0001: Record Architectural Decisions

Establish ADRs as the repository's architectural decision record, define the
directory, and standardize the format and append-only policy.

### 0002: Adopt Agentic Team Operating Model

Ratify the multi-agent operating model in `docs/agentic-team.md`, including
state-driven dispatch, role boundaries, compliance gates, and failure handling.

## Newly Decided Role and Workflow ADRs

### 0003: Add Feature Draft Agent

Capture the decision to add a human-invoked pre-lifecycle Feature Draft Agent
that creates planning-ready `Draft` issues using a CTR-based Draft Design
Prompt, without adding a new Linear state.

### 0004: Linear State Machine as Canonical Tracking Standard

Ratify Linear as the system of record for live execution state and adopt the
canonical state machine defined in `docs/tracking-process.md`.

### 0005: Adopt Spec-Driven Planning Process

Ratify the spec-first planning workflow, the planning gates, and the artifact
model defined in `docs/planning-process.md`.

### 0006: Adopt Software Review Process

Ratify the four-tier software review model and merge-readiness standards
defined in `docs/review-process.md`.

## ADR Backlog Already Called Out in the Docs

### 0007: Director Invocation, Polling vs Webhook

Decide whether the Director runs on polling, webhook dispatch, or a hybrid
model. This affects latency, infrastructure complexity, and operational cost.

### 0008: Retry and Failure Escalation Policy

Define the system-wide retry, backoff, and escalation model for agent and API
failures.

### 0009: Codex Pipeline as Internal Execution Substrate

Formalize the relationship between the Director as the system-level
orchestrator and Codex as a per-session internal execution substrate.

### 0010: Progressive Task Promotion Mechanism

Define how the Coordinator promotes dependent tasks as upstream tasks are
completed.

### 0011: Agent Authentication and Secrets Management

Decide how agents authenticate to Linear, GitHub, Graphite, AWS, and other
systems, including token and secret handling boundaries.

### 0012: AWS Tool Scope and Agent Ownership

Define which AWS operations are in scope for agents and which specific agent or
agents own them.

### 0013: Worktree Management Policy

Define creation, isolation, retention, and cleanup rules for concurrent
Engineer worktrees.

### 0014: Concurrency and Locking Semantics

Define ticket locks, branch namespace locks, acquisition and release rules, and
lock recovery behavior.

## Additional ADRs Strongly Implied by Current Docs

### 0015: Constitution Governance and Minimum Contents

The Constitution is a hard gate throughout the planning flow, but the docs do
not yet define who ratifies it, what its minimum sections are, or how it is
maintained.

### 0016: Canonical Validation Command and Merge Gate Policy

The implementation and review docs assume one standard validation command and a
clear policy for local validation versus CI as merge gates.

### 0017: Pull Request Template and Traceability Standard

The review and planning model depend on consistent PR structure for
traceability, validation evidence, and reviewer verdicts, but that decision is
not yet captured as architecture.

## Recommended Creation Order

1. `0001-record-architectural-decisions.md`
2. `0002-adopt-agentic-team-operating-model.md`
3. `0003-add-feature-draft-agent.md`
4. `0004-linear-state-machine-as-canonical-tracking-standard.md`
5. `0005-adopt-spec-driven-planning-process.md`
6. `0006-adopt-software-review-process.md`
7. `0007-director-invocation-polling-vs-webhook.md`
8. `0008-retry-and-failure-escalation-policy.md`
9. `0009-codex-pipeline-as-internal-execution-substrate.md`
10. `0010-progressive-task-promotion-mechanism.md`
11. `0011-agent-authentication-and-secrets-management.md`
12. `0012-aws-tool-scope-and-agent-ownership.md`
13. `0013-worktree-management-policy.md`
14. `0014-concurrency-and-locking-semantics.md`
15. `0015-constitution-governance-and-minimum-contents.md`
16. `0016-canonical-validation-command-and-merge-gate-policy.md`
17. `0017-pull-request-template-and-traceability-standard.md`

## Recommendation

If the goal is the minimum strict set needed to cover the currently explicit ADR
backlog, create `0001` through `0014`.

If the goal is to cover the full set of decisions the current docs already
depend on, create `0001` through `0017`.
