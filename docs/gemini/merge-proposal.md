# Task Tracking Process (Merged Proposal)

## Purpose

This document defines the unified task tracking process for the Archive Agentic workflow, optimized for high-velocity autonomous agent teams. It establishes Linear as the primary system of record for execution status and lifecycle management, integrated with Graphite for stacked PRs and GitHub Speckit for planning.

The intent is a process that is:
- **Autonomous-First**: Agents "know" their work by polling Linear state.
- **Traceable**: Clear audit trail from requirement to merged implementation.
- **High-Throughput**: Leverages stacked PRs (Graphite) to avoid blocking developers.
- **Rigorous**: Gate-based transitions ensure quality and consistency.

## Process Summary

1.  **Planning**: Use `spec.md`, `plan.md`, and `tasks.md` (via GitHub Speckit) as the approved design.
2.  **Execution Tracker**: Use Linear issues for every task across the full lifecycle.
3.  **Expanded Lifecycle**: Move features and tasks through 9 states: `Draft` → `Planning` → `Plan Review` → `Backlog` → `Selected` → `In Progress` → `In Review` → `Done`.
4.  **Agent Roles**: Explicit specialist agents (Architect, Coordinator, Engineer, Technical Lead) perform tasks based on state transitions.
5.  **Implementation**: Use Graphite for stacked pull requests and Git worktrees for isolation.

---

## Agent Team Roles & Responsibilities

The **Director** (Foreman) acts as the central orchestrator, polling Linear and invoking the appropriate agent based on the current issue state.

| Role | Responsibility | Entry State |
| --- | --- | --- |
| **Director** | Orchestrates the team; polls Linear state; delegates work. | Any |
| **Architect** | Produces `spec.md`, `plan.md`, and `tasks.md`. Opens Plan Review PRs. | `Draft` |
| **Explorer** | Conducts research and produces reports/ADRs. | On-demand |
| **Coordinator** | Decomposes approved plans into per-task Linear issues. | `Backlog` |
| **Engineer** | Implements tasks using worktrees and Graphite stacks. | `Selected` |
| **Technical Lead**| Reviews and merges stacked PRs. | `In Review` |

---

## State Model & Transition Rules

Linear is the single source of truth for the *entire* lifecycle.

| State | Responsibility | Description |
| --- | --- | --- |
| `Draft` | Director/User | Feature or bug report initial entry. |
| `Planning` | Architect | Active design and artifact creation using Speckit. |
| `Plan Review` | Reviewer | Plan artifacts (Spec/Plan/Tasks) awaiting approval. |
| `Backlog` | Coordinator | Approved plan waiting to be decomposed into tasks. |
| `Selected` | Engineer | Ready for implementation; all dependencies met. |
| `In Progress` | Engineer | Active coding; branch created; Graphite stack started. |
| `In Review` | Technical Lead | PRs published to Graphite; awaiting review. |
| `Blocked` | Assignee | Work halted due to an external dependency or ambiguity. |
| `Done` | Director | Merged, verified, and evidence attached. |

### Interruption State: `Blocked`
`Blocked` is a temporary state that can be entered from any active state. Upon transition to `Blocked`, the assignee **must** document the blocker in a Linear comment. When unblocked, the issue returns to its *previous* active state.

---

## Gate Rules

Each transition must satisfy specific conditions to ensure systemic integrity.

| Gate | Transition | Condition |
| --- | --- | --- |
| **T-1** | `Draft` → `Planning` | Feature objective defined and Architect assigned. |
| **T-2** | `Planning` → `Plan Review` | `spec.md`, `plan.md`, `tasks.md` exist; `/speckit.analyze` passes. |
| **T-3** | `Plan Review` → `Backlog` | Planning PR merged to main branch. |
| **T-4** | `Backlog` → `Selected` | Per-task issues created; all upstream dependencies are `Done`. |
| **T-5** | `Selected` → `In Progress` | Git worktree created; Branch named `t-##-slug`. |
| **T-6** | `In Progress` → `In Review` | Graphite stack published; links to Spec/Plan/Task added. |
| **T-7** | `In Review` → `Done` | PR merged; Acceptance Criteria checked; Evidence attached. |

---

## Implementation Workflow

### 1. Planning (Architect)
The Architect creates a planning PR. `tasks.md` must be structured so each task corresponds to one logical unit of work suitable for a Graphite stacked PR.

### 2. Scheduling (Coordinator)
The Coordinator creates individual Linear issues for each task in `tasks.md`.
- Issue Title format: `[T-##] [Feature Name] Short Description`
- Linear description must include links to the `spec.md`, `plan.md`, and the specific line in `tasks.md`.

### 3. Execution (Engineer)
Engineers work in isolated environments:
- **Worktrees**: Use `git worktree` to isolate task state.
- **Graphite**: Use `gt create`, `gt modify`, and `gt submit` for managing stacked PRs.
- **Commits**: Message must include Task ID and Linear ID: `feat: implement login (T-12, ARC-42)`.

### 4. Review & Merge (Technical Lead)
Technical Leads review the Graphite stack.
- Validation evidence (test logs, screenshots) **must** be provided in the Linear ticket.
- Merging is done via Graphite's squash-and-merge or similar strategy to maintain clean history.

---

## Agent Execution Protocol (Resumability)

For autonomous execution, the **Execution Log** is mandatory for any task taking more than one hour or involving a handoff.

```markdown
## Execution Log
- [timestamp] [role]: Started T-12 implementation.
- [timestamp] [role]: Encountered dependency error in module X.
- [timestamp] [role]: Resolved error; tests passing.
- [timestamp] [role]: Published Graphite stack.
```

---

## Scope Change Protocol
If execution reveals a change in scope or architectural design:
1. **Stop** implementation.
2. **Move** ticket to `Blocked`.
3. **Notify** Architect and Technical Lead.
4. **Update** planning artifacts and get approval before resuming.

---

## Conclusion

This unified process combines the high-fidelity state management of Linear with the high-velocity execution of Graphite and the rigorous validation of GitHub Speckit. By following these gates and role definitions, the Archive Agentic team can operate at scale with minimal coordination overhead.
