# ADR Backlog: Agentic Delivery System

**Date**: 2026-03-17
**Status**: Proposed

---

## Overview

`docs/adr/` exists but contains no ADRs. The system's own mandate requires ADRs for
cross-cutting patterns, shared APIs, platform-wide infrastructure, long-lived direction,
and compatibility strategy. Nine ADRs are required before implementation begins; twelve
more are required before full autonomous operation.

This document identifies all twenty-two ADRs needed to cover the decisions already
encoded in the process documentation. They are organized into four tiers by what they
unblock. The meta-ADR (0001) must precede all others because it defines the format and
criteria every subsequent ADR must satisfy.

---

## Tier 0 — Meta

### ADR-0001: Record Architectural Decisions

Establish ADRs as the repository's canonical decision record. Define the `docs/adr/`
directory, the MADR format, the append-only policy, the criteria for when an ADR is
required (cross-cutting patterns, shared APIs, platform-wide infrastructure, long-lived
direction, compatibility strategy), and what blocks merge when a required ADR is absent.
Resolves OQ-03 and OQ-29.

**Write this first. Nothing else can be formatted correctly without it.**

---

## Tier 1 — Foundational

Required before any planning or specification work begins. These five ADRs define the
operating model, methodology, and state machine that every other decision builds on.

### ADR-0002: Adopt Agentic Team Operating Model

Ratify the multi-agent operating model as the repository's canonical delivery approach.
Covers state-driven dispatch, role boundaries, compliance gate enforcement, fail-loudly
protocol, evidence-based completion, no-silent-scope-expansion, and the execution log
standard. This is the umbrella decision; subsequent ADRs capture specific mechanisms
within it.

### ADR-0003: Spec-Driven Development as Primary Methodology

Ratify the commitment that specification is the authoritative source of truth, code
never reverse-engineers intent, and the spec-first discipline reduces agent hallucination
and increases delivery fidelity. Covers the six-phase planning lifecycle, gate
requirements between phases, and why formal spec is required before implementation
begins.

### ADR-0004: Nine-State Linear State Machine and Eight Gate Rules

Ratify the canonical nine-state model (`Draft` → `Planning` → `Plan Review` →
`Backlog` → `Selected` → `In Progress` → `Blocked` → `In Review` → `Done`) as the
single source of truth for live execution state. Covers the eight gate transitions with
their preconditions, `Blocked` as a returnable state from any active state, and Linear
as the system of record. Resolves OQ-24.

### ADR-0005: Feature Draft Agent as Pre-Lifecycle Intake Exception

Ratify the structural exception — the only role in the system that is human-invoked
rather than Director-dispatched, operates before the first Linear issue exists, and
creates the `Draft` artifact that starts the state machine. Justifies why no new Linear
state is added (`Idea` or `Drafting`) and defines the minimum quality bar required
before a `Draft` issue may be created. Resolves OQ-06.

### ADR-0006: CTR as Planning and Intake Method

Ratify CTR (Context, Task, Refine) as the canonical method for both planning (Architect,
engineering perspective) and intake (Drafter, product and stakeholder perspective).
Covers the dual meaning of each pass by role, why "Refine" is the canonical name for
the third pass, what decision-completeness means for an implementer, and the separation
between ideation and formal specification. Covers the Draft Design Prompt as the
mandatory handoff artifact from Drafter to Architect.

---

## Tier 2 — Required Before Implementation Begins

Required before any Engineer begins implementation work. These four ADRs define the
implementation conventions and quality gates every PR must satisfy.

### ADR-0007: Test-Driven Development as Default Implementation Practice

Ratify the Red-Green-Refactor cycle as the default for all new behavior. Covers how TDD
applies by change type (new behavior, bug fix, refactor, infrastructure), when
exceptions are permitted, who approves exceptions and where approval is recorded, and
the hard gate requiring a full local validation pass before any PR is opened. Resolves
OQ-19.

### ADR-0008: Graphite Stacked PRs and One-Task-One-PR Convention

Ratify Graphite as the stacked PR transport layer. Covers one-task-one-branch-one-stack-
frame-one-PR as the default unit of work, stack depth limits (soft cap: 3–4 frames
before forced split), merge order (bottom-up), when stacking is required vs. when tasks
should be separate branches, and the branch and commit naming conventions
(`<linear-id>-t-<##>-<short-slug>`). Resolves OQ-18.

### ADR-0009: Four-Tier Code Review and Three-State Verdict

Ratify the four-tier review sequence (Automated Validation → Implementation Fidelity →
Architectural Integrity → Final Polish), the `reject`/`revise`/`approve` verdict model,
the comment taxonomy (`blocking:`, `question:`, `suggestion:`, `note:`), Tier 3
escalation requirements for high-risk changes (auth, persistence, migration, distributed
workflow, platform boundaries), the eight blocker conditions, and review service level
targets.

