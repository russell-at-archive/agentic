# Task Tracking Process (Linear-First Proposal)

## Purpose

This document defines the task tracking process for the Archive Agentic workflow, realigned around Linear as the primary system of record for execution status and lifecycle management.

The intent is a process that is:

- **Integrated**: Seamlessly connects planning artifacts with live execution.
- **Traceable**: Maintains a clear audit trail from requirement to implementation to verification.
- **Agent-First**: Designed to be operated autonomously by agents while remaining transparent to humans.
- **High-Velocity**: Supports parallel execution and stacked pull requests via Graphite.

## Process Summary

1. Use `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts (managed via GitHub Speckit).
2. Use one Linear issue per approved task as the live execution record.
3. Manage the entire lifecycle through expanded Linear states: `Draft` → `Planning` → `Plan Review` → `Backlog` → `Selected` → `In Progress` → `In Review` → `Done`.
4. Utilize `Blocked` as a returnable interruption state for any active task.
5. Require explicit ownership, blocker handling, and verification evidence for every task.
6. Use Graphite for stacked pull requests to maintain high throughput and clean review boundaries.

## Design Principles

- **Track Execution, Not Just Ideation**: Linear tickets represent actionable work units.
- **Link Everything**: Tickets must link back to planning artifacts (`spec.md`, `plan.md`, `tasks.md`).
- **One Task, One Owner**: Every ticket has exactly one directly responsible agent or human.
- **Small Batches**: Tasks should be sized for review in single or small stacked PRs.
- **Visibility First**: Blockers and status changes must be reflected in Linear immediately.
- **Evidence-Based Completion**: A task is not `Done` until verification evidence is attached.

## Separation of Responsibilities

| Artifact/Tool | Responsibility |
| --- | --- |
| `spec.md` | Defines behavior, scope, and acceptance criteria. |
| `plan.md` | Defines implementation approach, constraints, and validation strategy. |
| `tasks.md` | Defines the approved task breakdown and dependencies. |
| Linear Issue | Holds live execution state, ownership, blockers, and evidence links. |
| Graphite | Manages stacked pull requests and implementation review. |
| GitHub | Canonical source control and final PR merge destination. |

## Expanded State Model

Linear is configured with the following workflow states to reflect the full agentic development lifecycle:

| State | Meaning | Transition Condition |
| --- | --- | --- |
| `Draft` | Initial task or feature idea. | Move to `Planning` when research begins. |
| `Planning` | Active creation of `spec.md` and `plan.md`. | Move to `Plan Review` when artifacts are ready. |
| `Plan Review` | Reviewing planning artifacts via GitHub PR. | Move to `Backlog` once plan is approved. |
| `Backlog` | Approved tasks waiting for scheduling. | Move to `Selected` when dependencies are met. |
| `Selected` | Ready for implementation; next in queue. | Owner moves to `In Progress` to start coding. |
| `In Progress` | Active implementation (coding and testing). | Move to `In Review` when Graphite stack is published. |
| `Blocked` | Work stopped due to external dependency or ambiguity. | Move back to previous state once unblocked. |
| `In Review` | PRs published and awaiting Technical Lead review. | Move to `Done` once merged and verified. |
| `Done` | Implementation merged, verified, and evidenced. | Final state. |

## Gate Rules (Automation & Quality)

These gates enforce the minimum conditions for state transitions.

| Gate | Transition | Condition |
| --- | --- | --- |
| **T-1** | `Draft` → `Planning` | Explorer or Architect assigned; objective defined. |
| **T-2** | `Plan Review` → `Backlog` | Plan PR merged; `/speckit.analyze` passes. |
| **T-3** | `Backlog` → `Selected` | All upstream task dependencies in `Done` state. |
| **T-4** | `Selected` → `In Progress` | Branch/Worktree created; Graphite stack initialized. |
| **T-5** | `In Progress` → `Blocked` | Blocker documented in Linear comments with owner/ETA. |
| **T-6** | `In Progress` → `In Review` | Graphite stack published; links to Spec/Plan/Task added. |
| **T-7** | `In Review` → `Done` | PR merged; Acceptance Criteria checked; Evidence attached. |

## Workflow

### 1. Planning and Initialization
Once a feature moves from `Draft` to `Planning`, the **Architect** produces the required Speckit artifacts. The transition to `Backlog` occurs only after the planning PR is merged. The **Coordinator** then populates Linear with individual task tickets derived from `tasks.md`.

### 2. Implementation (Engineer)
An **Engineer** selects a ticket in the `Selected` state:
- Validates all dependencies are `Done`.
- Moves the ticket to `In Progress`.
- Creates a dedicated worktree and initializes a Graphite stack.
- Implementation follows the `T-##` ID for branch naming and commit messages.

### 3. Review (Technical Lead)
When the Engineer publishes a Graphite stack:
- The ticket moves to `In Review`.
- The **Technical Lead** is notified for review.
- Any feedback results in the ticket staying in `In Review` (or moving back to `In Progress` if significant rework is needed).

### 4. Verification and Closure
Before moving to `Done`:
- The Engineer must attach **Validation Evidence** (test logs, screenshots, etc.) to the Linear ticket.
- The Engineer must check off the **Acceptance Criteria** in the ticket description.
- The **Director** verifies the rollup of status before final closure.

## Agent Execution Protocol

Agents operating this workflow must:
1. **Poll Linear**: The Director agent polls for `Selected` tasks.
2. **Update Status**: Move tickets to `In Progress` immediately upon starting.
3. **Log Progress**: For complex tasks, leave an `## Execution Log` in the ticket comments every 4 hours or upon significant milestones.
4. **Escalate Blockers**: If an agent hits an ambiguity or technical hurdle, move to `Blocked` and tag a human or the Architect for clarification.
5. **Attach Evidence**: Never move a ticket to `Done` without attaching a `validation-results.log` or similar proof of correctness.

## Tooling Integration

- **Linear CLI/API**: Used for status updates and ticket creation.
- **Graphite CLI**: Used for managing stacked PRs and submissions.
- **Speckit**: Used for validating that tasks align with the approved spec.

## Conclusion

By using Linear's expanded state model, we gain high-fidelity visibility into the agentic workflow. The transition from GitHub Issues to Linear enables better project-level rollup, clearer dependency management, and a more robust foundation for autonomous operations.
