# Proposal: Feature Draft Agent (Drafter)

**Status**: Proposed — pending ratification and ADR
**Date**: 2026-03-17
**Resolves**: OQ-06

---

## Summary

Add a **Feature Draft Agent** (short name: **Drafter**) as a pre-lifecycle intake role.
Its sole responsibility is to engage a human requestor in a focused, structured
conversation and transform a raw idea into a CTR-framed design prompt written as a
`Draft` Linear issue. The formal delivery lifecycle begins at `Draft`; this agent
creates the artifact that starts it.

Adoption requires an ADR because the Drafter is the first role in the system invoked
directly by a human rather than dispatched by the Director.

---

## Problem Statement

The current lifecycle begins at **Phase 1 — Intake & Classification**, where the
Architect receives a `Draft` Linear issue with an assumed-complete problem statement.
This assumption is routinely false. Stakeholders arrive with half-formed ideas, ambiguous
goals, and undiscovered constraints.

The gap is already documented in multiple places:

- `docs/agentic-team.md` assigns the Architect responsibility for confirming the
  objective and starting planning, but not for running an intake dialogue.
- `docs/planning-process.md` requires intake and classification before specification
  work begins but does not define an agent dedicated to that intake conversation.
- `docs/tracking-process.md` treats `Draft` as the first tracked state, meaning
  ideation quality directly affects planning quality.
- `docs/open-questions.md` flags this explicitly in OQ-06: "Should a future Triage
  agent create `Draft` issues from raw requests?"

The consequence is that the Architect absorbs two fundamentally different modes of work:
exploratory stakeholder interviewing (conversational, undirected) and formal planning
artifact production (disciplined, gate-governed). Splitting them produces a cleaner
handoff and protects planning capacity.

---

## Proposed Role

### Name

**Feature Draft Agent** — short identifier: **Drafter**

### Mission

Engage a human in a focused intake conversation and produce a planning-ready design
prompt in CTR form. Create the `Draft` Linear issue that serves as the formal entry
point to the delivery lifecycle.

### Phase

**Phase 0.5 — Feature Drafting** — sits before the existing Phase 1 (Intake &
Classification). It is the entry point to the system, not a phase the Director
orchestrates.

### Primary Responsibilities

1. Conduct a structured intake dialogue with the human requestor.
2. Classify the request using the existing planning taxonomy: `feature`, `bug fix`,
   `refactor`, `dependency/update`, or `architecture/platform`.
3. Resolve missing information that would block planning during the conversation; surface
   what cannot be resolved as explicit open questions.
4. Produce a CTR design prompt that is concise but planning-ready.
5. Present the completed CTR block to the human and obtain explicit confirmation before
   writing to Linear.
6. Create the Linear issue in `Draft` state with the CTR prompt, intake metadata, and a
   traceability summary of the intake conversation.
7. Stop at handoff — the Drafter must not create `spec.md`, `plan.md`, or `tasks.md`.

### Explicitly Out of Scope

- No implementation decisions
- No deep repository or code exploration (lightweight context gathering only)
- No technical investigation — that is Explorer's job, invoked by the Architect
- No planning artifact generation
- No issue decomposition into implementation tasks

---

## CTR in the Feature Draft Context

The Architect uses CTR as a technical planning method. The Drafter applies CTR from the
**product and stakeholder perspective**. The third pass is named **Refine** to stay
consistent with the Architect's CTR vocabulary, but the content is different:

| Pass | Architect (Planning) | Drafter (Intake) |
|------|----------------------|-----------------|
| **C — Context** | Inspect current codebase, patterns, constraints | What is the current situation, pain point, or opportunity? Who is affected? What triggers this request now? |
| **T — Task** | Define approach, interfaces, sequencing | What new behavior or capability is desired? What user-visible or operational result counts as success? |
| **R — Refine** | Tighten until decision-complete for implementer | Clarify assumptions, surface unresolved questions, identify risks, note suggested research areas, document non-goals and constraints, state measurable success criteria |

The output is a **design prompt** — not a spec, not a plan — but a well-structured
statement of intent that gives the Architect a solid foundation without requiring them to
re-interview the stakeholder.

---

## Conversation Protocol

The Drafter conducts intake in three passes with a hard cap of **nine questions across
all passes**. Quality of questions matters more than quantity.

### Pass 1 — Context

Establish situational grounding (maximum three questions):

- What is the current state of the world that makes this necessary?
- Who experiences the problem or benefit, and how often?
- What triggers this request now (deadline, incident, customer request, tech debt)?

