# Proposal Analysis: Three-Way Comparison

**Date**: 2026-03-16
**Documents compared**:
- `docs/claude/team-proposal.md` (Claude)
- `docs/codex/team-proposal.md` (Codex)
- `docs/gemini/team-proposal.md` (Gemini)

---

## Summary Scores by Dimension

| Dimension | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| Gap analysis depth | Strongest | Moderate | Light |
| State machine precision | Strongest | Moderate | Moderate |
| Agent invocation model | Strongest | Not addressed | Not addressed |
| Role contract detail | Strong | Strong | Moderate |
| Concurrency and locking | Weak | Strongest | Not addressed |
| Failure handling | Moderate | Strongest | Light |
| Observability and metrics | Not addressed | Strongest | Not addressed |
| Core philosophy framing | Not named | Not named | Strongest |
| Execution log protocol | Referenced | Not addressed | Strongest |
| Phased rollout | Not addressed | Strongest | Not addressed |
| Artifact bundle definitions | Moderate | Strongest | Not addressed |
| Practical implementation recs | Not addressed | Light | Strongest |
| Cross-cutting control agents | Not addressed | Strongest | Not addressed |
| Readability and conciseness | Moderate | Moderate | Strongest |

---

## Claude's Proposal — Strengths and Weaknesses

### Strengths

**State machine reconciliation**: Claude is the only proposal that explicitly
reconciles the state name conflicts between `docs/design.md` and
`docs/tracking-process.md`. It identifies that design.md uses informal names
("ready for scheduling", "ready for implementation", "ready for review") that
do not match the canonical nine-state model. It provides the canonical state
table with ownership and meaning.

**Gap analysis**: Claude identifies 19 specific gaps in `docs/design.md` and
resolves or flags each one. No other proposal reaches this depth.

**Agent invocation model**: Claude is the only proposal that addresses the
relationship between the Director orchestration layer and the existing Codex
multi-agent pipeline in `.codex/config.toml`. It correctly identifies that
these are not competing models — the Codex pipeline is a per-session execution
substrate and the Director is the system-level event-driven orchestrator.

**ADR requirements**: Claude explicitly lists seven decisions that must be
elevated to ADRs before implementation begins. The other proposals mention ADRs
generally without enumerating which decisions require them.

**Pre-flight checklists**: Claude provides explicit pre-flight checklists for
the Engineer and Technical Lead — the conditions that must be true before an
agent begins work. These are directly actionable.

**Dispatch table**: Claude provides an explicit state-to-agent dispatch table,
making the Director's routing logic unambiguous.

**Tool assignment table**: Claude provides a clear table showing which tools
each agent uses, and notes the gap that AWS has no assigned agent.

### Weaknesses

**No concurrency or locking model**: Claude says "one active agent per issue at
a time" but does not define what locking mechanism enforces this or how lock
recovery works.

**No observability or metrics**: Claude does not define any SLOs, metrics, or
reporting cadence. There is no way to measure team performance.

**No phased rollout**: Claude does not propose how to implement the system
incrementally.

**No cross-cutting agents**: Claude does not propose the Compliance Gate or
Metrics Reporter roles that Codex introduces.

**No failure recovery procedures**: Beyond "document and move to Blocked",
Claude does not address recovery from specific failure types (stale locks,
broken PR stacks, API failures).

---

## Codex's Proposal — Strengths and Weaknesses

### Strengths

**Cross-cutting control agents**: Codex introduces two roles not present in the
other proposals:
- *Compliance Gate*: validates required artifacts before any state transition.
  This is a valuable enforcement layer that prevents gates from being bypassed.
- *Metrics Reporter*: publishes cycle time, lead time, and defect metrics per
  ticket and per role.

**Concurrency and locking model**: Codex is the only proposal that defines
explicit locking semantics:
- Ticket lock acquired on `Selected` → `In Progress`
- Branch namespace lock acquired on first PR in stack
- Lock release on `Done`, cancellation, or Director recovery action

This is essential for preventing duplicate work and PR collisions.

**Failure handling and recovery**: Codex provides specific recovery procedures:
- Transient API failures: exponential backoff with bounded retries
- Stale locks: Director runs lock-reconciliation
- Broken PR stack: Engineer runs stack repair workflow
- Invalid state transition: reject with reason and notify owner

**Observability and metrics**: Codex defines five measurable metrics: lead
time, review latency, reopen rate, defect escape rate, and agent failure rate,
with a daily/weekly reporting cadence.

**Phased rollout plan**: Codex proposes four implementation phases: governance
and artifacts → scheduling and planning → engineering and review → resilience
and optimization.

**Artifact bundle definitions**: Codex explicitly names the artifacts required
for each phase (planning bundle, scheduling bundle, implementation bundle,
review bundle, research bundle).

**Access boundaries**: Codex defines authorization rules: who can approve
architecture-affecting changes, that engineers cannot merge without required
ADR linkage, and that the Director can pause all dispatch for incident
containment.

### Weaknesses

**State name inconsistency**: The Coordinator contract says "Preconditions:
ticket in `Selected`" — this is wrong. The Coordinator entry state is `Backlog`
per all other documents. This is a significant error in the proposal.

