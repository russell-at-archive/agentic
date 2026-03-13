# Unified Task Tracking Process

## Purpose

This document defines the unified task-tracking process for the Archive Agentic workflow. It merges the strongest aspects of the Codex, Claude, and Gemini proposals into a single, cohesive standard.

The intent is to create a process that is:

- Simple enough to use consistently.
- Rigorous enough to preserve traceability and execution quality.
- Explicit enough for both human developers and AI agents to collaborate safely.

The guiding principle is that planning and execution are distinct. Planning artifacts define approved work. Task tracking records the live execution of that work.

## Process Summary

The unified approach follows these five pillars:

1. **Approved Planning**: Use `spec.md`, `plan.md`, and `tasks.md` as the authoritative source for work definition.
2. **Live Execution Records**: Use one GitHub Issue per approved task as the canonical record of execution.
3. **Compact State Model**: Track progress through `ready`, `in_progress`, `blocked`, `in_review`, and `done`.
4. **Traceability & Evidence**: Require explicit ownership, blocker documentation, and validation evidence before closure.
5. **Agent Resumability**: Require agents to maintain timestamped execution logs within the tracker.

## Design Principles

- **Track Execution, Not Ideation**: Only track work that has passed all planning gates.
- **Link Artifacts Tight**: Maintain explicit links between planning documents and execution issues.
- **Atomic Units**: Default to one task, one owner, one branch, and one pull request.
- **Visibility First**: Surface blockers immediately; never absorb uncertainty silently.
- **Evidence-Based Done**: Require verification evidence (tests, logs, screenshots) before marking a task complete.
- **Agent Safety**: Preserve enough history for a human or agent to resume work from any point without re-reading session history.
- **No Silent Scope Creep**: Return to planning if implementation reveals necessary changes beyond the task's defined scope.

## Separation of Responsibilities

| Artifact | Responsibility |
| :--- | :--- |
| `spec.md` | Defines required behavior, scope, and acceptance criteria. |
| `plan.md` | Defines engineering approach, constraints, and validation strategy. |
| `tasks.md` | Defines the approved task breakdown and dependency sequencing. |
| GitHub Issue | Holds live execution state, ownership, blockers, and links to evidence. |
| Pull Request | Holds the concrete implementation and review discussion. |

**The governing rule**: If a detail changes *execution status*, it belongs in the issue tracker. If a detail changes *scope, design, or sequencing*, it belongs in the planning artifacts first.

## Source of Truth Model

We adopt a split source-of-truth model:

- **`tasks.md`** is the source of truth for *approved task decomposition*.
- **GitHub Issues** are the source of truth for *live execution state*.

`tasks.md` should not be edited to reflect day-to-day progress. It should change only if the underlying plan or task list is officially amended.

## State Model & Label Taxonomy

Use the following labels and states for all execution work.

### State Model

| State | Meaning | Typical Exit Condition |
| :--- | :--- | :--- |
| `ready` | Approved task is available to start (dependencies met). | Owner claims the task. |
| `in_progress` | Task is actively being implemented. | PR opens, task blocks, or work completes. |
| `blocked` | Progress is halted by an external factor. | Blocker is resolved and documented. |
| `in_review` | PR is open and awaiting review or validation. | Review passes and validation is confirmed. |
| `done` | PR is merged and validation evidence is attached. | None. |

### Label Taxonomy

| Label | Meaning |
| :--- | :--- |
| `status:ready` | Dependencies met, unassigned. |
| `status:in-progress` | Actively being worked. |
| `status:blocked` | Blocked; blocker documented in issue body or comment. |
| `status:in-review` | PR open and awaiting review. |
| `status:done` | Merged and verified against acceptance criteria. |
| `type:feature` | New user-visible behavior. |
| `type:bug` | Defect fix. |
| `type:refactor` | Internal restructuring, no behavior change. |
| `type:chore` | Dependency, tooling, or infrastructure work. |
| `priority:p1` | MVP; must ship before any P2 work begins. |
| `priority:p2` | High value; ships after MVP is verified. |
| `priority:p3` | Nice to have; ships after P2 is verified. |

## Gate Rules

Compliance with these gates is mandatory for all tracked work.

| Gate | Condition |
| :--- | :--- |
| T-1 | `/speckit.analyze` passes before any issue is created. |
| T-2 | All dependency tasks are `done` before a task enters `ready`. |
| T-3 | Branch opened and issue updated (assignee, branch link) before work begins. |
| T-4 | Blocker formally documented before task enters `blocked`. |
| T-5 | PR description traces to spec, plan, and task before review begins. |
| T-6 | All acceptance criteria verified and evidence attached before task is `done`. |

## Agent Execution Protocol

AI agents require higher resumability than human-only work. Agents must maintain an **Execution Log** in the GitHub Issue body.

### Execution Log Format

```text
## Execution Log

- [TIMESTAMP] - [ACTION TAKEN] - [OUTCOME]
- Next Step: [INSTRUCTION FOR RESUMPTION]
```

- **Autonomy Boundaries**: Agents must not resolve architectural or product ambiguity. If a task requires a new decision, the agent must transition the task to `status:blocked` and surface the discovery.
- **Validation**: Agents must attach validation evidence (test results, screenshots, logs) to the PR or Issue identically to a human developer.

## Scope Change Rules

If implementation reveals necessary work outside the approved task:

1. **Stop Implementation**: Do not expand scope silently.
2. **Document**: Record the discovery in the tracker record.
3. **Plan**: Update the relevant planning artifact (`plan.md` or `spec.md`) and re-run `/speckit.tasks`.
4. **Sync**: Update GitHub Issues to reflect the amended tasks.
5. **Resume**: Proceed only once the new scope is approved.

## Completion Evidence

A task moves to `done` only when concrete evidence of verification is linked. Evidence types include:

- Automated test results (CI logs or local output).
- Manual verification notes or recordings.
- Screenshots for UI changes.
- Rollout or migration confirmation logs.

---

*This unified process represents the merged standard for the Archive Agentic workflow, balancing rigor with execution speed.*
