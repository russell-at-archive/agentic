# Task Tracking Process Analysis

## Purpose

This report compares the three task-tracking proposals in:

- `docs/codex/task-tracking-process.md`
- `docs/claude/task-tracking-process.md`
- `docs/gemini/task-tracking-process.md`

The goal is to identify where they align, where they conflict, and which
elements are strongest for a practical team process in this repository.

## Executive Summary

All three documents agree on the core intent: task tracking should begin after
planning, should preserve traceability to planning artifacts, and should make
execution status visible to both humans and agents.

The main disagreement is the location of live execution state:

- Codex treats the issue tracker as the live execution layer and keeps planning
  artifacts separate.
- Claude does the same, but in a stricter and more GitHub-centric way, with
  explicit gates, labels, and agent logging requirements.
- Gemini keeps `tasks.md` as the live source of truth and uses GitHub Issues as
  a synchronization and visibility layer.

The strongest overall direction is a hybrid of Codex and Claude:

- keep `tasks.md` as the approved planning artifact, not the live execution
  tracker
- use GitHub Issues or an equivalent tracker as the canonical execution record
- require explicit blocker handling, traceability, and completion evidence
- adopt a smaller state model than Claude's, but more rigor than Gemini's

Gemini contributes a simple workflow and lightweight task markers, but its
proposal introduces dual-write risk by asking teams to maintain live task state
in both `tasks.md` and GitHub Issues.

## Areas of Agreement

All three proposals align on these points:

- Task tracking starts after planning artifacts exist.
- Tasks should trace back to planned work, especially `tasks.md`.
- Ownership should be explicit when implementation starts.
- Blockers should be visible rather than implied.
- A task is not complete just because code exists; verification is required.
- GitHub Issues are useful for team visibility, even when not treated as the
  sole source of truth.
- Branches and pull requests should map clearly to tracked work.

This consensus is strong enough to define a baseline process without much
controversy.

## Key Differences

| Dimension | Codex | Claude | Gemini |
| --- | --- | --- | --- |
| Live execution source of truth | Issue tracker | GitHub Issue | `tasks.md` |
| Role of `tasks.md` | Approved task list, not live status | Planning artifact only after issue creation | Active execution tracker |
| State model | `ready`, `in_progress`, `blocked`, `in_review`, `done` | `backlog`, `ready`, `in-progress`, `blocked`, `in-review`, `done` | `[ ]`, `[/]`, `[x]`, `[~]` markers |
| Workflow rigor | Moderate | High | Low to moderate |
| Agent-specific requirements | Minimal | Strong execution-log and handoff requirements | Light session reporting |
| Traceability expectations | Strong | Very strong | Moderate |
| Risk of process overhead | Moderate | High | Low |
| Risk of drift between tools | Low | Low | High |

## Analysis by Proposal

## Codex Proposal

### Strengths

- Draws a clean boundary between planning and execution.
- Uses a compact state model that is easy to operationalize.
- Emphasizes completion evidence instead of status-only updates.
- Has a sensible default unit of work: one task, one branch, one PR.
- Handles blockers, stale work, WIP limits, and cadence without over-designing
  the workflow.

### Weaknesses

- It is less explicit than Claude about how agents should leave resumable
  execution history.
- It assumes an issue tracker model but does not fully specify labels,
  templates, or automation.
- It excludes `backlog`, which is reasonable for post-planning execution, but
  some teams may still want a pre-ready holding state in the same system.

### Overall Assessment

Codex is the best balance of rigor and usability. It is structured enough to
prevent ambiguity but avoids turning task tracking into a second planning
system.

## Claude Proposal

### Strengths

- Strongest traceability model from spec to plan to task to PR.
- Best treatment of agent execution, especially resumability and audit trail.
- Clear transition rules and gate model reduce ambiguity.
- Explicit label taxonomy is operationally ready for GitHub.
- Strong stance against silent scope expansion is valuable.

### Weaknesses

- It is the most process-heavy proposal and may slow execution for smaller
  changes.
- Requiring that states cannot be skipped may be too rigid for routine fixes or
  tightly scoped tasks.
- The mandated execution log in every issue may create noise if applied
  universally rather than only to agent-run or high-risk tasks.
