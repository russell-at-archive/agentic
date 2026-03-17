# Selected Proposal Defense

## Selection

The strongest document is
`docs/codex/merged.md`.

## Why This One Wins

### Best Architectural Discipline

The Codex version stays focused on the actual architectural decision:

- add a pre-lifecycle intake role
- keep the formal lifecycle beginning at `Draft`
- avoid introducing unnecessary new Linear states

That is the cleanest fit with the repository's current system design.

### Strongest Alignment with Existing Repository Doctrine

The Codex version is the most coherent with the current process documents:

- `docs/agentic-team.md`
- `docs/planning-process.md`
- `docs/tracking-process.md`
- `docs/open-questions.md`

It preserves the current state-driven lifecycle, uses the existing planning
taxonomy, and resolves the intake gap without forcing a broader redesign of
dispatch behavior.

### Best Separation of Concept from Implementation

The Codex version defines:

- the new role
- its boundaries
- the CTR structure
- the Linear handoff contract
- failure modes
- follow-on documentation changes

It does this without prematurely locking in platform-specific implementation
details such as exact model choices, command file paths, or agent runtime
wiring.

That makes it a better proposal document. It is easier to ratify because it
asks for the right decision at the right level of abstraction.

### Complete Enough to Act On

The document is not just clean; it is complete enough to support a decision.
It covers the core pieces that need to be true before adoption:

- mission
- entry and exit conditions
- conversation protocol
- prompt format
- handoff mechanics
- role boundaries
- guardrails
- follow-on changes
- remaining open questions

Nothing essential is missing for a human reviewer to evaluate the proposal.

## Why Not the Claude Version

`docs/claude/merged.md` is strong and is the best implementation-oriented
document of the three.

Its strengths:

- the best verification gate
- stronger duplicate handling
- clearer operator workflow
- richer operational detail

But it is slightly weaker as the canonical proposal because it mixes too many
layers into one artifact:

- architecture
- process design
- runtime implementation
- platform-specific tooling
- rollout details

It overcommits early on things that should likely be follow-on decisions, such
as specific model choices, exact tool lists, command paths, and execution log
formats.

That makes it a strong second-place document and a useful implementation
reference, but not the best canonical proposal.

## Why Not the Gemini Version

`docs/gemini/merged.md` is concise and readable, but it is too thin to serve as
the canonical proposal.

Its strengths:

- easy to scan
- simple mental model
- good emphasis on a drafting entrypoint

Its weaknesses:

- not enough architectural argument
- not enough detail on boundaries and handoff
- unclear lifecycle fit
- less precise CTR framing
- too many open assumptions left unstated

It works better as a summary than as the primary decision document.

## Final Ranking

1. `docs/codex/merged.md`
2. `docs/claude/merged.md`
3. `docs/gemini/merged.md`

## Recommendation

Use `docs/codex/merged.md` as the base document for ratification.

If the work moves into implementation planning, selectively pull in the best
operational sections from `docs/claude/merged.md`, especially:

- the verification gate
- duplicate handling
- stakeholder confirmation flow
- operator workflow
