# Proposal: Add a Feature Draft Agent

## Status

Proposed for review. This document is a design proposal, not a ratified
architectural decision. Adoption should be followed by an ADR because it adds
a new agent role and changes the intake boundary of the delivery system.

## Summary

Add a `Feature Draft Agent` whose only job is to work with a human requestor,
turn an initial idea into a structured CTR draft, and write that result into a
new Linear issue in `Draft` state. The existing planning flow remains
unchanged after that handoff: the Director detects the `Draft` issue and
dispatches the Architect.

This keeps the current state-driven delivery lifecycle intact while improving
the quality of feature intake. The new agent should operate before the formal
planning lifecycle, not inside it.

## Why Add This Agent

The current system assumes a sufficiently formed `Draft` issue already exists.
That leaves a gap between a human's rough request and the Architect's planning
work:

- `docs/agentic-team.md` assigns the Architect responsibility for confirming
  the objective and starting planning, but not for running an intake dialogue.
- `docs/planning-process.md` requires intake and classification before
  specification work begins, but it does not define an agent dedicated to that
  intake conversation.
- `docs/tracking-process.md` treats `Draft` as the first tracked state, which
  means ideation quality directly affects planning quality.
- `docs/open-questions.md` already flags this gap in `OQ-06`, asking whether a
  future triage agent should handle intake classification and `Draft` issue
  creation from a raw request.

In practice, this means the Architect is forced to absorb two different jobs:

- interactive request shaping with a human
- formal planning artifact production

Those are different modes of work. The first is exploratory and conversational.
The second is disciplined, artifact-driven planning with hard gates. Splitting
them improves the handoff.

## Proposed Role

### Name

`Feature Draft Agent`

### Mission

Engage a human in a focused intake conversation and produce a planning-ready
draft prompt in CTR form:

- `Context`: the business problem, users, constraints, dependencies, and known
  repository or platform context
- `Task`: the requested outcome, expected behavior, scope, success conditions,
  and likely impact areas
- `Refine`: clarified assumptions, explicit open questions, non-goals, risks,
  and handoff notes for planning

### Entry Condition

A human has a feature idea, problem statement, or rough request that is not
yet ready for formal planning artifacts.

### Exit Condition

A new Linear issue exists in `Draft` state inside the `Agentic Harness`
project, with a complete CTR-based draft design prompt and enough metadata for
the Architect to begin planning.

### Primary Responsibilities

1. Interview the human requestor to clarify intent.
2. Classify the request using the existing planning taxonomy:
   `feature`, `bug fix`, `refactor`, `dependency/update`, or
   `architecture/platform`.
3. Identify missing information that would block planning and try to resolve it
   during intake.
4. Produce a CTR draft design prompt that is concise but planning-ready.
5. Create the Linear issue in `Draft` with the CTR prompt and required intake
   metadata.
6. Stop at handoff. It must not create `spec.md`, `plan.md`, or `tasks.md`.

### Non-Responsibilities

- no planning artifact generation
- no repository research beyond lightweight context gathering needed for intake
- no architectural decision-making
- no issue decomposition into implementation tasks
- no implementation or review work

## Recommended System Placement

The `Feature Draft Agent` should be defined as a pre-lifecycle intake role.

That means:

- it is invoked directly by a human or intake surface
- it creates the first tracked Linear artifact
- it does not replace the Director
- it does not change the existing `Draft` to `Planning` transition

This is the best fit with the current documentation because the repository's
main operating model is state-driven once a Linear issue exists. The new agent
solves the problem before that state machine starts.

## Proposed Workflow

### 1. Human intake conversation

The agent runs a short structured dialogue to answer:

- what problem should be solved
- who is affected
- what outcome would count as success
- what is explicitly out of scope
- what systems or documents are likely involved
- what uncertainties or risks are already known

### 2. Request classification

The agent assigns one planning classification:

- `feature`
- `bug fix`
- `refactor`
- `dependency/update`
- `architecture/platform`

This should reuse the classification model already defined in
`docs/planning-process.md`.

### 3. CTR draft construction

The agent writes a planning handoff prompt with three sections:

#### Context

- problem statement
- request owner
- users or systems affected
- urgency or business importance
- relevant constraints
- known repository, platform, or workflow context

#### Task

- desired outcome
- user-visible behavior or operational result
- in-scope changes
- non-goals
- success criteria

#### Refine

- clarified assumptions
- unresolved questions
- notable risks
- suggested research areas for the Architect or Explorer
- rationale for the selected classification

### 4. Linear draft creation

The agent creates a Linear issue in:

- Project: `Agentic Harness`
- Team: `Platform & Infra`
- State: `Draft`

The ticket becomes the official intake artifact that the Director can detect
and route to the Architect.

### 5. Handoff to planning

