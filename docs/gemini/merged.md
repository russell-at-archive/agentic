# Unified Agent Team Proposal for Autonomous Software Delivery

**Date**: 2026-03-16
**Status**: Draft — pending review and ADR elevation for significant decisions

---

## 1. Purpose & Philosophy

This document defines the production-ready operating model for a multi-agent software development team. It synthesizes system architecture, operational rigor, and engineering philosophy into a single cohesive standard.

### Design Principles
- **Spec-Driven Development**: Intent is clarified in plain text (`spec.md`, `plan.md`) before code is written. Agents rely on these artifacts to prevent hallucinations and scope creep.
- **State-Driven Dispatch**: Agents are invoked by Linear issue state, not by direct function calls. The Director reads state; state determines which agent acts.
- **Single Responsibility**: Each agent owns exactly one phase of the delivery lifecycle.
- **Evidence-Based Completion**: No state transition advances without required evidence (test output, linked PRs, approved artifacts).
- **Fail Loudly**: When an agent encounters a blocker or ambiguity, it documents it, moves the issue to `Blocked`, and stops. It does not improvise.
- **The Execution Log Protocol**: Agents must maintain an `## Execution Log` in Linear issue descriptions to ensure resumability, clear handoffs, and auditability.

---

## 2. Linear State Machine & Transitions

The following nine states are the canonical lifecycle states. Transitioning between them requires specific gate approvals.

| State | Phase | Meaning | Owner |
| --- | --- | --- | --- |
| `Draft` | Planning | Feature created; Architect not yet assigned | Director |
| `Planning` | Planning | Architect producing planning artifacts | Architect |
| `Plan Review` | Planning | Plan PR open; awaiting human approval | Architect |
| `Backlog` | Scheduling | Plan accepted; Coordinator scheduling | Coordinator |
| `Selected` | Implementation | Ready for implementation; dependencies met | Engineer |
| `In Progress` | Implementation | Engineer actively implementing | Engineer |
| `In Review` | Review | Graphite stack published; PR under review | Tech Lead |
| `Done` | Complete | PR merged; evidence attached; rollup complete | Director |
| `Blocked` | Any | Work halted; blocker documented | Any |

### Allowed Transitions
- `Draft` → `Planning` (Director assigns Architect).
- `Planning` → `Plan Review` (Architect links plan artifact PR).
- `Plan Review` → `Backlog` (Human approves Plan PR).
- `Backlog` → `Selected` (Coordinator promotes based on dependency resolution).
- `Selected` → `In Progress` (Engineer claims lock and creates branch).
- `In Progress` → `In Review` (Engineer submits PR stack).
- `In Review` → `Done` (Tech Lead approves; PR merged).
- `In Review` → `In Progress` (Tech Lead requests revisions).

---

## 3. Agent Roster & Strict Contracts

### 1. Director (The Orchestrator)
- **Mission**: System entry point, intake prioritization, agent dispatch, and policy enforcement.
- **Inputs**: Linear issues in `Draft`, `Backlog`, `Selected`, `In Review`, or `Done`.
- **Preconditions**: Valid project mapping and run policy config.
- **Outputs**: Agent session invocation, final completion rollup confirmation.
- **Failure Policy**: Retry transient API errors; on persistent failure, mark target issue `Blocked`.
- **Model Effort**: **Low**. Primarily routing and rule enforcement.

### 2. Architect (The Planner)
- **Mission**: Transform broad requests into executable plans, specs, and tasks.
- **Inputs**: Ticket in `Planning`, raw product intent.
- **Preconditions**: Objective is defined.
- **Outputs**: `spec.md`, `plan.md`, `tasks.md`, ADRs, and a Plan PR.
- **Exit Criteria**: Plan PR opened.
- **Model Effort**: **High**. Complex reasoning, system design, and technical writing.

### 3. Coordinator (The Scheduler)
- **Mission**: Convert approved plans into dependency-safe Linear tickets.
- **Inputs**: Accepted plan bundle (`tasks.md`).
- **Preconditions**: Parent ticket in `Backlog`.
- **Outputs**: Child Linear tickets with task IDs, parent-child links, and dependency mapping.
- **Exit Criteria**: Tickets created; unblocked tasks moved to `Selected`.
- **Model Effort**: **Low**. Data mapping and API graph construction.

