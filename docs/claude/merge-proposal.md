# Merge Proposal: Agent Team Document Strategy

**Date**: 2026-03-16
**Input**: `proposal-analysis.md`
**Output target**: `merged.md`

---

## Merger Objectives

1. Preserve the strongest ideas from each proposal without duplication.
2. Resolve all identified conflicts with a clear rationale.
3. Produce a document that is complete enough to drive ADR creation and
   implementation planning.
4. Maintain the readability and conciseness of Gemini's framing while
   incorporating Claude's depth and Codex's operational rigor.

---

## Document Structure

The merged document will use the following top-level sections, in order:

1. Purpose
2. Core Philosophy (Gemini's "Spec-Driven Development" framing)
3. Design Principles (Claude's list, enhanced)
4. Agent Roster (six primary agents + Metrics Reporter)
5. Cross-Cutting Enforcement (Compliance Gate as Director sub-function)
6. Linear State Machine (Claude's canonical table)
7. Dispatch Table (Claude's state → agent mapping)
8. Artifact Standards (Codex's bundle definitions, enhanced)
9. Concurrency and Locking Model (Codex's model)
10. Execution Log Protocol (Gemini's framing, Claude's detail)
11. Failure Handling and Recovery (Codex's specifics)
12. Observability and Metrics (Codex's metrics)
13. Tool Assignments and Access Boundaries (Claude's table + Codex's rules)
14. Gaps Resolved from design.md (Claude's gap table, condensed)
15. ADR Backlog (Claude's seven ADRs + Codex's additions)
16. Phased Rollout (Codex's four phases)
17. Practical Implementation Recommendations (Gemini's section)
18. Open Questions (merged from all three)

---

## Conflict Resolutions

### Coordinator entry state
**Conflict**: Codex says Coordinator precondition is "ticket in `Selected`".
Claude and Gemini correctly say `Backlog`.
**Resolution**: `Backlog` is canonical per `docs/tracking-process.md`. The
Codex proposal contains an error. The merged document uses `Backlog`.

### Director dispatch coverage
**Conflict**: Codex's Director contract lists inputs as `Draft`, `Planning`,
`Selected`, `Blocked` — omitting `In Review`.
**Resolution**: The Director must dispatch the Technical Lead for issues in
`In Review`. Add `In Review` → Technical Lead to the dispatch table.

### Compliance Gate: separate agent vs. Director sub-function
**Conflict**: Codex proposes Compliance Gate as a named cross-cutting agent.
Claude does not include it. Gemini does not include it.
**Resolution**: The Compliance Gate validation logic is valuable but adding a
seventh primary agent for what is essentially a pre-dispatch check adds
operational surface area. In the merged document, Compliance Gate is
implemented as a named validation sub-function that the Director invokes before
every dispatch. The function is described explicitly so it can be implemented
as a separate module internally, but it is not a separately invocable agent.

### Metrics Reporter: separate agent
**Conflict**: Only Codex proposes this role.
**Resolution**: Accept. Metrics Reporter is a lightweight, read-only agent that
requires no write access to any system except the reporting destination. It does
not interfere with other agents. It is included as a support agent distinct from
the six primary delivery agents.

### Explorer trigger scope
**Conflict**: Claude says Explorer is invoked "on demand by Architect or
human". Gemini correctly adds that Explorer should also be invoked when a task
hits `Blocked` due to technical unknowns.
**Resolution**: Gemini's broader trigger is operationally correct. The merged
document defines Explorer triggers as: (1) Architect during Planning, (2) any
agent when a task blocks on technical unknowns, (3) direct human invocation.

### Execution Log framing
**Conflict**: Claude describes the Execution Log procedurally. Gemini frames it
around three purposes: resumability, transparency, handoff.
**Resolution**: Use Gemini's purpose framing as the lead, then incorporate
Claude's detail on entry format and reporting tempo.

### Core philosophy naming
**Conflict**: Claude and Codex describe spec-driven principles without naming
them. Gemini names the philosophy "Spec-Driven Development".
**Resolution**: Adopt Gemini's named framing. It provides a memorable anchor
for all downstream agent behavior.

---

## Section-by-Section Source Decisions

| Section | Primary Source | Enhancements From |
| --- | --- | --- |
| Purpose | Claude (most complete) | — |
| Core Philosophy | Gemini (named framing) | Claude (principles list) |
| Design Principles | Claude | Gemini |
| Director | Claude (dispatch table, concurrency) | Codex (pause authority, retry policy) |
| Architect | Claude (depth) | Gemini (entry/exit clarity) |
| Coordinator | Claude (progressive promotion) | Gemini (entry/exit clarity) |
| Engineer | Claude (pre-flight, TDD, worktree) | Gemini (entry/exit clarity) |
| Technical Lead | Claude (four tiers, pre-flight) | Gemini (entry/exit labels) |
| Explorer | Claude (output format, storage) | Gemini (trigger breadth) |
| Metrics Reporter | Codex (sole source) | — |
| Compliance Gate | Codex (concept) | Claude (as Director sub-function) |
| Linear State Machine | Claude (canonical, reconciled) | Codex (transition ownership) |
| Dispatch Table | Claude (sole source) | Codex (Director pause authority) |
| Artifact Standards | Codex (bundle definitions) | Claude (storage paths) |
| Concurrency and Locking | Codex (sole source) | — |
| Execution Log Protocol | Gemini (framing) | Claude (format, tempo) |
| Failure Handling | Codex (sole source) | — |
| Observability and Metrics | Codex (sole source) | — |
| Tool Assignments | Claude (table) | Codex (access boundaries) |
| Gap Table | Claude (19 items) | — |
| ADR Backlog | Claude (7 items) | Codex (5 items, deduplicated) |
| Phased Rollout | Codex (4 phases) | — |
| Practical Recs | Gemini (sole source) | — |
| Open Questions | All three (merged) | — |

---

## Agents in the Merged Document

### Primary delivery agents (six)

1. Director — orchestrator and lifecycle monitor
2. Architect — planning specialist
3. Coordinator — scheduling specialist
4. Engineer — implementation specialist
5. Technical Lead — review specialist
6. Explorer — research specialist

### Support agents (one)

7. Metrics Reporter — observability and reporting

### Cross-cutting function (not a separate agent)

- Compliance Gate — pre-dispatch artifact validation, implemented as a
  Director sub-function

---

## Style and Formatting Rules for merged.md

- Use the same section depth conventions as Claude's proposal (H2 for major
  sections, H3 for sub-sections).
- Lead each agent section with a one-sentence mission statement (Codex's
  pattern).
- Include entry state and exit state labels in each agent section (Gemini's
  pattern).
- Include pre-flight checklists for Engineer and Technical Lead (Claude's
  pattern).
- Use tables for state machine, dispatch table, tool assignments, gap analysis,
  and ADR backlog.
- Do not duplicate content across sections. Cross-reference instead.
- Flag unresolved open questions at the bottom, not inline.
