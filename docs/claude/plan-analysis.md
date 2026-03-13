# Task Tracking Process — Cross-Agent Analysis

**Agents compared:** Claude (`docs/claude/`), Codex (`docs/codex/`), Gemini (`docs/gemini/`)
**Date:** 2026-03-13

---

## Summary

All three agents produced coherent, internally consistent task tracking processes. They share a common foundation: planning artifacts (`spec.md`, `plan.md`, `tasks.md`) gate execution; GitHub Issues track live state; one task maps to one branch and one PR. The differences are in depth, formalism, locus of truth, and coverage of edge cases.

---

## Point-by-Point Comparison

### Source of Truth

| Aspect | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Primary source of truth | GitHub Issues (canonical during execution) | Issue tracker (execution state only) | `tasks.md` (local source of truth) |
| Role of `tasks.md` | Read-only after issues are created | Planning artifact, not execution log | Primary, continuously updated |
| Sync direction | `tasks.md` → Issues, then Issues own state | `tasks.md` → Issues, Issues own state | Bidirectional (tasks.md updated with markers) |

**Analysis:** Claude and Codex agree that GitHub Issues own live execution state, with `tasks.md` becoming static after planning completes. Gemini inverts this: `tasks.md` remains the running record and GitHub Issues serve as a visibility layer. Gemini's approach is simpler to operate locally and well-suited to AI agents working from the filesystem, but it creates a synchronization risk if the file and issues diverge. Claude and Codex's approach is more robust for multi-person or multi-agent teams but requires discipline to keep issues updated.

---

### State Model

| State | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Not started / backlog | `backlog` | Excluded by design | `[ ]` |
| Ready to start | `ready` | `ready` | (implicit, no marker) |
| Active | `in-progress` | `in_progress` | `[/]` |
| Blocked | `blocked` | `blocked` | `[~]` |
| Under review | `in-review` | `in_review` | (implicit, closed on merge) |
| Complete | `done` | `done` | `[x]` |

**Analysis:** Claude has the most granular model (6 states including `backlog`). Codex defines 5 states and explicitly excludes `backlog`, `todo`, `qa`, and custom states to prevent tracker bloat. Gemini uses 4 checkbox markers, dropping the `ready` and `in-review` distinctions entirely.

Claude's `backlog` → `ready` distinction is valuable when a task list is created well in advance of execution and dependency gates must be enforced. Codex's deliberate exclusion of `backlog` keeps the tracker tightly scoped to execution, pushing pre-execution scheduling back to planning. Gemini's simpler model reduces cognitive overhead and is well-suited to agents that operate sequentially through a file, but it loses the ability to query "what is ready to start next" without reading `tasks.md` manually.

The absence of an `in-review` state in Gemini is a notable gap. Without it, there is no explicit handoff signal between the implementer and reviewer, and PR lifecycle becomes invisible to anyone reading the task file.

---

### Agent Protocol

| Aspect | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Execution log | Required in GitHub Issue body | Not specified | Not specified |
| Agent blocker handling | Formal: document, transition to blocked, stop, surface to human | Mentioned as part of general blocker rules | Not addressed |
| Scope creep by agent | Explicit stop-document-replan protocol | Implied by "changes to scope go back to planning" | Not addressed |
| Session start behavior | Not specified | Not specified | Agent reports current tasks.md status and target task |

**Analysis:** Claude provides the most complete agent protocol, requiring a running `## Execution Log` section in the GitHub Issue body so any human can resume from any point without re-reading session history. This is a direct response to the coordination challenge of async, multi-session AI execution and is the most operationally useful feature in Claude's document.

Codex and Gemini do not define an execution log format. Gemini's requirement that an agent report `tasks.md` status at session start is a lightweight equivalent — it establishes a handoff convention but does not provide the mid-task auditability that Claude's log does.

---

### Scope Change Handling

| Aspect | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Protocol defined | Yes — stop, document, replan, create new task, resume original at original scope | Yes — stop, update planning artifacts, then continue | Implicit — stop before moving to next user story |
| Architectural decisions | Mentioned as a planning return trigger | Requires creating/updating an ADR | Not addressed |

