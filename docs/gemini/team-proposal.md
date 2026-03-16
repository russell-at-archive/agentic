# Team Proposal: Autonomous Agentic Software Engineering

This document proposes a detailed structure and workflow for a team of autonomous agents designed to perform software engineering tasks. It synthesizes and extends the initial concepts in `docs/design.md` with the rigorous processes defined in the project's planning, implementation, tracking, and review documentation.

## Core Philosophy

The team operates on the principle of **Spec-Driven Development**, where intent is clarified in plain text before code is written. This minimizes ambiguity, reduces hallucinations in AI agents, and ensures a traceable record from business requirements to delivered code.

## Agent Team Roles

### 1. Director (The Foreman)
The Director is the central orchestrator and entry point for the system. It manages the high-level lifecycle and delegates to specialized agents.

- **Primary Responsibility**: Poll Linear, identify state transitions, and invoke the appropriate agent.
- **Key Functions**:
    - Monitor Linear for issues in trigger states.
    - Confirm preconditions (Gates) are met before delegation.
    - Verify completion rollup and evidence before moving issues to `Done`.
    - Handle session initialization and teardown for other agents.
- **Entry State**: Any state (as the observer); specifically triggers on `Draft`, `Backlog`, `Selected`, `In Review`, and `Done` (for final verification).

### 2. Architect (The Planner)
The Architect transforms high-level requests into executable engineering plans.

- **Primary Responsibility**: Produce the "What" and "How" of a feature using GitHub Speckit.
- **Key Functions**:
    - Create/Update `spec.md`, `plan.md`, and `tasks.md`.
    - Author Architecture Decision Records (ADRs) for significant changes.
    - Structure tasks for atomic, reviewable Graphite stacked PRs.
    - Run `/speckit.analyze` to ensure consistency.
    - Open the Planning PR for human/TL review.
- **Tooling**: GitHub Speckit (`.specify/`), ADR templates.
- **Entry State**: `Draft` -> `Planning`.
- **Exit State**: `Plan Review`.

### 3. Coordinator (The Scheduler)
The Coordinator bridges the gap between a technical plan and a trackable execution backlog.

- **Primary Responsibility**: Decompose a merged plan into actionable Linear issues.
- **Key Functions**:
    - Create one Linear issue per task defined in `tasks.md`.
    - Map task IDs (T-01) to Linear IDs (ARC-42).
    - Link issues to parent artifacts (`spec.md`, `plan.md`).
    - Promote issues to `Selected` once their dependencies are `Done`.
- **Tooling**: Linear API/CLI.
- **Entry State**: `Backlog`.
- **Exit State**: `Selected` (for ready tasks) or `Backlog` (for dependent tasks).

### 4. Engineer (The Implementer)
The Engineer executes the approved plan using disciplined, test-driven development.

- **Primary Responsibility**: Implement specific tasks and submit for review.
- **Key Functions**:
    - Create isolated worktrees and Graphite branches.
    - Follow the Red-Green-Refactor (TDD) cycle.
    - Maintain Graphite stack discipline (stacking only on true dependencies).
    - Perform the "Full Local Validation Pass" (Build, Lint, Type Check, Test).
    - Open Graphite PRs with full traceability links.
- **Tooling**: Graphite (`gt`), Local Test Runners, Linters, Type Checkers.
- **Entry State**: `Selected` -> `In Progress`.
- **Exit State**: `In Review`.

### 5. Technical Lead (The Reviewer)
The Technical Lead ensures that implementations are safe, correct, and align with the plan.

- **Primary Responsibility**: Perform multi-tier reviews of submitted PRs.
- **Key Functions**:
    - Verify Tier 1 (Automated Validation) and Tier 2 (Implementation Fidelity).
    - Perform Tier 3 (Architectural Integrity) and Tier 4 (Final Polish) reviews.
    - Provide blocking (`blocking:`), inquisitive (`question:`), or suggestive (`suggestion:`) feedback.
    - Approve or Reject/Revise PRs based on confidence.
- **Entry State**: `In Review`.
- **Exit State**: `Done` (Approval) or `In Progress` (Revision required).

### 6. Explorer (The Researcher)
The Explorer provides deep-dive technical research on demand.

- **Primary Responsibility**: Resolve technical unknowns during the Research phase of planning.
- **Key Functions**:
    - Investigate libraries, APIs, or architectural patterns.
    - Produce `research.md` with source citations.
    - Identify risks and proposed mitigations.
- **Trigger**: Invoked by Architect during Planning or when a task hits a `Blocked` state due to technical unknowns.

---

## Workflow Integration

### Linear State Machine
The team synchronizes through a strict 9-state Linear workflow:

1.  **Draft**: Initial request.
2.  **Planning**: Architect is active.
3.  **Plan Review**: Human/TL reviews the Speckit artifacts.
4.  **Backlog**: Plan is merged; Coordinator is active.
5.  **Selected**: Task is ready for implementation.
6.  **In Progress**: Engineer is active.
7.  **In Review**: Technical Lead is active.
8.  **Done**: Verification complete; Director rolls up.
9.  **Blocked**: Returnable interruption state for any agent.

### The "Execution Log" Protocol
Agents must maintain an `## Execution Log` in Linear issue descriptions. This allows:
- **Resumability**: Another agent or human can pick up where the previous agent left off.
- **Transparency**: Clear audit trail of actions taken, tests run, and errors encountered.
- **Handoff**: Explicit signals for the next agent in the chain.

---

## Gaps Addressed from `docs/design.md`

The initial `docs/design.md` was a high-level sketch. This proposal fills the following critical gaps:

1.  **Hard Quality Gates**: Explicitly defines gates (T-1 through T-8 and I-1 through I-9) that must be passed before state transitions.
2.  **Traceability**: Mandates links from PRs back to `spec.md`, `plan.md`, and specific tasks, ensuring code never drifts from intent.
3.  **TDD Enforcement**: Requires the Engineer to provide evidence of failing tests before production code (Gate I-3).
4.  **Stack Discipline**: Clarifies when to use Graphite stacks (logical dependencies) vs. independent branches.
5.  **Multi-Tier Review**: Moves beyond "performing review" to a structured 4-tier process covering automation, fidelity, architecture, and polish.
6.  **State Recovery**: Formalizes the `Blocked` state and how to return from it.

## Recommendations for Implementation

1.  **Ratify Constitution**: The `.specify/memory/constitution.md` must be populated with project-specific engineering principles to enable the Architect's "Constitution Check".
2.  **Canonical Validation Commands**: Define a single `make validate` or equivalent command in the root `Makefile` that runs Build + Lint + Type Check + Tests to be used by the Engineer and Technical Lead.
3.  **PR Templates**: Update GitHub PR templates to include sections for:
    - Traceability (links to Spec/Plan/Task).
    - Validation Evidence (test outputs).
    - Explicit Verdict (for Reviewers).
4.  **Director Polling Logic**: Implement the Director as a robust long-running process or scheduled task that can handle Linear webhooks or periodic polling with exponential backoff.