### Pass 2 — Task

Define the desired outcome (maximum three questions):

- What should a user or system be able to do that it cannot do today?
- How will you know this is working correctly?
- Are there existing examples, analogues, or prior art to reference?

### Pass 3 — Refine

Bound and clarify the work (maximum three questions):

- What must this NOT do, touch, or change?
- What constraints exist (compliance, performance, compatibility, dependencies, budget)?
- Is there anything the Architect should know, or any risk already visible, before
  writing the spec?

### Verification Gate

After Pass 3, the Drafter synthesizes the CTR block, presents it in full to the
stakeholder, and waits for explicit confirmation before creating the Linear issue. The
stakeholder must either approve the prompt as written or request corrections. The Drafter
iterates until the stakeholder is satisfied or open questions are acknowledged.

This gate is mandatory. The Drafter must not write to Linear before stakeholder
confirmation.

### Conversation Guardrails

- Never ask for implementation decisions — redirect those to planning.
- If the stakeholder cannot answer a question, capture it as an open question; do not
  block.
- If the request is clearly a bug rather than a feature, classify accordingly and
  complete the intake with adjusted framing.
- If the stakeholder abandons the conversation, preserve the partial design prompt in a
  local file; do not create a Linear issue.
- The Drafter may perform lightweight context gathering (e.g., checking classification
  taxonomy in AGENTS.md) but must not perform deep code exploration. That boundary is
  enforced by tool access.

---

## Design Prompt Format

The design prompt is written as the Linear issue description and optionally saved to a
local `design-prompt.md` for traceability before the Linear issue number is assigned.

```markdown
## Intake Summary

- **Requester**: <name or team>
- **Classification**: feature | bug fix | refactor | dependency/update | architecture/platform
- **Urgency**: urgent | high | medium | low
- **Date**: <YYYY-MM-DD>
- **Objective**: <one-paragraph summary of the desired outcome>
- **Affected users or systems**: <list>

## CTR Design Prompt

### Context

<2–4 sentences: current situation, who is affected, what triggers this request,
known constraints or dependencies>

### Task

<2–4 sentences: desired new behavior or capability, in-scope changes, non-goals,
user-visible or operational success definition>

### Refine

**Must Have:**
- <requirement>

**Out of Scope:**
- <explicit exclusion>

**Constraints:**
- <compliance, performance, compatibility, or other constraint>

**Success Criteria:**
- <measurable outcome or definition of done that the stakeholder will recognize>

**Open Questions:**
- <anything the Architect should resolve before or during spec work>

**Suggested Research:**
- <optional: areas where Explorer may be useful during planning>

## Handoff Notes

<optional: anything that does not fit the CTR structure but is useful for the Architect>

## Intake Traceability

Intake conducted: <YYYY-MM-DDTHH:MM:SSZ>
Turns: <N>
Confirmation: obtained from <stakeholder>
```

---

## Lifecycle Integration

### Updated Lifecycle Flow

```
[Human Request]
      ↓
Phase 0.5 — Feature Drafting  (Drafter)
      ↓     [creates Draft Linear issue]
Phase 1   — Intake & Classification  (Architect validates, classifies, assigns)
      ↓
Phase 2   — Specification  (Architect)
      ...
```

### Linear State Machine

No new Linear state is added. The Drafter creates the issue directly in `Draft` state
upon stakeholder confirmation. The existing `Draft` → `Planning` transition (T-1) and
all downstream states are unchanged.

Adding a new pre-`Draft` state would require updates to `docs/tracking-process.md`,
`docs/agentic-team.md`, the Director's dispatch logic, and the Linear project
configuration. The benefit — tracking in-flight conversations — is achievable more
cheaply by persisting a local `design-prompt.md` until the conversation is complete.

### Director Dispatch

The Director does **not** dispatch the Drafter. The Drafter is the system entry point,
invoked directly by a human via `/speckit.draft`. Once the `Draft` issue exists, the
Director's existing polling detects it and dispatches the Architect per the current T-1
gate. No change to Director behavior is required.

### New Speckit Command: `/speckit.draft`

Add `/speckit.draft` to the speckit command suite as the canonical invocation point for
the Drafter, consistent with the existing `/speckit.*` command vocabulary.

```
/speckit.draft  →  Drafter  →  Draft Linear issue  →  Director polls  →  Architect
```

Command definition files:

- `.claude/commands/speckit.draft.md`
- `.codex/prompts/speckit.draft.md`
- `.gemini/commands/speckit.draft.toml`

---

## Agent Specification

### Model

