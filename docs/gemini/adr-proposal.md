# Proposal: ADR Backlog for Agentic Delivery System

**Date**: 2026-03-17
**Status**: Draft
**Context**: This document identifies the specific Architecture Decision Records (ADRs) required to formalize the system's design, resolve outstanding open questions (OQs), and unblock implementation.

---

## 1. Core Orchestration ADRs
These ADRs define the fundamental operating model of the agentic team and its automation.

| ADR # | Title | Purpose |
| --- | --- | --- |
| **ADR-01** | **Director Invocation Strategy** | Defines how the Director monitors Linear (Polling vs. Webhook). Affects latency and infrastructure complexity. (Resolves OQ-08) |
| **ADR-02** | **Retry and Failure Policy** | Establishes canonical backoff and escalation rules for agent failures across all roles to ensure system resilience. |
| **ADR-03** | **Execution Substrate** | Formalizes the relationship between high-level Director orchestration and the underlying sub-agent execution pipelines (e.g., Codex/Gemini/Claude). |
| **ADR-04** | **Progressive Task Promotion** | Defines how the Coordinator and Director dynamically promote issues from `Backlog` to `Selected` as dependencies complete. |
| **ADR-05** | **Concurrency and Locking** | Establishes the "Ticket Lock" and "Branch Namespace Lock" mechanisms to prevent agent collisions. (Resolves OQ-05, OQ-24) |

---

## 2. Security & Infrastructure ADRs
These ADRs govern how agents interact with external systems and the local execution environment.

| ADR # | Title | Purpose |
| --- | --- | --- |
| **ADR-06** | **Agent Auth & Secrets** | Defines how agents securely access Linear, GitHub, Graphite, and AWS. Establishes the security boundary for automated operations. (Resolves OQ-12) |
| **ADR-07** | **AWS Tool Scope** | Maps specific AWS operations (provisioning, secrets, deployment) to responsible agents. (Resolves OQ-09) |
| **ADR-08** | **Worktree & Branch Policy** | Standardizes the creation, isolation, and cleanup of git worktrees for concurrent agent sessions. |
| **ADR-09** | **Canonical Validation Command** | Formalizes the single command (e.g., `make validate`) used by agents and humans to enforce quality gates. (Resolves OQ-07) |

---

## 3. Workflow & Role ADRs
These ADRs ratify the specific phases and specialist roles within the delivery lifecycle.

| ADR # | Title | Purpose |
| --- | --- | --- |
| **ADR-10** | **Feature Draft Agent (Drafter)** | Ratifies the Drafter role and Phase 0.5 (Ideation). Justifies the structural exception of a human-invoked agent. (Resolves OQ-06) |
| **ADR-11** | **CTR Intake Standards** | Formalizes the "Draft Design Prompt" as the mandatory input for the Architect, separating ideation from formal planning. |
| **ADR-12** | **Linear State Machine** | Ratifies the nine-state model as the canonical single source of truth for execution state across the team. |

---

## 4. Governance & Quality ADRs
These ADRs define the standards for documentation, review, and project principles.

| ADR # | Title | Purpose |
| --- | --- | --- |
| **ADR-13** | **ADR Management Process** | Defines the ADR template (e.g., MADR) and the management workflow within `docs/adr/`. (Resolves OQ-29) |
| **ADR-14** | **Project Constitution Framework**| Defines the required sections and ratification process for the `.specify/memory/constitution.md` file. (Resolves OQ-31) |
| **ADR-15** | **PR & Traceability Standards** | Defines the mandatory sections for GitHub PR templates and how agents must link back to specs, plans, and tasks. (Resolves OQ-30) |

---

## Next Steps
1. Ratify **ADR-13 (ADR Management Process)** to establish the template.
2. Sequence the remaining ADRs based on the Phase 1 rollout requirements defined in `docs/agentic-team.md`.
3. Assign owners (human or agent) to draft each ADR for review.