### ADR-0010: Compliance Gate Enforcement Before Agent Dispatch

Ratify the Director's pre-dispatch validation function as a mandatory, non-skippable
gate before every agent invocation. Covers what the gate checks at each state (required
artifacts, defined assignee, upstream dependency completion, evidence attachment),
behavior on failure (move to `Blocked`, document reason), and why no agent or human
override may bypass the gate.

---

## Tier 3 — Required Before Full Autonomy

Required before the system operates without human supervision. These eight ADRs cover
the operational mechanics of orchestration, resilience, security, and infrastructure.

### ADR-0011: Director Orchestration Model — Polling vs. Webhook

Decide between 5-minute polling (simpler, lower infrastructure cost) and webhook-driven
dispatch (lower latency, higher infrastructure complexity). Covers the tradeoff analysis,
selected approach, fallback behavior during webhook outage if webhooks are chosen, and
polling interval configuration. Resolves OQ-08.

### ADR-0012: Retry, Failure Recovery, and Session Crash Handling

Define the system-wide retry and escalation model. Covers exponential backoff bounds,
the condition under which exhausted retries move an issue to `Blocked`, session crash
recovery via stale execution log detection, Director behavior on detecting a crashed
in-progress session, and lock orphan handling.

### ADR-0013: Concurrency, Ticket Locking, and Branch Namespace

Define the ticket lock and branch namespace lock mechanisms that prevent agent collisions
on concurrent tasks. Covers lock acquisition rules (at `Selected` → `In Progress`),
release rules (at `Done`, cancellation, or Director recovery), lock reconciliation
procedure (requires human confirmation), and the policy for multiple Engineers working
simultaneously on independent tasks. Resolves OQ-05 and OQ-24.

### ADR-0014: Progressive Task Promotion Mechanism

Define how the Coordinator promotes dependent tasks from `Backlog` to `Selected` as
upstream tasks reach `Done`. Covers the trigger condition, the dependency resolution
algorithm, and the guarantees required before promotion (all upstream tasks `Done`, no
active locks on shared subsystems).

### ADR-0015: Execution Substrate — Director and Sub-Agent Runtime Relationship

Formalize the relationship between the Director as system-level orchestrator and the
platform-specific sub-agent runtimes (Claude Code, Codex, Gemini). Covers how the
Director selects and invokes sub-agents per platform, context isolation guarantees,
session lifecycle, and behavior when the execution substrate is unavailable.

### ADR-0016: Agent Authentication and Secrets Management

Define how agents authenticate to Linear, GitHub, Graphite, and AWS. Covers token and
secret handling boundaries (what each agent may read and write), how secrets are
provisioned to agent sessions, rotation policy, and the security boundary for automated
operations. Resolves OQ-12.

### ADR-0017: AWS Tool Scope and Agent Ownership

Define which AWS operations are in scope for agents and which specific agent owns each
category (provisioning, secrets, deployment, observability). Covers the authorization
boundary for automated AWS access and the escalation path when AWS operations fail.
Resolves OQ-09.

### ADR-0018: Worktree Creation, Isolation, and Cleanup Policy

Standardize the lifecycle of git worktrees for concurrent Engineer sessions. Covers
creation at task start, retention through PR merge, cleanup after merge, recreation on
task rejection requiring restart, and isolation guarantees between concurrent worktrees.

---

## Tier 4 — Complete the Record

Not immediate blockers, but required for a self-consistent ADR record that covers all
decisions the current process documentation already depends on.

### ADR-0019: Constitution Governance and Minimum Contents

Define what the Constitution (`.specify/memory/constitution.md`) is, what sections it
must contain, who ratifies it, when it is evaluated (Constitution Check during
planning), and what happens when a plan violates it. Distinguishes between the
structural decision (this ADR) and the actual engineering principles (the Constitution
document itself). Resolves OQ-31.

### ADR-0020: Canonical Validation Command and Merge Gate Policy

Define the single invocable validation command (e.g., `make validate`) that both agents
and humans use to enforce the local quality gate. Covers what the command must execute
(tests, lint, type checks, build), the policy for divergence between a local pass and a
CI failure, and coverage threshold requirements. Resolves OQ-07 and OQ-13.

### ADR-0021: Pull Request Template and Traceability Standard

Define the mandatory sections of the GitHub PR template: traceability links (spec, plan,
task, Linear issue), validation evidence, deviation justification, and reviewer verdict.
Covers how agents must populate the template and which missing sections constitute a
review blocker. Resolves OQ-30.

