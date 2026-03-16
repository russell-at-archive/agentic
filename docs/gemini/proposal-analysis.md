# Analysis of Task Tracking Proposals

This document analyzes and compares the four existing task tracking documents in the repository to identify the strongest ideas for a unified merger.

## Documents Analyzed

1.  **`docs/tracking-process.md` (Original)**: The baseline process using GitHub Issues and a 4-state model.
2.  **`docs/codex/tracking-proposal.md` (Codex)**: A transition to Linear using a 5-state model, introducing Linear-specific terminology.
3.  **`docs/gemini/tracking-proposal.md` (Gemini)**: A refined Linear-first proposal with a 9-state model, explicitly integrating the "Agent Team" roles from `docs/design.md`.
4.  **`docs/claude/tracking-proposal.md` (Claude)**: A comprehensive 9-state Linear model that deeply integrates Graphite, the Agent Team roles, and the Director-led orchestration.

## Comparison & Contrast

### 1. Tooling & Platform
- **Original**: GitHub-centric.
- **Codex**: Linear-first, but keeps it relatively simple.
- **Gemini & Claude**: Full Linear adoption, with Claude adding explicit Graphite integration for stacked PRs.

### 2. State Model Complexity
- **Original**: 4 states (`ready`, `in_progress`, `in_review`, `done`) + `blocked`.
- **Codex**: 5 states (`Ready`, `In Progress`, `In Review`, `Done`) + `Blocked`.
- **Gemini & Claude**: 9 states (`Draft`, `Planning`, `Plan Review`, `Backlog`, `Selected`, `In Progress`, `In Review`, `Done`) + `Blocked`. This model covers the *entire* lifecycle from feature conception to completion, not just the implementation phase.

### 3. Agent Roles & Orchestration
- **Original & Codex**: Roles are implicit or loosely defined.
- **Gemini & Claude**: Explicitly define the **Agent Team** (Director, Architect, Coordinator, Engineer, Technical Lead, Explorer). Claude's version is the most detailed regarding the "Director" as the central dispatcher based on Linear state.

### 4. Implementation Workflow
- **Original & Codex**: Standard branch/PR model.
- **Gemini & Claude**: Explicit use of **Graphite** for stacked PRs and **Worktrees** for isolated environments. This aligns with high-velocity agentic development.

### 5. Traceability & Evidence
- All proposals agree on the "Split Source of Truth" (`tasks.md` for planning, Tracker for execution).
- All agree on Gate Rules and the requirement for verification evidence.
- Claude introduces the "Linear identifier + Task ID" dual-referencing in commits (e.g., `T-12, ARC-42`).

## Strongest Ideas to Retain

| Feature | Source | Why |
| --- | --- | --- |
| **9-State Lifecycle** | Gemini/Claude | Provides full visibility from `Draft` (Architect) to `Done`. |
| **Agent Team Roles** | Gemini/Claude | Clearly defines "who" does "what" at "which state". |
| **Director Orchestration** | Claude | The most scalable way for agents to "know" their work: poll Linear state. |
| **Graphite / Stacked PRs** | Claude | Essential for avoiding PR bottlenecks and maintaining context. |
| **Split Source of Truth** | All | Maintains `tasks.md` as the "plan" and Linear as the "live state". |
| **Gate Rules (T-1 to T-8)** | Claude | The most rigorous set of conditions for safe autonomous transitions. |
| **Execution Log** | All | Critical for agent handoffs and human oversight. |
| **Worktree / Isolated Envs** | Claude/Gemini | Prevents environment contamination between tasks. |

## Conclusion for Merger

The merged proposal should adopt the **Claude/Gemini 9-state model** as the framework, use **Claude's detailed agent role definitions**, and incorporate the **Graphite/Worktree implementation workflow**. It should refine the **Gate Rules** to be the definitive standard for the repository.
