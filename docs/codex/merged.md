# Proposal: Feature Draft Agent

## Status

Proposed for review. This document is intended to replace the competing draft
proposals with a single canonical direction. If accepted, it should be
followed by an ADR because it adds a new agent role and changes the intake
boundary of the delivery system.

## Summary

Add a `Feature Draft Agent` as a narrowly scoped pre-lifecycle intake role.
Its responsibility is to engage a human stakeholder in a short structured
conversation, convert a rough request into a CTR-based Draft Design Prompt,
and write that prompt into a Linear issue in `Draft` state.

After the `Draft` issue is created, the existing lifecycle remains unchanged:
the Director detects the issue and dispatches the Architect, who performs the
formal planning work.

## Problem Statement

The current system assumes a sufficiently formed `Draft` issue already exists
before planning begins. That leaves a gap between raw human intent and the
planning-ready input the Architect expects.

This gap is visible across the current documentation:

- `docs/agentic-team.md` assigns the Architect responsibility for confirming
  the objective and producing planning artifacts, but not for running a
  stakeholder intake conversation.
- `docs/planning-process.md` requires intake and classification before
  specification work begins, but it does not define a dedicated intake role.
- `docs/tracking-process.md` treats `Draft` as the first tracked state, which
  means planning quality depends directly on the quality of the initial issue.
- `docs/open-questions.md` raises this explicitly in `OQ-06`, asking whether a
  future intake or triage role should create `Draft` issues from raw requests.

Today, the Architect is implicitly forced to do two different jobs:

- conversational clarification with a stakeholder
- formal planning and artifact production

Those jobs have different goals and different operating modes. The first is
exploratory. The second is spec-driven and gate-bound. Separating them improves
handoff quality and reduces avoidable planning churn.

## Proposed Role

### Name

`Feature Draft Agent`

### Mission

Refine vague human intent into a planning-ready Draft Design Prompt using CTR:

- `Context`: current situation, affected users or systems, urgency, known
  constraints, and why the request exists
- `Task`: desired behavior, outcome, and definition of success
- `Refine`: must-haves, non-goals, constraints, risks, open questions, and
  acceptance signal

### Entry Condition

A human has a feature idea, bug report, refactor request, dependency update,
or architecture/platform request that is not yet ready for formal planning.

### Exit Condition

A Linear issue exists in `Draft` under the `Agentic Harness` project and
`Platform & Infra` team, with a complete Draft Design Prompt and enough intake
metadata for the Architect to begin planning.

### Primary Responsibilities

1. Conduct a short intake conversation with the stakeholder.
2. Classify the request using the repository's existing planning taxonomy.
3. Capture enough context to remove avoidable ambiguity before planning.
4. Produce a Draft Design Prompt in CTR form.
5. Create or update the Linear issue in `Draft`.
6. Stop at handoff.

### Explicitly Out of Scope

- no `spec.md`
- no `plan.md`
- no `tasks.md`
- no technical research that belongs to Explorer
- no architectural decisions
- no scheduling, implementation, or review work

## Why It Is Pre-Lifecycle, Not a New State

The strongest architectural fit is to treat the Feature Draft Agent as a
pre-lifecycle intake role rather than adding a new Linear workflow state.

This proposal intentionally does not add states such as `Drafting` or `Idea`.
Those states add workflow complexity without being necessary to achieve the
core goal.

The recommended model is simpler:

- a human invokes the Feature Draft Agent directly
- the agent performs intake and creates the first tracked artifact
- that artifact is a `Draft` issue
- from that point onward, the current state-driven system operates unchanged

This preserves the repository's existing principle that once an issue exists,
state determines dispatch.

## CTR Design Prompt Format

The Draft Design Prompt should use the following structure:

```md
# Draft Design Prompt: <Title>

**Classification:** feature | bug fix | refactor | dependency/update | architecture/platform
**Requestor:** <name or team>
**Urgency:** urgent | high | medium | low
**Date:** <YYYY-MM-DD>

## Context

<Current problem, trigger, affected users or systems, and important background>

## Task

<Desired new behavior, outcome, and stakeholder-visible success condition>

## Refine

### Must-Haves

- <required outcome>

### Non-Goals

- <explicitly out of scope>

### Constraints

- <performance, compatibility, compliance, or process constraint>

### Risks

- <known risk or ambiguity>

### Open Questions

- <question for Architect or Explorer>

### Acceptance Signal

<How the stakeholder will know this request is satisfied>
```

This is not a spec and not a plan. It is a structured statement of intent that
improves the quality of what enters `Draft`.

## Conversation Protocol

The intake conversation should be bounded and structured in three passes.

### Pass 1: Context