No additional custom signal is needed if the Director already dispatches all
`Draft` issues to the Architect. The act of creating the `Draft` issue is the
signal.

## Proposed Linear Draft Schema

The `Draft` issue created by the `Feature Draft Agent` should include:

- title: short outcome-oriented feature title
- state: `Draft`
- project: `Agentic Harness`
- team: `Platform & Infra`
- requester: human origin of the request
- classification: one of the planning taxonomy values
- objective: one-paragraph summary
- CTR draft prompt: the main body of the issue
- affected users or systems
- urgency or priority signal
- initial non-goals
- open questions for planning

Recommended description template:

```md
## Intake Summary

- Requester:
- Classification:
- Objective:
- Affected users or systems:
- Urgency:

## CTR Draft

### Context

...

### Task

...

### Refine

...

## Open Questions

- ...

## Handoff Notes

- ...
```

## Agent Boundary Changes

If this proposal is adopted, the role boundaries should become:

- `Feature Draft Agent`: converts raw human intent into a high-quality `Draft`
  issue
- `Director`: watches Linear and dispatches the Architect when a `Draft` issue
  appears
- `Architect`: converts the CTR-backed `Draft` issue into `spec.md`,
  `plan.md`, `tasks.md`, and required ADRs

This lets the Architect start from a stronger intake artifact without making
the Architect responsible for exploratory stakeholder interviewing.

## Expected Benefits

- better `Draft` issue quality
- fewer planning loops caused by missing intent
- cleaner separation between conversational intake and formal planning
- more consistent issue descriptions for the Architect
- easier future automation of intake channels such as Slack, forms, or API
  requests

## Risks and Failure Modes

### Risk: overlap with Architect

If the `Feature Draft Agent` starts producing solution design or implementation
detail, it will blur into the Architect role.

Mitigation:

- keep its output limited to a CTR draft prompt and intake metadata
- explicitly prohibit planning artifact creation

### Risk: weak intake quality still passes through

If the agent accepts vague answers too easily, the Architect will inherit the
same ambiguity under a more polished format.

Mitigation:

- require the agent to surface unresolved critical questions explicitly
- block ticket creation when the objective is undefined

### Risk: conflict with the state-driven model

The current system says agents are invoked by issue state, not direct call.
This new role is different because it acts before the first issue exists.

Mitigation:

- document it as a pre-lifecycle intake exception
- keep the rest of the lifecycle unchanged

### Risk: noisy or low-value Linear tickets

If every rough idea becomes a `Draft` issue, Linear may fill with speculative
requests that are not ready for planning.

Mitigation:

- require a minimum intake quality bar before issue creation
- optionally add a lightweight human confirmation step before the ticket is
  created

## Alternatives Considered

### Alternative 1: Keep intake inside the Architect role

Pros:

- no new agent type
- no new documentation surface

Cons:

- mixes exploratory intake with formal planning
- weakens single-responsibility boundaries
- keeps `Draft` quality inconsistent

### Alternative 2: Add a more general Triage Agent

Pros:

- broader long-term applicability
- could support bugs, chores, and operational requests with one intake role

Cons:

- broader scope than the immediate need
- higher design ambiguity
- more likely to overlap with Director and Coordinator responsibilities

### Alternative 3: Add a new Linear state before `Draft`

Pros:

- preserves strict state-driven invocation for every role

Cons:

- adds lifecycle complexity
- requires more workflow and gate changes across all process docs
- not necessary if the only purpose is issue creation

## Recommendation

Adopt the `Feature Draft Agent` as a narrowly scoped pre-lifecycle intake role.

Keep the current lifecycle beginning at `Draft`. Do not add a new Linear state.
Do not expand the agent into planning. Its output should be a strong CTR-based
design prompt written into a `Draft` issue that the Architect can immediately
use as planning input.

## Required Follow-On Changes if Accepted

1. Create an ADR that records the new agent role and the pre-lifecycle intake
   exception to the state-driven dispatch model.
2. Update `docs/agentic-team.md` to add the `Feature Draft Agent` and clarify
   that the delivery lifecycle begins after draft creation.
3. Update `docs/planning-process.md` Phase 1 to reference the CTR-backed draft
   intake artifact.
4. Update `docs/tracking-process.md` to describe how `Draft` issues are created
   and what fields are required at creation time.
5. Resolve `OQ-06` in `docs/open-questions.md`.
6. Define the exact Linear issue template or automation used for draft
   creation.

## Decision Needed

The main question is not whether intake should improve. The main question is
whether this repository wants to model intake as:

- a narrow `Feature Draft Agent` focused on feature requests only, or
- a broader future `Triage Agent` responsible for all raw request intake

My recommendation is to start with the narrower `Feature Draft Agent` because
it matches the current problem statement and avoids unnecessary overlap with
the existing lifecycle roles.
