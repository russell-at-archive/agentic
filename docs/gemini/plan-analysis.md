# Task Tracking Process Analysis

This document provides a comparative analysis of the task-tracking process proposals from three independent agents (Claude, Codex, and Gemini). It synthesizes their core philosophies, methodologies, and technical requirements to define a unified standard for the Archive Agentic workflow.

## Overview of Proposals

The three proposals represent different operational perspectives:

1. **Claude**: An operational-heavy approach focusing on rigorous state transitions, detailed audit trails (Execution Logs), and high-fidelity traceability from spec to PR.
2. **Codex**: A managerial-focused proposal emphasizing WIP limits, operational metrics (lead time, blocker age), and clear separation between planning and execution artifacts.
3. **Gemini**: A tool-centric, minimalist approach that prioritizes `tasks.md` as a local developer-friendly source of truth while using GitHub Issues for team visibility.

## Comparison Matrix

The following table summarizes the key differences and commonalities between the three suggestions.

| Feature | Claude's Process | Codex's Process | Gemini's Process |
| :--- | :--- | :--- | :--- |
| **Philosophy** | Coordination mechanism for async handoffs. | Visibility without duplicate planning overhead. | Bridge between planning and implementation. |
| **Source of Truth** | **GitHub Issues** (Canonical). | **GitHub Issues** (Canonical). | **`tasks.md`** (Local Source of Truth). |
| **Core States** | `backlog`, `ready`, `in-progress`, `blocked`, `in-review`, `done`. | `ready`, `in_progress`, `blocked`, `in_review`, `done`. | `[ ]`, `[/]`, `[x]`, `[~]`. |
| **Agent Protocol** | **Execution Log** in GitHub Issue body (timestamped). | Agent as a "Task Owner." | **Session Report** of `tasks.md` status. |
| **Branching/PR** | One branch/PR per task. Traceability required. | Default: One task per branch/PR. | Branch per task or task group. |
| **Blockers** | Formally documented in issue with owner/next steps. | Documented with owner and date; escalate if > 1 day. | Marker `[~]` in `tasks.md` with comment. |
| **Metrics** | Not specified. | Lead/Review time, Blocker age, Stale tasks. | Not specified. |
| **Completion** | AC verified, PR merged, reviewer approval. | PR merged, evidence attached (logs/tests). | `[x]` in `tasks.md`, close Issue. |

## Detailed Analysis

### 1. Canonical Source of Truth

A significant divergence exists regarding the "Source of Truth":

- **External (Claude/Codex)**: GitHub Issues are the definitive state. This ensures that the entire team (human and agent) has a shared, immutable history of the feature's progress. It avoids "stale file" syndrome where local `tasks.md` files drift from actual implementation.
- **Local (Gemini)**: `tasks.md` is the primary record. This is highly efficient for agents operating in a single session but creates a visibility gap for other team members unless synchronization is automated and frequent.

### 2. Agent Execution Protocols

Claude provides the most robust protocol for AI agents:

- **Auditability**: The "Execution Log" requirement (timestamp, action, outcome, next step) in the GitHub Issue body is critical for handoffs between sessions or between agents and humans.
- **Autonomy Boundaries**: Claude explicitly mandates stopping and documenting when architectural or product ambiguity is encountered, preventing "silent scope expansion."

### 3. State Management and Transitions

All three agree on the basic flow but differ in "Gate" rigor:

- **Claude** defines explicit "State Transition Rules" (e.g., cannot go from `blocked` to `done` directly).
- **Codex** adds "WIP Limits," recommending one `in_progress` task per owner to reduce context switching and drift.
- **Gemini** uses simple markers (`[/]`, `[x]`) which are easy to parse but lack the metadata (assignee, branch link) required for large-scale coordination.

## Synthesis and Recommendations

To establish the "Archive Agentic" standard, we should combine the strengths of all three proposals.

### Recommendations for the Unified Process

1. **Dual-Sync Truth**: Use GitHub Issues as the **Canonical Source of Truth** for state, ownership, and history. Maintain `tasks.md` as a **Local Operational Cache** that agents use to sequence their work within a session.
2. **Adopt the Execution Log**: All agents MUST maintain an execution log in the GitHub Issue body. This replaces the need for humans to read through long chat histories to understand progress.
3. **Strict WIP Limits**: Enforce one active task per agent. This aligns with the "thin vertical slice" philosophy of spec-driven development.
4. **Evidence-Based Completion**: A task is not `done` until validation evidence (test results, screenshots, or logs) is linked in the PR or Issue, as proposed by Codex.
5. **Automated Sync**: Use `/speckit.taskstoissues` as the bridge. Any change to task scope during implementation must return to `plan.md` and `tasks.md` before the Issue is updated.

---

*This analysis was generated by Gemini CLI based on the task-tracking documents provided in `docs/`.*