Establish the current situation:

- What problem or opportunity exists today?
- Who is affected?
- Why is this request happening now?

### Pass 2: Task

Define the desired outcome:

- What should a user or system be able to do that it cannot do today?
- What observable result would count as success?
- Are there examples or analogues worth noting?

### Pass 3: Refine

Bound the work:

- What must this not change?
- What constraints exist?
- What should the Architect know before planning starts?

### Guardrails

- no more than nine clarification questions total unless the stakeholder
  explicitly asks for a deeper drafting session
- no implementation design questions
- if an answer is unknown, record it as an open question rather than guessing
- if the request is not a feature, still complete the draft using the standard
  classification taxonomy

## Classification Contract

Every request must be classified using the taxonomy already defined in
`docs/planning-process.md`:

- `feature`
- `bug fix`
- `refactor`
- `dependency/update`
- `architecture/platform`

This keeps intake aligned with downstream planning depth and review
expectations.

## Linear Handoff Contract

The Feature Draft Agent creates or updates a Linear issue with:

- Project: `Agentic Harness`
- Team: `Platform & Infra`
- State: `Draft`

The issue description should include:

- intake summary
- classification
- objective
- Draft Design Prompt
- open questions
- handoff notes
- acceptance signal

Suggested description layout:

```md
## Intake Summary

- Requestor:
- Classification:
- Objective:
- Affected users or systems:
- Urgency:

## Draft Design Prompt

### Context

...

### Task

...

### Refine

#### Must-Haves

- ...

#### Non-Goals

- ...

#### Constraints

- ...

#### Risks

- ...

#### Open Questions

- ...

#### Acceptance Signal

...

## Handoff Notes

- ...
```

The act of creating the `Draft` issue is the handoff signal. No additional
Director behavior is required.

## Role Boundaries

The intended boundaries are:

- `Feature Draft Agent`: conversational intake and Draft Design Prompt
  creation
- `Director`: monitor Linear and dispatch the Architect on `Draft`
- `Architect`: validate the request, move to `Planning`, and produce
  `spec.md`, `plan.md`, `tasks.md`, and required ADRs
- `Explorer`: on-demand technical research invoked by the Architect when needed

The Feature Draft Agent must not cross into planning or implementation.

## Failure Modes and Guardrails

### Stakeholder cannot answer a question

Record the unknown under `Open Questions`. Do not block unless the objective is
so unclear that no meaningful draft can be written.

### Duplicate issue appears to exist

Surface the existing issue and prefer updating it over creating a new duplicate
unless the stakeholder clearly wants a separate request.

### Request is out of scope

Do not create a `Draft` issue. Explain why the request is out of scope and stop.

### Conversation ends before the draft is strong enough

Do not silently convert a weak conversation into a planning-ready issue. Keep
the partial work outside Linear unless the stakeholder explicitly wants it
saved.

### Intake drifts into solution design

Redirect back to intent, scope, and constraints. Technical design belongs to
planning.

## Expected Benefits

- higher quality `Draft` issues
- less rework during planning
- cleaner separation between intake and planning
- more consistent intake artifacts for the Architect
- easier future automation of Slack, web, or CLI entrypoints

## Follow-On Changes if Accepted

1. Create an ADR for the new agent role and the pre-lifecycle intake boundary.
2. Update `docs/agentic-team.md` to add the Feature Draft Agent and clarify
   that it is human-invoked, not Director-dispatched.
3. Update `docs/planning-process.md` to reference the Draft Design Prompt as
   the planning intake artifact.
4. Update `docs/tracking-process.md` to define how `Draft` issues are created
   and what fields are required at creation time.
5. Resolve `OQ-06` in `docs/open-questions.md`.
6. Decide whether to provide a dedicated operator interface such as
   `/speckit.draft`.
7. Add agent definition files for supported runtimes after the architectural
   decision is accepted.

## Open Questions

This proposal resolves the question of whether a dedicated intake role should
exist, but a few implementation details remain open:

- Should `/speckit.draft` become the canonical operator interface, or should
  direct runtime invocation be sufficient?
- Should the Draft Design Prompt live only in Linear, or also be persisted in
  the repository after issue creation?
- What minimum quality bar should the agent enforce before creating a `Draft`
  issue?
- Who is the requestor of record when intake starts from an automated source
  rather than a named human stakeholder?

## Recommendation

Adopt the Feature Draft Agent as a narrow pre-lifecycle intake role.

Do not add new Linear states in the first version. Keep the current lifecycle
beginning at `Draft`. Use `Context`, `Task`, and `Refine` as the canonical
structure for the Draft Design Prompt, and make the Architect the first
Director-dispatched role after the issue is created.