**Director contract is incomplete**: Codex says the Director inputs include
`Draft`, `Planning`, `Selected`, `Blocked` — but omits `In Review`, which the
Director must monitor to invoke the Technical Lead.

**Agent invocation model unaddressed**: Codex does not acknowledge the existing
`.codex/config.toml` multi-agent pipeline or explain how it relates to the
Director model.

**Less detail on individual agents**: The role contracts are higher-level
compared to Claude's per-agent specification. The Engineer, Architect, and
Technical Lead sections lack the depth needed to build against.

**Compliance Gate as a separate agent**: The Compliance Gate concept is
valuable, but treating it as a separate agent adds operational complexity.
It may be better implemented as a Director sub-function invoked before each
dispatch.

---

## Gemini's Proposal — Strengths and Weaknesses

### Strengths

**Core philosophy framing**: Gemini names the operating philosophy: "Spec-Driven
Development." This is a clear, memorable frame that orients all agent behavior.
The other proposals operate on the same principles but do not name them.

**Execution Log protocol**: Gemini provides the clearest description of the
Execution Log requirement — the mandatory `## Execution Log` section in Linear
issue descriptions. Gemini frames this around three concrete purposes:
*resumability* (another agent or human can pick up where the previous left off),
*transparency* (audit trail), and *handoff* (explicit signals for the next
agent). This framing is stronger than Claude's more procedural description.

**Explorer trigger breadth**: Gemini is the only proposal that correctly
identifies that the Explorer should be invoked not only by the Architect during
Planning but also when a task hits `Blocked` due to technical unknowns. This
is a meaningful operational detail.

**Practical implementation recommendations**: Gemini's recommendations section
is the most immediately actionable:
- Ratify the Constitution (`.specify/memory/constitution.md`)
- Define a canonical `make validate` command
- Update PR templates with traceability, validation evidence, and verdict
  sections
- Implement Director as a long-running process with exponential backoff

**Readability**: Gemini's proposal is the most readable. The role definitions
are concise and scannable. Entry/exit states are clearly labeled per role.

**Four-tier review explicitly labeled**: Gemini explicitly names and numbers
the four review tiers (Automated Validation, Implementation Fidelity,
Architectural Integrity, Final Polish) in the Technical Lead section.

### Weaknesses

**Light gap analysis**: Gemini identifies six gap areas from design.md but does
not resolve or enumerate them with the same specificity as Claude's 19-item
table.

**No concurrency model**: Gemini does not address concurrency, locking, or what
happens when two agents try to act on the same issue.

**No failure handling**: Beyond the Director's exponential backoff mention in
recommendations, Gemini does not define failure recovery procedures.

**No metrics or SLOs**: No observability content.

**No phased rollout**: Implementation approach is not addressed.

---

## Key Conflicts to Resolve

| Conflict | Resolution |
| --- | --- |
| Coordinator entry state: Codex says `Selected`, others say `Backlog` | `Backlog` is correct per tracking-process.md |
| Director inputs: Codex omits `In Review` | Add `In Review` → Technical Lead to Director dispatch |
| Compliance Gate as separate agent vs. Director sub-function | Implement as a Director sub-function invoked before each dispatch; avoids agent proliferation |
| Explorer trigger: Architect only (Claude) vs. Architect + Blocked states (Gemini) | Gemini's broader trigger is correct and more operationally useful |
| Execution log: Claude's procedural vs. Gemini's purpose-framed | Gemini's framing (resumability, transparency, handoff) is stronger |
| Core philosophy: unnamed (Claude, Codex) vs. named (Gemini) | Adopt Gemini's "Spec-Driven Development" naming |

---

## Unique Contributions Per Proposal

### Claude unique contributions to preserve
- 19-item gap analysis with resolutions
- State name reconciliation table with `docs/design.md` conflicts
- Agent invocation model (Codex pipeline as internal execution substrate)
- Explicit dispatch table (state → agent)
- Seven specific ADRs required before implementation
- Pre-flight checklists per agent
- Worktree lifecycle specification
- Tool assignment table with AWS gap identified

### Codex unique contributions to preserve
- Compliance Gate as enforcement mechanism (recast as Director sub-function)
- Metrics Reporter as lightweight separate agent
- Concurrency locking model (ticket lock + branch namespace lock + release rules)
- Failure recovery procedures (backoff, lock reconciliation, stack repair)
- Five observability metrics with reporting cadence
- Phased rollout (4 phases)
- Artifact bundle definitions per phase
- Access boundary definitions
- "Director can pause all dispatch for incident containment"

### Gemini unique contributions to preserve
- "Spec-Driven Development" as the named operating philosophy
- Execution Log protocol framed around resumability, transparency, handoff
- Explorer invoked also when tasks are `Blocked` due to technical unknowns
- Practical implementation recommendations (Constitution, `make validate`, PR templates)
- Clear entry/exit state labels per role in the role definitions

---

## What All Three Agree On

All three proposals agree on the core six-agent team structure (Director,
Architect, Coordinator, Engineer, Technical Lead, Explorer), the nine-state
Linear lifecycle, the use of Graphite for stacked PRs, the requirement for ADRs
on significant architectural decisions, and the principle that each issue has
exactly one active agent at a time.