### ADR-0022: Classification Taxonomy and Planning Depth

Ratify the five classification types (`feature`, `bug fix`, `refactor`,
`dependency/update`, `architecture/platform`) and define how classification determines
planning depth per type. Covers which types require full spec/plan/tasks, which allow
abbreviated planning, and the Drafter's obligation to classify before creating a `Draft`
issue.

---

## Summary Table

| ID | Title | Tier | Resolves |
|----|-------|------|---------|
| ADR-0001 | Record Architectural Decisions | 0 | OQ-03, OQ-29 |
| ADR-0002 | Adopt Agentic Team Operating Model | 1 | — |
| ADR-0003 | Spec-Driven Development as Primary Methodology | 1 | — |
| ADR-0004 | Nine-State Linear State Machine and Eight Gate Rules | 1 | OQ-24 partial |
| ADR-0005 | Feature Draft Agent as Pre-Lifecycle Intake Exception | 1 | OQ-06 |
| ADR-0006 | CTR as Planning and Intake Method | 1 | — |
| ADR-0007 | Test-Driven Development as Default | 2 | OQ-19 |
| ADR-0008 | Graphite Stacked PRs and One-Task-One-PR Convention | 2 | OQ-18 |
| ADR-0009 | Four-Tier Code Review and Three-State Verdict | 2 | OQ-32 partial |
| ADR-0010 | Compliance Gate Enforcement Before Dispatch | 2 | — |
| ADR-0011 | Director Orchestration Model — Polling vs. Webhook | 3 | OQ-08 |
| ADR-0012 | Retry, Failure Recovery, and Session Crash Handling | 3 | — |
| ADR-0013 | Concurrency, Ticket Locking, and Branch Namespace | 3 | OQ-05, OQ-24 |
| ADR-0014 | Progressive Task Promotion Mechanism | 3 | — |
| ADR-0015 | Execution Substrate — Director and Sub-Agent Runtime | 3 | — |
| ADR-0016 | Agent Authentication and Secrets Management | 3 | OQ-12 |
| ADR-0017 | AWS Tool Scope and Agent Ownership | 3 | OQ-09 |
| ADR-0018 | Worktree Creation, Isolation, and Cleanup Policy | 3 | — |
| ADR-0019 | Constitution Governance and Minimum Contents | 4 | OQ-31 |
| ADR-0020 | Canonical Validation Command and Merge Gate Policy | 4 | OQ-07, OQ-13 |
| ADR-0021 | Pull Request Template and Traceability Standard | 4 | OQ-30 |
| ADR-0022 | Classification Taxonomy and Planning Depth | 4 | — |

---

## Recommended Creation Order

Write in this sequence. Each ADR may reference those before it.

```
0001-record-architectural-decisions.md
0002-adopt-agentic-team-operating-model.md
0003-spec-driven-development-as-primary-methodology.md
0004-nine-state-linear-state-machine-and-gate-rules.md
0005-feature-draft-agent-as-pre-lifecycle-intake-exception.md
0006-ctr-as-planning-and-intake-method.md
0007-test-driven-development-as-default.md
0008-graphite-stacked-prs-and-one-task-one-pr-convention.md
0009-four-tier-code-review-and-three-state-verdict.md
0010-compliance-gate-enforcement-before-dispatch.md
0011-director-orchestration-model-polling-vs-webhook.md
0012-retry-failure-recovery-and-session-crash-handling.md
0013-concurrency-ticket-locking-and-branch-namespace.md
0014-progressive-task-promotion-mechanism.md
0015-execution-substrate-director-and-sub-agent-runtime.md
0016-agent-authentication-and-secrets-management.md
0017-aws-tool-scope-and-agent-ownership.md
0018-worktree-creation-isolation-and-cleanup-policy.md
0019-constitution-governance-and-minimum-contents.md
0020-canonical-validation-command-and-merge-gate-policy.md
0021-pull-request-template-and-traceability-standard.md
0022-classification-taxonomy-and-planning-depth.md
```

---

## Minimum vs. Full Creation Strategy

**Minimum set — unblocks implementation (Tiers 0–2):** ADR-0001 through ADR-0010.
These ten cover every decision required before an Engineer can begin work under human
supervision.

**Full set — unblocks full autonomy (all tiers):** ADR-0001 through ADR-0022. Required
before the system operates without human supervision on a production delivery cycle.

---

## Next Steps

1. Write **ADR-0001** to establish the format and criteria all subsequent ADRs must use.
2. Assign an owner (human or Architect agent) to each ADR in Tiers 0–2.
3. Sequence remaining ADRs against the Phase 1 rollout plan in `docs/agentic-team.md`.
4. Update `docs/open-questions.md` as each ADR resolves its listed OQs.
