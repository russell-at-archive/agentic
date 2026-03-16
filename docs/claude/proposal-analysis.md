# Tracking Proposal: Comparative Analysis

## Documents Reviewed

| Document | Author |
| --- | --- |
| `docs/claude/tracking-proposal.md` | Claude |
| `docs/codex/tracking-proposal.md` | Codex |
| `docs/gemini/tracking-proposal.md` | Gemini |

---

## Summary of Each Proposal

### Claude

The most comprehensive of the three. Claude fully integrates `design.md`'s
nine-state lifecycle and five-agent team model. It introduces a formal Agent
Team section mapping each agent (Director, Architect, Coordinator, Engineer,
Technical Lead, Explorer) to an entry state and responsibility. It provides
eight gate rules covering both the planning and implementation tracks, a
detailed per-agent workflow with numbered steps, a Scope Change Rules section,
WIP Limits, and an Operating Cadence table. Mentions Graphite for stacked PRs
and worktree creation. The prose is thorough but verbose in places.

### Codex

The leanest of the three. Codex captures the full nine-state model concisely
and adds two distinctive contributions not found in the other proposals. First,
it promotes `Project`, `Team`, and `Priority` from optional to required fields
in the issue schema — treating Linear's project and team attribution as
mandatory, not an afterthought. Second, it proposes five named Linear views
(`My In Progress`, `Blocked`, `Selected by Priority`, `In Review`, `Done This
Cycle`) as shared team surfaces. The prose is tighter than Claude's, and the
Workflow section is deliberately compact. Gate rules are simplified to six.
No Agent Team section.

### Gemini

The most opinionated in framing. Gemini introduces "Agent-First" and
"High-Velocity" as named design principles and is the only proposal to list
Graphite and GitHub as first-class entries in the Separation of Responsibilities
table. Its gate rules are seven and carry the most specific preconditions: T-1
requires the Explorer or Architect to be assigned and the objective to be
defined before `Planning`; T-4 requires a Graphite stack to be initialized, not
merely a branch created. It adds two runtime behaviors absent from the others:
the Director verifying completion rollup before final closure, and a four-hour
cadence for agent execution log entries. Workflow prose is the briefest of the
three. Does not include WIP limits, scope change rules, or an operating cadence
table.

---

## Feature Comparison Matrix

| Feature | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Nine-state model | Yes | Yes | Yes |
| Agent Team section | Yes | No | Partial |
| Agent entry state per agent | Yes | No | No |
| Design principles | Yes | Yes | Yes (bold framing) |
| Graphite in responsibilities table | No | No | Yes |
| GitHub in responsibilities table | No | No | Yes |
| Project/Team as required schema fields | No | Yes | No |
| Estimate as optional schema field | No | Yes | No |
| Risk level as optional schema field | No | Yes | No |
| Gate rule count | 8 | 6 | 7 |
| T-1 gate: assignee + objective required | No | No | Yes |
| T-4 gate: Graphite stack initialization | No | No | Yes |
| Named Linear views | No | Yes | No |
| Linear CLI/API in tooling | No | No | Yes |
| Worktree creation step | Yes | No | Yes |
| WIP limits | Yes | No | No |
| Scope change rules | Yes | Yes | No |
| Operating cadence table | Yes | Partial | No |
| Execution log cadence (4-hour) | No | No | Yes |
| Director rollup verification at close | No | No | Yes |
| Commit references Linear identifier | Yes | Yes | Yes |

---

## Strengths by Proposal

### Claude — strengths to preserve

- **Agent Team table** with entry state per agent is the clearest expression of
  how the Director routes work and is directly derived from `design.md`.
- **Eight gate rules** covering the full planning track (T-1 through T-3) close
  a gap both other proposals leave open by treating `Draft` → `Backlog` as
  ungated.
- **WIP limits** section is unique and addresses a real failure mode in
  agentic workflows: unbounded parallelism masquerading as progress.
