# Proposal: Canonical ADR Backlog for Agentic Delivery System

**Status**: Proposed
**Date**: 2026-03-17

## 1. Purpose

This document establishes the canonical backlog of Architecture Decision Records (ADRs) required to formalize the system's design, resolve outstanding misalignments across process documents, and provide a clear roadmap for implementation. Adoption of these ADRs is a prerequisite for moving the system from "Draft" to "Ratified" status.

## 2. Tier 1: Foundational Governance (Critical Path)

These five ADRs define the foundational decisions that all agent dispatch logic, planning gates, and process documents depend on. Nothing proceeds without these records.

| ID | Title | Purpose | Resolves |
| --- | --- | --- | --- |
| **ADR-001** | **ADR Management Process** | Defines the ADR template (MADR), directory structure (`docs/adr/`), and the append-only ratification policy. | OQ-03, OQ-29 |
| **ADR-002** | **Agentic Team Operating Model** | Ratifies the 7-agent lifecycle, role boundaries, and the principle of state-driven dispatch. | — |
| **ADR-003** | **Spec-Driven Development** | Establishes specification as the authoritative source of truth; code never reverse-engineers intent. | — |
| **ADR-004** | **Nine-State Linear State Machine** | Canonicalizes state names, the 8 gate transitions, and Linear as the system of record. | OQ-24 |
| **ADR-005** | **Feature Draft Agent (Drafter)** | Ratifies the pre-lifecycle intake exception and the CTR-based Draft Design Prompt. | OQ-06 |

## 3. Tier 2: Implementation Standards (Required for Pilot)

These ADRs must be ratified before any Engineer begins implementation work. They ensure consistency in code quality, review, and transport.

| ID | Title | Purpose | Resolves |
| --- | --- | --- | --- |
| **ADR-006** | **TDD as Default Practice** | Defines the Red-Green-Refactor cycle, when it applies, and how exceptions are approved. | OQ-19 |
| **ADR-007** | **Four-Tier Code Review Model** | Establishes the review sequence, the 3-state verdict model, and comment taxonomy. | OQ-28, OQ-32 |
| **ADR-008** | **Graphite Stacked PRs** | Defines the one-task-one-branch-one-PR unit and stack depth limits. | OQ-18 |
| **ADR-009** | **Compliance Gate Logic** | Formalizes the Director's pre-dispatch validation function and its failure behaviors. | — |
| **ADR-010** | **Canonical Validation Command** | Defines the single command (e.g., `make validate`) for all quality gate enforcement. | OQ-07 |

## 4. Tier 3: Autonomy & Infrastructure (Required for Phase 3/4)

These decisions govern the system's resilience and autonomous operations.

| ID | Title | Purpose | Resolves |
| --- | --- | --- | --- |
| **ADR-011** | **Director: Polling vs. Webhook** | Decides the orchestration trigger mechanism (latency vs. complexity). | OQ-08 |
| **ADR-012** | **Retry & Failure Policy** | Defines system-wide backoff, escalation, and lock reconciliation rules. | — |
| **ADR-013** | **Agent Auth & Secrets** | Establishes how agents securely access Linear, GitHub, Graphite, and AWS. | OQ-12 |
| **ADR-014** | **Concurrency & Locking** | Defines ticket locks, branch namespace locks, and acquisition/release rules. | OQ-05 |
| **ADR-015** | **Worktree Management Policy** | Defines creation, isolation, and cleanup rules for concurrent worktrees. | — |

## 5. Tier 4: Operational Governance

These records ensure long-term maintainability and consistent project principles.

| ID | Title | Purpose | Resolves |
| --- | --- | --- | --- |
| **ADR-016** | **Project Constitution Framework** | Defines the required sections and ratification process for the project Constitution. | OQ-31 |
| **ADR-017** | **PR & Traceability Standards** | Formalizes the PR template requirements and mandatory artifact linkage. | OQ-30 |

## 6. Implementation Strategy

1.  **Bootstrapping**: Execute **ADR-001** immediately to establish the ADR format.
2.  **Phase 1 Readiness**: Draft and ratify Tier 1 ADRs to stabilize the governance layer.
3.  **Pilot Readiness**: Draft and ratify Tier 2 ADRs to unblock the first end-to-end feature delivery.
4.  **Autonomy Readiness**: Tiers 3 and 4 should be drafted in parallel with early pilot implementation.