- It makes GitHub Issues deeply canonical, which may be correct operationally
  but reduces portability if the team later changes tracker tooling.

### Overall Assessment

Claude is the most robust operational design, especially for teams mixing human
and agent execution. Its main drawback is overhead. It is best used as the
source for guardrails rather than copied wholesale.

## Gemini Proposal

### Strengths

- Simplest model to understand and adopt quickly.
- Keeps execution close to the feature artifact, which can feel natural during
  implementation.
- Uses a lightweight checklist syntax that is easy for humans and agents to
  update.
- Has a practical focus on sequential implementation and story checkpoints.

### Weaknesses

- Treating `tasks.md` as the live source of truth conflicts with the other two
  proposals and creates synchronization problems with GitHub Issues.
- Checklist markers are too lightweight for detailed operational tracking,
  especially blockers, evidence, ownership history, and review state.
- It does not define a strong traceability or validation model.
- It makes the execution state more dependent on local file edits, which is
  weaker for collaborative visibility and concurrent work.

### Overall Assessment

Gemini is the easiest process to start with, but it is the least reliable at
team scale. Its simplicity is useful, but its source-of-truth choice is the
largest structural weakness among the three proposals.

## Major Design Tensions

## 1. Where live state should live

This is the biggest disagreement.

- Codex and Claude separate planning artifacts from execution records.
- Gemini combines them by updating `tasks.md` during execution.

The Codex and Claude model is stronger. Live execution state changes frequently,
needs comments, ownership, blockers, PR links, and evidence, and benefits from
collaborative tooling. `tasks.md` is better treated as an approved decomposition
artifact than as an operational log.

## 2. How much workflow rigor is appropriate

- Claude optimizes for auditability and controlled execution.
- Gemini optimizes for simplicity and speed.
- Codex sits between them.

For this repository, Codex's level of rigor is the better default, with select
Claude controls added where agent resumability and governance matter.

## 3. How much process should be agent-specific

Claude directly addresses agent behavior. Codex implies it. Gemini barely
special-cases it.

Given this repository's agent-heavy workflow, Claude is correct that agent
execution needs explicit handoff discipline. That said, a full issue-body log on
every task may be more than necessary. A lighter requirement such as meaningful
execution notes on agent-touched tasks would likely be enough.

## Recommended Synthesis

The best combined process would be:

1. Keep `spec.md`, `plan.md`, and `tasks.md` as approved planning artifacts.
2. Create one GitHub Issue per approved task for live execution tracking.
3. Use a compact execution state model:
   `ready`, `in_progress`, `blocked`, `in_review`, `done`.
4. Require each issue to include:
   task ID, owner, dependencies, artifact links, branch, PR link, and
   validation evidence.
5. Require blocker documentation and escalation timing.
6. Require traceability from PR back to spec, plan, and task.
7. Require agent execution notes sufficient for a human to resume, but only for
   agent-executed or materially complex tasks.
8. Keep WIP limits and stale-task review from the Codex proposal.
9. Avoid updating `tasks.md` for live execution state after issue creation.

This synthesis preserves the strongest parts of each document:

- Codex provides the clearest execution model.
- Claude provides the best governance and agent handoff rules.
- Gemini provides useful simplicity, but mainly as a reminder not to overbuild
  the process.

## Recommendation

If one proposal must be chosen as the base document, use the Codex version as
the foundation and incorporate the following additions from Claude:

- explicit PR traceability requirements
- blocker documentation format
- agent resumability and handoff expectations
- optional gate checks for high-risk work

Do not adopt Gemini's recommendation to keep `tasks.md` as the live execution
source of truth. That is the main point where it is materially weaker than the
other two proposals.

## Final Conclusion

The three proposals are directionally aligned, but they optimize for different
failure modes:

- Codex protects against planning drift and tracker bloat.
- Claude protects against ambiguity, weak traceability, and poor agent handoff.
- Gemini protects against process complexity.

For this repository, the most defensible approach is a Codex-centered process
with selective Claude controls. If the team decides to standardize on that
model, the resulting process choice is significant enough that it should likely
be recorded as an ADR before it becomes the required workflow.