- **Scope change rules** provide a clear stop-and-escalate protocol when
  implementation reveals out-of-scope work.
- **Operating cadence table** makes the heartbeat of the process explicit and
  linkable to agent polling behavior.

### Codex — strengths to preserve

- **Project and Team as required fields** closes a real gap. An issue without a
  Project or Team attribution is effectively invisible in Linear's rollup views.
  Making these required rather than optional enforces correct issue creation from
  the start.
- **Estimate and Risk level as optional fields** are practically useful and
  absent from the others.
- **Named Linear views** (`My In Progress`, `Blocked`, `Selected by Priority`,
  `In Review`, `Done This Cycle`) are immediately actionable team surfaces that
  operationalize the state model. This is the most actionable tooling
  recommendation across all three proposals.
- **Concise prose** demonstrates that the full process can be stated without
  the verbosity of the Claude proposal, which is a useful benchmark for editing
  the merged document.

### Gemini — strengths to preserve

- **Graphite and GitHub in the Separation of Responsibilities table** completes
  the picture. The split between Linear (state), GitHub (code), and Graphite
  (review stack) is an important architectural decision that belongs in this
  table.
- **"Agent-First" design principle** is a clear statement of intent that
  distinguishes this workflow from a human-centric process with agent
  bolt-ons.
- **T-1 gate: Explorer/Architect assignment + objective definition** adds a
  meaningful precondition before planning work begins, preventing issues from
  drifting through `Planning` without an owner or goal.
- **T-4 gate: Graphite stack initialization** is more precise than "branch
  created" and reflects the actual toolchain. An Engineer operating this
  workflow should initialize the stack, not merely a branch.
- **Director rollup verification before `Done`** introduces a final integrity
  check that is missing from both other proposals. It prevents an issue from
  closing if acceptance criteria or evidence are incomplete.
- **Four-hour execution log cadence** gives agents an explicit tempo for
  progress reporting, which improves resumability without requiring a full
  transcript.
- **Linear CLI/API in tooling** acknowledges that agents interact with Linear
  programmatically and should reference the correct interface.

---

## Points of Conflict

### Gate numbering and granularity

Claude has eight gates; Codex has six; Gemini has seven. The differences are
not contradictory — they reflect different choices about how granularly to gate
the planning track. The merger should use a numbered set derived from Claude's
eight but enriched with Gemini's precondition specificity.

### Required versus optional schema fields

Claude and Gemini treat Project, Team, and Priority as optional. Codex makes
them required. The merger should adopt Codex's position: an issue without a
Project or Team is operationally incomplete in Linear.

### Scope change rules

Claude and Codex include scope change rules. Gemini omits them. The merger
should keep them; scope discipline is essential in agentic workflows.

### WIP limits

Only Claude includes WIP limits. They should be retained in the merger.

### Prose density

Gemini's workflow section is too brief to serve as an operational guide. Claude's
is thorough but contains redundancy. The merger should aim for Claude's
completeness at Codex's density.

---

## Merger Recommendations

1. Adopt the nine-state model from all three proposals unchanged.
2. Retain Claude's Agent Team table with entry state per agent.
3. Add Graphite and GitHub to the Separation of Responsibilities table
   (Gemini).
4. Promote Project and Team to required schema fields; add Estimate and Risk
   level as optional (Codex).
5. Consolidate gate rules to eight: keep Claude's structure, enrich T-1 with
   Gemini's assignee + objective precondition, enrich T-4/T-5 with Graphite
   stack initialization.
6. Add "Agent-First" and "Small Batches" to design principles (Gemini).
7. Add named Linear views to the Tooling section (Codex).
8. Add Linear CLI/API to the Tooling section (Gemini).
9. Add Director rollup verification step before `Done` (Gemini).
10. Add four-hour execution log cadence as a default agent reporting tempo
    (Gemini).
11. Retain WIP limits and scope change rules (Claude).
12. Retain operating cadence table (Claude).
13. Target prose density between Claude and Codex: complete but not redundant.