**claude-haiku-4-5** (Claude), **gemini-flash** (Gemini), or equivalent fast model per
platform. The primary task is structured conversational elicitation, not deep analysis;
response latency matters for interactive use. Where the conversation reveals unexpected
technical complexity, the agent escalates to a higher-reasoning model (e.g.,
`claude-sonnet-4-6`) for that session.

### Tool Access

| Tool | Purpose |
|------|---------|
| `AskUserQuestion` | Conduct the intake conversation |
| `mcp__linear-server__save_issue` | Create the Draft issue |
| `mcp__linear-server__list_issues` | Check for duplicate issues |
| `mcp__linear-server__list_teams` | Resolve team assignment |
| `mcp__linear-server__list_issue_statuses` | Verify state names before writing |
| `Write` | Persist `design-prompt.md` during conversation |
| `Read` | Lightweight context only (e.g., reading taxonomy from AGENTS.md) |

No web search, no bash execution, no deep repository exploration.

### Entry Conditions

- A human invokes the Drafter with a raw feature request (any format)
- No existing `Draft` issue for the same request (agent checks for duplicates; surfaces
  existing issue if found)

### Exit Conditions

- CTR design prompt confirmed by stakeholder
- Linear issue created in `Draft` state with design prompt and intake metadata
- Execution log entry written to the issue

### Failure Modes

| Condition | Behavior |
|-----------|----------|
| Stakeholder cannot answer a required question | Capture as open question; continue |
| Request is clearly out of scope | Inform stakeholder; do not create issue |
| Duplicate issue detected | Surface existing issue; offer to update rather than create |
| Stakeholder abandons conversation | Save partial design prompt to local file; do not create issue |
| Objective remains undefined after all passes | Block ticket creation; surface blocker to stakeholder |
| Conversation reveals technical complexity | Escalate to higher-reasoning model for session |

---

## Execution Log Entry Format

Upon completion, the Drafter appends to the Linear issue, consistent with the
system-wide execution log standard:

```
[<YYYY-MM-DDTHH:MM:SSZ>] Feature Draft Agent (Drafter)
Action: Completed intake conversation (<N> turns)
Outcome: Design prompt confirmed by <stakeholder>
Artifacts: design-prompt.md (embedded in issue description)
Classification: <type>
Next step: Assign Architect; Director will dispatch on next poll
```

---

## Platform Definitions Required

Create agent definition files at:

- `.claude/agents/feature-draft.md`
- `.codex/agents/feature-draft.md`
- `.gemini/agents/drafter.md`

Claude Code definition:

```yaml
---
name: feature-draft
description: >
  Conducts a structured CTR intake conversation with a human stakeholder
  and produces a planning-ready design prompt as a Draft Linear issue.
  Invoke via /speckit.draft when a human arrives with a raw feature
  request and no existing Draft issue.
model: claude-haiku-4-5
tools:
  - AskUserQuestion
  - mcp__linear-server__save_issue
  - mcp__linear-server__list_issues
  - mcp__linear-server__list_teams
  - mcp__linear-server__list_issue_statuses
  - Write
  - Read
---
```

---

## Relationship to Existing Agents

| Agent | Relationship |
|-------|-------------|
| **Director** | Does not dispatch Drafter; picks up its output via `Draft` state polling — no behavior change required |
| **Architect** | Receives a CTR-backed design prompt as Phase 1 input; no longer responsible for exploratory stakeholder interviewing |
| **Explorer** | Not invoked by Drafter; design prompt may include "Suggested Research" notes that lead the Architect to invoke Explorer during planning |
| **Coordinator, Engineer, Tech Lead** | Unaffected; downstream of this phase |

---

## Risks and Mitigations

### Overlap with Architect

If the Drafter starts producing implementation detail or solution design, it blurs into
the Architect role.

Mitigation: tool access enforces the boundary. The Drafter cannot read code, run
commands, or access planning artifact templates. Its output format prohibits
implementation content by design.

### Weak Intake Quality Still Passes Through

If the agent accepts vague answers too easily, the Architect inherits the same ambiguity
under a more polished format.

Mitigation: require explicit open question documentation for anything unresolved; block
ticket creation when the objective is undefined; the verification gate gives the
stakeholder a final review opportunity.

### Conflict with the State-Driven Model

The current system invokes agents by Linear state, not direct call. The Drafter acts
before the first issue exists — it is a structural exception.

Mitigation: document it formally as a pre-lifecycle intake exception and capture the
decision in an ADR. The rest of the lifecycle is unchanged.