### 4. Engineer (The Implementer)
- **Mission**: Implement exactly one scoped task via disciplined Red-Green-Refactor TDD.
- **Inputs**: Ticket in `Selected`, parent `plan.md` and `spec.md`.
- **Preconditions**: All upstream dependencies are `Done`. Repository clean.
- **Outputs**: Code, passing tests, execution log, and a Graphite stacked PR.
- **Exit Criteria**: Local validation passes (build/lint/type/test); PR opened; ticket moved to `In Review`.
- **Model Effort**: **High**. Code generation, context assimilation, and test debugging.

### 5. Technical Lead (The Reviewer)
- **Mission**: Enforce quality, architecture, and merge readiness through 4-tier review.
- **Inputs**: PR chain, linked issue, linked planning artifacts.
- **Preconditions**: Ticket in `In Review`; automated validation (CI) is green or locally evidenced.
- **Outputs**: Review verdict (`approve`, `revise`, `reject`), blocking/optional findings.
- **Exit Criteria**: Ticket approved and moved to `Done`, or findings documented and moved to `In Progress`.
- **Model Effort**: **High**. Nuanced logic evaluation and architectural integrity checks.

### 6. Explorer (The Researcher)
- **Mission**: Produce source-backed research to reduce uncertainty.
- **Inputs**: Research question, scope constraints.
- **Preconditions**: Invoked by Architect (during planning) or Human.
- **Outputs**: `research.md` report with citations, risk identification, and recommendations.
- **Model Effort**: **Medium**. Data synthesis and summarization (requires web search).

---

## 4. Cross-Cutting Control Agents

To ensure the primary agents remain focused, two background agents operate continuously:
1. **Compliance Gate**: Validates required artifacts before any state transition (e.g., ensuring ADR links exist if architecture is touched).
2. **Metrics Reporter**: Publishes SLO data per cycle (Lead time, Review latency, Defect escape rates, Agent retry counts).

---

## 5. System Architecture & Execution Model

### Orchestration vs. Pipeline Substrate
The **Director** serves as the system-level orchestrator polling Linear. When it identifies actionable work, it spawns an agent session (e.g., an Engineer session). This spawned session may internally utilize a multi-agent framework (like the Codex sub-agent pipeline) to perform iterative local reasoning before returning the final state to Linear.

### Concurrency & Locking Model
- **Tickets**: One Engineer per ticket. Lock acquired on `Selected` → `In Progress`.
- **Branches**: Graphite branch namespace lock acquired on first PR in stack.
- **Parallelism**: Multiple independent Explorer tasks or Engineer tasks (on disjoint branch paths) may run simultaneously.
- **Release**: Locks released on `Done`, cancellation, or explicit Director recovery.

### Incident and Recovery Procedures
- **Stale Locks / Crashed Agents**: The Director runs a periodic lock-reconciliation check. If an agent execution log hasn't updated in 4 hours, the issue is flagged for human triage.
- **Broken PR Stacks**: If upstream frames change, the Engineer is explicitly dispatched to run `gt restack` and re-validate before writing new code.
- **Worktree Lifecycle**: Isolated git worktrees are created per task. If an Engineer agent fails permanently, the worktree is retained for forensic review until manually cleared or a retry is initiated.

---

## 6. Tool Assignments Matrix

| Tool | Agents Utilizing |
| --- | --- |
| **Linear API** | Director, Architect, Coordinator, Engineer, Tech Lead, Control Agents |
| **GitHub (Read)** | Architect, Engineer, Tech Lead, Explorer |
| **GitHub (Write)** | Architect, Engineer, Tech Lead |
| **Graphite CLI (`gt`)** | Engineer, Tech Lead |
| **GitHub Speckit** | Architect |
| **Web Search** | Explorer |
| **AWS** | *Requires ADR (Currently unassigned)* |

---

## 7. Action Plan & Rollout

### Required ADR Backlog
Before implementation, the following Architecture Decision Records must be authored:
1. **Director Invocation Method**: Polling vs. Linear Webhooks.
2. **Authentication & Secrets Strategy**: Managing agent access to GitHub, Linear, Graphite, and AWS.
3. **AWS Operations Scope**: Defining what infrastructure automation agents are permitted to touch.
4. **Agent Orchestration Substrate**: Formalizing the relationship between the Linear-polling Director and local CLI agent pipelines (Codex/Claude/Gemini CLIs).

### Phased Rollout Plan
- **Phase 1: Governance & Artifacts**: Finalize role contracts, Speckit templates, and state machine rules.
- **Phase 2: Planning Automation**: Implement the Director, Architect, and Coordinator flows.
- **Phase 3: Implementation Automation**: Implement the Engineer and Technical Lead flows with local tool and Graphite integrations.
- **Phase 4: Resilience & Optimization**: Add lock reconciliation, error backoff strategies, and the Metrics Reporter agent.