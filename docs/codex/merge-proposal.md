# Merge Proposal: Feature Draft Agent

## Purpose

This document compares the three existing Feature Draft Agent proposals in
`docs/codex/`, `docs/claude/`, and `docs/gemini/`, then proposes a merged
direction that preserves the strongest ideas from each while removing
conflicting or unnecessary complexity.

## Source Comparison

### Codex Proposal

Strongest ideas:

- clear architectural fit with the current state-driven system
- strong role boundaries between Feature Draft Agent, Director, and Architect
- explicit argument that the new agent should be a pre-lifecycle intake role
- practical Linear issue schema for `Draft`
- disciplined treatment of ADR impact and follow-on documentation updates

Weaknesses:

- lighter on the actual intake conversation mechanics
- less explicit about agent invocation surface and operator workflow
- uses `Refine` in CTR, while other proposals use `Requirements` or `Result`

### Claude Proposal

Strongest ideas:

- best articulation of the problem as a gap between raw stakeholder intent and
  planning-ready input
- detailed, usable conversation protocol with bounded question count
- strongest explanation of applying CTR from the product and stakeholder
  perspective rather than the planning perspective
- good operational detail around failure modes, duplicate handling, execution
  logging, and agent definitions
- useful design-prompt template with acceptance signal

Weaknesses:

- introduces more lifecycle machinery than is necessary for first adoption
- proposes a `Drafting` state that conflicts with the simpler fit described in
  the Codex proposal
- includes platform-specific implementation detail that is premature for a
  concept-level architectural proposal

### Gemini Proposal

Strongest ideas:

- compact and easy to understand
- good naming shorthand with `Drafter`
- simple framing of the outcome as a CTR-based Draft Design Prompt
- good proposal for an operator-facing command, `/speckit.draft`

Weaknesses:

- too thin to stand alone as the canonical proposal
- introduces an `Idea` state without sufficient justification
- uses `Result` in CTR, which is less consistent with the existing planning
  language in this repository

## Key Agreements Across All Three

All three proposals agree on the core design:

- a new intake-focused agent should exist
- it should talk to a human before formal planning begins
- its output should be a structured prompt written into Linear
- the handoff target is the Architect
- the goal is to improve the quality of issues entering `Draft`

This is the stable center of the design and should be retained.

## Main Points of Conflict

### 1. Pre-lifecycle role vs new workflow state

- Codex argues the agent should be a pre-lifecycle role that creates the first
  tracked issue.
- Claude proposes a `Drafting` state.
- Gemini proposes an `Idea` state.

Recommendation:

Do not add `Drafting` or `Idea` in the first version. The Codex position is
stronger because it preserves the current state model and avoids unnecessary
Linear workflow churn. The Feature Draft Agent should be invoked directly by a
human or intake surface, then create a `Draft` issue as its handoff artifact.

### 2. CTR vocabulary

- Codex uses `Context`, `Task`, `Refine`.
- Claude maps intake CTR to `Context`, `Task`, `Requirements`.
- Gemini uses `Context`, `Task`, `Result`.

Recommendation:

Use `Context`, `Task`, and `Refine` as the canonical structure, because it
fits the repository's existing CTR language in `docs/planning-process.md`.
Borrow Claude's stronger content model by making `Refine` explicitly include:

- must-haves
- constraints
- non-goals
- open questions
- risks
- acceptance signal

This keeps naming consistent while preserving Claude's stronger operational
content.

### 3. Scope of implementation detail in the proposal

- Codex stays at the architectural and process level.
- Claude includes model choices, specific tools, agent file definitions, and
  execution log details.
- Gemini includes a lightweight command concept.

Recommendation:

The merged proposal should separate:

- architectural decision and process changes
- implementation notes and next steps

Keep Gemini's `/speckit.draft` as a candidate interface and Claude's operator
details as follow-on implementation notes, not as core design requirements.

## Merged Thoughtstream

### Core Position

Add a `Feature Draft Agent` as a narrowly scoped pre-lifecycle intake role.
Its job is to transform a rough human request into a planning-ready `Draft`
issue in Linear using a structured CTR design prompt.

This agent should not be treated as a replacement for the Architect, nor as a
new stateful phase in the Director-managed lifecycle. It exists immediately
before the current lifecycle begins.

### Why This Is the Right Boundary

The current documentation assumes a usable `Draft` issue already exists, but it
does not define who creates that issue from raw intent. That gap shows up in
`docs/open-questions.md` as `OQ-06`, and the three proposals all correctly
identify it as the missing intake function.

Placing the Feature Draft Agent before the state machine preserves the current
design principle that once an issue exists, state drives dispatch. The Draft
Agent creates that first issue; the Director then continues operating exactly
as designed.

### Agent Mission

The Feature Draft Agent conducts a short, focused stakeholder conversation to
produce a `Draft Design Prompt` with three sections:

- `Context`: current situation, affected users or systems, urgency, trigger,
  and known constraints
- `Task`: desired behavior, outcome, and definition of success
- `Refine`: must-haves, non-goals, constraints, risks, open questions, and the
  stakeholder-facing acceptance signal

This prompt is not a spec and not a plan. It is a high-quality intake artifact
that gives the Architect a better starting point for specification and
planning.

### Conversation Model

The Claude proposal has the best structure here and should be adopted with only
minor simplification.

The agent should use a bounded three-pass conversation:

1. `Context`
   Capture the current problem, who is affected, and why the request matters
   now.
2. `Task`
   Capture the desired user-visible outcome, expected behavior, and what
   success looks like.
3. `Refine`
   Capture must-haves, non-goals, constraints, risks, and unresolved questions.

Guardrails:

- no more than nine clarification questions total unless the user explicitly
  asks for a deeper drafting session
- no implementation design questions
- unresolved answers are captured as open questions, not silently guessed
- if the request is not a feature, the agent still completes the draft using
  the repository's standard classification taxonomy

### Classification

The agent should classify every request using the taxonomy already defined in
`docs/planning-process.md`:

- `feature`
- `bug fix`
- `refactor`
- `dependency/update`
- `architecture/platform`

This is one of the strongest shared ideas across the proposals and should be
retained unchanged.

### Linear Handoff

The output should be a new or updated Linear issue in `Draft` under:

- Project: `Agentic Harness`
- Team: `Platform & Infra`
- State: `Draft`

The issue description should contain:

- intake summary
- classification
- objective
- CTR draft prompt
- open questions
- handoff notes
- acceptance signal

The Codex proposal has the best architectural argument here: creating the
`Draft` issue is itself the handoff signal. No additional Director behavior is
required.

### Role Boundaries

The merged role boundaries should be:

- `Feature Draft Agent`: conversational intake and CTR draft creation
- `Director`: detects `Draft` issues and dispatches the Architect
- `Architect`: validates the objective, resolves planning ambiguities, and
  produces `spec.md`, `plan.md`, `tasks.md`, and required ADRs

The Feature Draft Agent must not:

- write `spec.md`
- write `plan.md`
- write `tasks.md`
- perform technical research that belongs to Explorer
- make architectural decisions

### Failure Handling

Claude contributes the strongest operational detail here. The merged proposal
should preserve these behaviors:

- if the stakeholder cannot answer a question, record it under open questions
- if a duplicate request appears to exist, surface that issue instead of
  blindly creating a new one
- if the request is clearly out of scope, do not create a ticket
- if the conversation stops early, do not silently promote weak intake into a
  planning-ready artifact

For first adoption, partial conversations should remain outside Linear unless a
human explicitly wants them saved. That is a simpler default than introducing a
new `Drafting` or `Idea` state.

### Operator Surface

Gemini's `/speckit.draft` idea is strong and should be kept as a likely
implementation path, but it should be framed as tooling, not as part of the
architectural decision itself.

Recommended operator surfaces:

- direct human invocation in each agent runtime
- optional future `/speckit.draft` command
- optional future Slack or web intake entrypoint

## Recommended Canonical Direction

If these three documents are merged into one canonical proposal, that document
should say:

1. The Feature Draft Agent is a pre-lifecycle intake role.
2. It does not introduce a new Linear state in the first version.
3. It produces a CTR-based Draft Design Prompt using `Context`, `Task`, and
   `Refine`.
4. It creates a `Draft` Linear issue in the existing project and team.
5. The Director and Architect lifecycle remains unchanged after issue creation.
6. Conversation structure, duplicate handling, and open-question capture should
   be explicit.
7. Platform-specific agent files and commands are follow-on implementation
   tasks, not prerequisites to accepting the concept.

## Suggested Document Structure for the Canonical Proposal

The merged canonical document should be organized as:

1. Summary
2. Problem Statement
3. Proposed Role
4. Why It Is Pre-Lifecycle, Not a New State
5. CTR Design Prompt Format
6. Conversation Protocol
7. Linear Handoff Contract
8. Role Boundaries
9. Failure Modes and Guardrails
10. Follow-On Documentation and ADR Changes
11. Open Questions

## Recommendation

Use the Codex proposal as the structural base.

Pull in from Claude:

- the three-pass conversation protocol
- the stronger explanation of intake-side CTR semantics
- duplicate and failure handling
- the design-prompt template concept

Pull in from Gemini:

- the concise mental model of "Drafter"
- the operator-facing `/speckit.draft` idea as a future interface

Do not carry forward:

- `Drafting` state
- `Idea` state
- platform-specific model and tool decisions as part of the architectural
  proposal

## Next Step

The next document should be a single canonical proposal in `docs/codex/` that
replaces the three competing drafts and is then either:

- elevated into an ADR-backed process change, or
- used as the basis for a narrower ADR plus follow-on implementation tasks