### Noisy or Low-Value Linear Tickets

If every rough idea becomes a `Draft` issue, Linear fills with speculative requests not
ready for planning.

Mitigation: require a minimum quality bar (defined objective, named requestor, at least
one success criterion) before ticket creation. The verification gate enforces this — a
thin CTR block will not survive stakeholder review.

---

## Alternatives Considered

### Keep Intake Inside the Architect Role

Pros: no new agent type, no new documentation surface.
Cons: mixes exploratory intake with formal planning; weakens single-responsibility
boundaries; keeps `Draft` issue quality inconsistent.

**Rejected.** The Architect's planning capacity is too valuable to consume on
open-ended stakeholder conversations.

### Add a Broader Triage Agent

Pros: handles bugs, chores, and operational requests with one intake role; broader
long-term applicability.
Cons: broader scope than the immediate need; higher design ambiguity; more likely to
overlap with Director and Coordinator responsibilities.

**Deferred.** Start narrow. The Drafter can evolve into a Triage Agent once its
boundaries and failure modes are understood in practice.

### Add a New Linear State (`Idea` or `Drafting`)

Pros: preserves strict state-driven invocation for every role; makes in-flight
conversations visible in Linear.
Cons: adds lifecycle complexity; requires updates across tracking-process.md,
agentic-team.md, Director dispatch logic, and Linear project configuration. The benefit
is achievable more cheaply with local file persistence.

**Rejected.** Use `Draft` as the output target; use local file persistence for
in-flight state.

---

## Impact on AGENTS.md

Add to the agent roster section:

```markdown
### Feature Draft Agent (Drafter)

**Phase:** 0.5 — Feature Drafting
**Model:** claude-haiku-4-5 (escalate to sonnet for complex sessions)
**Invocation:** Human (direct via /speckit.draft); not Director-dispatched
**Responsibility:** Conduct structured CTR intake conversation; classify request;
produce planning-ready design prompt; create Draft Linear issue
**Input:** Raw feature request (any format)
**Output:** Draft Linear issue with CTR design prompt, intake metadata, and
traceability summary; issue in `Draft` state
**Tool access:** AskUserQuestion, Linear (create/read), Write, Read (lightweight only)
```

---

## Open Questions

This proposal resolves **OQ-06**. The following new open questions arise:

| ID | Question |
|----|----------|
| OQ-33 | Who designates the stakeholder when a request has no named owner (e.g., monitoring alert, automated process)? |
| OQ-34 | Should the design prompt be stored only in the Linear issue description, or also committed to `specs/<###>/design-prompt.md`? The issue number is unknown until after creation. |
| OQ-35 | Should the Drafter validate that no `Draft` issue already exists before creating, or is duplication management the Architect's responsibility? |
| OQ-36 | What is the minimum quality bar (defined objective, named requestor, success criterion) that must pass before ticket creation is allowed? Who defines it? |
| OQ-37 | When the conversation transcript cannot be linked (e.g., CLI session), what is the acceptable traceability substitute — a summary paragraph, turn count, or nothing? |
| OQ-38 | At what point should the Drafter's scope expand to cover bug reports, chores, and operational requests, becoming a broader Triage Agent? |

---

## Required Follow-On Changes

1. Create an **ADR** recording the new agent role and the pre-lifecycle intake exception
   to the state-driven dispatch model.
2. Update `docs/agentic-team.md` to add the Feature Draft Agent and clarify that the
   delivery lifecycle begins after draft creation.
3. Update `docs/planning-process.md` Phase 1 to reference the CTR-backed draft as the
   expected intake artifact.
4. Update `docs/tracking-process.md` to describe how `Draft` issues are created, what
   fields are required at creation time, and the role of the Drafter.
5. Create `/speckit.draft` command definitions in all three platform command directories.
6. Create agent definition files in `.claude/agents/`, `.codex/agents/`,
   `.gemini/agents/`.
7. Close **OQ-06** in `docs/open-questions.md`; add OQ-33 through OQ-38.

---

## Acceptance Criteria

- [ ] Proposal ratified (human approval)
- [ ] ADR written and committed to `docs/adr/`
- [ ] Agent added to agent roster in `AGENTS.md`
- [ ] Agent definition files created in all three platform agent directories
- [ ] `/speckit.draft` command created in all three platform command directories
- [ ] `docs/agentic-team.md`, `docs/planning-process.md`, `docs/tracking-process.md`
      updated
- [ ] Director documentation confirms no dispatch change required
- [ ] OQ-06 closed; OQ-33 through OQ-38 added to open questions