**Analysis:** Claude and Codex have substantively identical scope change protocols. Both treat silent scope expansion as a planning failure. Codex adds the ADR requirement for architectural decisions, which is a useful hook into a formal decision record system. Gemini's treatment is underspecified; it relies on the developer's judgment at phase boundaries without a formal return-to-planning trigger.

---

### PR and Completion Requirements

| Aspect | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| PR must trace to spec/plan/task | Yes — explicit, PR returned if traceability missing | Links to parent artifacts required in tracker | Not specified |
| Evidence required to close | All acceptance criteria checked off, CI passing, reviewer verifies traceability | Merge + validation evidence (tests, screenshots, logs, rollout) | Marker updated to `[x]`, GitHub Issue closed |
| Review required | Yes, reviewer verifies traceability | Yes, validation complete | Implied (PR opened, not specified) |

**Analysis:** Claude has the most demanding completion bar, requiring explicit reviewer sign-off on full traceability (spec → plan → task → PR). Codex focuses on evidence completeness without requiring a separate traceability review step. Gemini's completion is the lightest: update the marker and close the issue. Gemini's approach may result in tasks being marked done before acceptance criteria are verified, which Claude's Gate T-6 explicitly prevents.

---

### Unique Contributions

**Claude only:**
- Formal gate rules table (T-1 through T-6)
- Risk and mitigation table
- Open questions section — surfaces unresolved design decisions rather than papering over them
- Agent execution log format

**Codex only:**
- WIP limits — one primary `in_progress` task per owner; explicit discouragement of using blocked work as justification for unlimited new starts
- Metrics to track (lead time, review time, blocker age, stale task count) and metrics to avoid (raw count, activity volume)
- Anti-patterns list
- Recommended rollout plan — phased adoption starting with one feature
- Stale task definition (no meaningful update in two working days)

**Gemini only:**
- Conventional commit message format with task ID reference (e.g., `feat: implement user model (T012)`)
- GitHub Project board (Kanban) for visual flow
- Checkpoint requirement — verify increment is functional at end of each user story phase before proceeding

---

## Agreements Across All Three

- Planning must be complete before tracking begins.
- One task maps to one branch and one PR by default.
- Blocked tasks must surface a written blocker; silent absorption is not allowed.
- `done` requires evidence, not just a status change.
- Scope changes return to planning rather than expanding the current task.
- `speckit.taskstoissues` converts `tasks.md` into GitHub Issues.

---

## Disagreements and Gaps

| Topic | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Canonical live state | GitHub Issues | Issue tracker | `tasks.md` |
| `backlog` state | Included | Explicitly excluded | Not applicable (checkbox) |
| `in-review` state | Included | Included | Not included |
| WIP limits | Not addressed | Formally defined | Not addressed |
| Metrics | Not defined | Defined | Not addressed |
| Agent execution log | Required (structured) | Not defined | Not defined |
| Conventional commits | Not mentioned | Not mentioned | Required with task ID |
| ADR requirement | Not mentioned | Required for arch decisions | Not mentioned |
| Sprint vs kanban | Open question | Not addressed | Kanban assumed |

---

## Synthesis and Recommendations

A combined process would draw the following from each agent:

1. **From Claude:** Agent execution log format; gate rules table; formal state transition rules; risk/mitigation table.
2. **From Codex:** WIP limits; metrics definition; anti-patterns list; explicit exclusion of non-execution states from the tracker; phased rollout plan; stale task definition.
3. **From Gemini:** Conventional commit format with task ID; checkpoint requirement at user story boundaries; GitHub Project board for visual kanban.

The one genuine conflict — whether `tasks.md` or GitHub Issues is the canonical live state — should be resolved in favor of GitHub Issues as canonical during execution (Claude and Codex). `tasks.md` is a planning artifact and should not become a second execution log. Gemini's checkbox approach is ergonomic for agents reading the filesystem but creates synchronization risk at scale and should be treated as a local scratch pad rather than the record of truth.

The most significant gap across all three documents is the absence of a clear authority model for state transitions: who is allowed to move a task to `done`, and what happens when the assignee and reviewer disagree. Claude raises this as an open question; Codex and Gemini do not address it. Any production adoption of this process should resolve that question before execution begins.
