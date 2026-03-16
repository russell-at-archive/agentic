# Tracking Proposal Analysis

## Scope

This analysis compares the three tracking proposals:

- `docs/claude/tracking-proposal.md`
- `docs/codex/tracking-proposal.md`
- `docs/gemini/tracking-proposal.md`

The goal is to identify the strongest ideas in each and define a coherent merged
proposal for a Linear-first operating model.

## Evaluation Criteria

The proposals were assessed against six criteria:

1. Lifecycle completeness
2. Operational clarity
3. Agent workflow fit
4. Governance and quality controls
5. Tooling realism
6. Maintainability (readability and enforceability)

## Proposal Comparison

| Dimension | Claude proposal | Codex proposal | Gemini proposal |
| --- | --- | --- | --- |
| Lifecycle coverage | Full end-to-end lifecycle with expanded states and explicit tracks | Expanded states included, but lighter planning/scheduling detail | Expanded states included with concise transitions |
| Agent model | Strongest role model (Director, Architect, Coordinator, Engineer, TL, Explorer) with entry states | Minimal role detail | Good role references, less strict than Claude |
| State transition rigor | Strongest; includes planning, scheduling, implementation, and blocker return semantics | Clear but simplified | Clear but some transition ambiguity |
| Gate rules | Most rigorous and auditable (T-1 to T-8) | Useful baseline gates (T-1 to T-6) | Practical gates tied to operations and automation |
| Workflow detail | Most complete, including planning PR, issue fan-out, review loop | Straightforward execution workflow | Good high-level flow for autonomous operations |
| Tooling integration | Strong Linear + Speckit + Graphite + Git integration details | Linear-focused; less tooling depth | Explicit Linear API/CLI and Graphite usage emphasis |
| Readability and brevity | Most comprehensive, but longest | Best readability and concise language | Good executive clarity |
| WIP and cadence controls | Includes WIP limits and stale-work handling | Includes cadence, no WIP policy details | Includes cadence and log expectations |

## Strongest Ideas by Proposal

### From `docs/claude/tracking-proposal.md`

- Complete nine-state lifecycle with `Blocked` as a returnable interruption
  state.
- Clear role-to-state ownership across the agent team.
- Strong transition tracks (planning, scheduling, implementation).
- Comprehensive gate model for quality and traceability.
- Explicit handling of Linear/Git linking conventions.
- WIP limits and stale work policy to preserve flow.

### From `docs/codex/tracking-proposal.md`

- Clean structure and direct language with low ambiguity.
- Good separation of source-of-truth responsibilities.
- Practical issue schema and evidence expectations.
- Easy to operationalize for humans and agents without excessive ceremony.

### From `docs/gemini/tracking-proposal.md`

- Strong focus on autonomous operations and throughput.
- Useful operational gates around worktree/stack initialization.
- Practical reminder to attach concrete validation artifacts before `Done`.
- Clear statement of why Linear improves project-level visibility.

## Key Conflicts and Resolutions

1. State model granularity:
The merged proposal keeps the full expanded state model from Claude/Codex/Gemini,
not a compact execution-only model.

2. Process depth versus readability:
The merged proposal retains Claude-level rigor but adopts Codex-style wording and
section structure to reduce operational overhead.

3. Gate strictness:
The merged proposal keeps an auditable gate system while simplifying duplicate or
implicit checks.

4. Agent logging intensity:
The merged proposal keeps proportional logging from Claude and avoids rigid
time-based logging requirements from Gemini unless required by team policy.

5. Tooling specificity:
The merged proposal keeps concrete Linear, Speckit, Graphite, and GitHub
integration guidance, but avoids over-prescribing command-level behavior.

## Recommended Merge Strategy

Use Claude as the structural baseline, then apply Codex editorial compression and
Gemini operational emphasis.

### Keep

- Expanded lifecycle states
- Agent ownership model and entry conditions
- Transition and gate rigor
- Evidence-based completion criteria
- Scope-change and ADR escalation protocol
- WIP limits and stale-task review cadence

### Simplify

- Repetitive restatements of the same guardrails
- Overly long narrative paragraphs where short rule lists are clearer

### Add

- Explicit mention that this remains a proposal until ratified by ADR
- Standardized Linear field usage (state, assignee, dependencies, project,
  priority, links)
- A compact "definition of done" checklist

## Final Recommendation

Adopt a merged proposal that is:

- Lifecycle-complete (expanded Linear states)
- Agent-operable (clear role handoffs)
- Quality-gated (state transition gates)
- Evidence-driven (verification before `Done`)
- Concise enough to execute without interpretation drift

This merged version is documented in `docs/codex/merge-proposal.md`.
