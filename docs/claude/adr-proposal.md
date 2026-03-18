# ADR Proposal: Required Architecture Decision Records

**Date**: 2026-03-17
**Status**: Proposed

---

## Overview

The `docs/adr/` directory exists but contains no ADRs. The system's own mandate
requires ADRs for cross-cutting patterns, shared APIs, platform-wide infrastructure,
long-lived direction, and compatibility strategy. `AGENTS.md` explicitly lists nine ADRs
as required before implementation begins.

This document identifies all fifteen ADRs that need to be written, organized by tier
based on what they unblock.

---

## Tier 1 — Critical Blockers

Nothing proceeds without these five. They define the foundational decisions that all
agent dispatch logic, planning gates, and process documents depend on.

### ADR-001: Seven-Agent Delivery Lifecycle

Covers the full agent roster, phase assignments, single-responsibility enforcement, and
the principle that agents refuse to act outside their required entry state. This is the
foundational architectural decision the entire system rests on.

### ADR-002: Spec-Driven Development as Primary Methodology

Covers the commitment that specification is the authoritative source of truth, code
never reverse-engineers intent, and that the spec-first discipline reduces agent
hallucination. Governs every planning decision downstream.

### ADR-003: Nine-State Linear State Machine and Eight Gate Rules

Covers the canonical state names, the eight gate transitions with their preconditions,
`Blocked` as a returnable state, evidence-based completion, and Linear as the system of
record. Every agent's dispatch logic depends on this.

### ADR-004: Feature Draft Agent as Pre-Lifecycle Intake Exception

Covers the structural exception — the only role in the system that is human-invoked
rather than Director-dispatched, operates before the first Linear issue exists, and
creates the `Draft` artifact that starts the state machine. Explicitly called out across
multiple documents as requiring an ADR before adoption.

### ADR-005: CTR Planning Method (Context, Task, Refine)

Covers the dual use of CTR (engineering perspective for the Architect; product and
stakeholder perspective for the Drafter), why "Refine" is the canonical name for the
third pass, and what decision-completeness means for an implementer.

---

## Tier 2 — Required Before Implementation Begins

These four must exist before any Engineer begins implementation work.

### ADR-006: Test-Driven Development as Default Implementation Practice

Covers the Red-Green-Refactor cycle, when TDD applies by change type (new behavior, bug
fix, refactor, infrastructure), when exceptions are allowed, and who approves
exceptions. Resolves OQ-19.

### ADR-007: Four-Tier Code Review Model and Three-State Verdict

Covers the four-tier review sequence, the `reject`/`revise`/`approve` verdict model,
comment taxonomy (`blocking:`, `question:`, `suggestion:`, `note:`), Tier 3 escalation
for high-risk changes, and the eight blocker conditions. Cross-cutting impact on every
PR in the system.

### ADR-008: Graphite Stacked PRs as Implementation Transport

Covers one-task-one-branch-one-stack-frame-one-PR as the default unit, stack depth
limits, merge order (bottom-up), when to stack vs. separate, and the branch naming
convention. Resolves OQ-18.

### ADR-009: Compliance Gate Enforcement Before Agent Dispatch

Covers the Director's pre-dispatch validation function, what it checks, what happens on
failure (move to `Blocked`, document reason), and why no agent may skip the gate.
Referenced throughout the documentation but never consolidated in one place.

---

## Tier 3 — Required Before Full Autonomy

These four are needed before the system operates autonomously without human supervision.

### ADR-010: Director Orchestration Model — Polling vs. Webhook

Explicitly listed as ADR Backlog Item #1 in `AGENTS.md`. Covers the choice between
5-minute polling (simpler, current default) and webhook-driven dispatch (lower latency,
higher infrastructure complexity). Resolves OQ-08.

### ADR-011: Failure Recovery, Retry Policy, and Lock Reconciliation

Explicitly listed as ADR Backlog Item #2 in `AGENTS.md`. Covers exponential backoff
bounds, the condition under which exhausted retries move an issue to `Blocked`, orphaned
lock detection and reconciliation, and session crash recovery via stale execution log
detection.

### ADR-012: One Task = One Branch = One PR as Default Unit of Work

Covers why this is the default, what qualifies as a valid exception, how the Coordinator
maps `tasks.md` entries to Linear issues one-to-one, and how Graphite stack order
mirrors task dependency order.

### ADR-013: Constitution as Non-Negotiable Governance Artifact

Covers what the Constitution is, where it lives (`.specify/memory/constitution.md`),
what it must contain, who ratifies it, when it is evaluated (Constitution Check during
planning), and what happens when a plan violates it. Resolves OQ-31 for the structural
decision; the actual content of the Constitution is a separate document.

---

## Tier 4 — Operational Decisions Worth Capturing

These two are not blockers but are required for a complete, self-consistent ADR record.

### ADR-014: Classification Taxonomy and Planning Depth

Covers the five classification types (`feature`, `bug fix`, `refactor`,
`dependency/update`, `architecture/platform`), how classification determines planning
depth per type, and how the Feature Draft Agent must classify before creating a `Draft`
issue.

### ADR-015: ADR Requirement Policy (meta-ADR)

The meta-ADR. Covers the criteria for when an ADR is required (cross-cutting patterns,
shared APIs, platform-wide infrastructure, long-lived direction, compatibility
strategy), where ADRs live (`docs/adr/`), what format they use, and what blocks merge
when a required ADR is absent. Resolves OQ-03.

---

## Summary Table

| ID | Title | Tier | Resolves |
|----|-------|------|---------|
| ADR-001 | Seven-Agent Delivery Lifecycle | 1 | — |
| ADR-002 | Spec-Driven Development as Primary Methodology | 1 | — |
| ADR-003 | Nine-State Linear State Machine and Eight Gate Rules | 1 | OQ-24 |
| ADR-004 | Feature Draft Agent as Pre-Lifecycle Intake Exception | 1 | OQ-06 |
| ADR-005 | CTR Planning Method | 1 | — |
| ADR-006 | Test-Driven Development as Default | 2 | OQ-19 |
| ADR-007 | Four-Tier Review Model and Three-State Verdict | 2 | OQ-32 partial |
| ADR-008 | Graphite Stacked PRs as Implementation Transport | 2 | OQ-18 |
| ADR-009 | Compliance Gate Enforcement Before Dispatch | 2 | — |
| ADR-010 | Director Orchestration Model — Polling vs. Webhook | 3 | OQ-08 |
| ADR-011 | Failure Recovery, Retry Policy, and Lock Reconciliation | 3 | — |
| ADR-012 | One Task = One Branch = One PR | 3 | — |
| ADR-013 | Constitution as Governance Artifact | 3 | OQ-31 |
| ADR-014 | Classification Taxonomy and Planning Depth | 4 | — |
| ADR-015 | ADR Requirement Policy (meta-ADR) | 4 | OQ-03 |

---

## Sequencing Note

`AGENTS.md` states nine ADRs are required before implementation begins. That maps to
Tiers 1 and 2 (ADR-001 through ADR-009). Tiers 3 and 4 are needed before full
autonomous operation but not before a human-supervised implementation pilot.

ADR-015 (the meta-ADR) should be written first or in parallel with ADR-001, since it
defines the format all other ADRs must follow.
