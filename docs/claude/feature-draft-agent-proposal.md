# Proposal: Feature Draft Agent

## Summary

Add a **Feature Draft Agent** to the delivery lifecycle as a new pre-planning phase
(Phase 0.5). Its sole responsibility is to engage a human stakeholder in a structured
conversation and transform a raw feature idea into a CTR-framed design prompt, then
commit that prompt as a `Draft` Linear issue that signals the Architect to begin work.

This proposal addresses **OQ-06** ("Should a future Triage agent create `Draft` issues
from raw requests?") and closes the gap between informal stakeholder intent and the
formal intake that the Architect currently expects.

---

## Problem Statement

The current lifecycle begins at **Phase 1 — Intake & Classification**, where an Architect
receives a `Draft` Linear issue with an assumed-complete problem statement and
classification. In practice, stakeholders arrive with half-formed ideas, ambiguous goals,
and undiscovered constraints. This forces the Architect to either:

1. Spend planning capacity on clarification that isn't yet planning, or
2. Produce a spec from under-specified input, resulting in rework after `Plan Review`.

There is no agent or process today that translates raw human intent into the structured
input the Architect needs.

---

## Proposed Agent: Feature Draft Agent

### Role

Pre-planning intake agent. Conducts a focused, time-bounded conversation with a human
stakeholder to elicit the full context of a feature request, then writes a structured
CTR design prompt to a new `Draft` Linear issue.

### Responsibility

- Receive an unstructured feature idea (free-form text, Slack thread, verbal summary)
- Ask targeted clarifying questions to fill known gaps
- Apply the CTR framework from the stakeholder's perspective
- Produce a `design-prompt.md` artifact capturing the structured output
- Create or update a `Draft` Linear issue with the design prompt as its description
- Hand off by leaving the issue in `Draft` state for the Architect

### Explicitly Out of Scope

- No implementation decisions
- No technical investigation (that is Explorer's job)
- No spec writing (that is Architect's job)
- No scheduling or task decomposition
- No code reads or repository exploration

---

## CTR in the Feature Draft Context

The Architect uses CTR as a technical planning method (inspect code → define approach →
tighten decisions). For the Feature Draft Agent, CTR is applied from the **product and
user perspective**, not the engineering perspective:

| Phase | Architect (Planning) | Feature Draft Agent (Intake) |
|-------|----------------------|------------------------------|
| **C — Context** | Inspect current codebase, patterns, constraints | What is the current situation, pain point, or opportunity? Who is affected? What exists today? |
| **T — Task** | Define approach, interfaces, sequencing | What new behavior or capability is desired? What does success look like for the user/stakeholder? |
| **R — Requirements / Refine** | Tighten until decision-complete for implementer | What are the must-haves vs nice-to-haves? What are the constraints, risks, and scope boundaries? What is explicitly out of scope? |

The output of this CTR pass is a **design prompt** — not a spec, not a plan — but a
well-structured statement of intent that makes the Architect's spec work faster and more
accurate.

---

## Conversation Protocol

The Feature Draft Agent conducts the intake conversation in three passes:

### Pass 1 — Intake (Context)

Ask no more than three questions to establish situational grounding:

- What is the current state of the world that makes this necessary?
- Who experiences the problem or benefit, and how often?
- What triggers this request now (deadline, incident, customer request, tech debt)?

### Pass 2 — Desired Outcome (Task)

Ask no more than three questions to define the target state:

- What should a user be able to do that they cannot do today?
- How will you know this is working correctly?
- Are there existing examples, analogues, or prior art to reference?

### Pass 3 — Constraints and Scope (Requirements)

Ask no more than three questions to bound the work:

- What must this NOT do, touch, or change?
- What constraints exist (compliance, performance, compatibility, budget)?
- Is there anything the Architect should know before writing the spec?

After three passes, the agent synthesizes the design prompt and presents it to the
stakeholder for confirmation before writing to Linear.

**Conversation guardrails:**
- Maximum nine questions total across all passes
- Never ask for implementation decisions — redirect those to planning
- If the stakeholder is blocked on a question, capture it as an open question rather
  than blocking progress
- If the request is clearly a bug rather than a feature, classify accordingly and still
  complete the design prompt with adjusted framing

---

## Design Prompt Format

The design prompt is a Markdown document stored as the Linear issue description and
optionally as `specs/<###-feature-name>/design-prompt.md` when the issue number is
known.

```markdown
# Design Prompt: <Feature Title>

**Type:** feature | bug fix | refactor | dependency update | architecture/platform
**Urgency:** urgent | high | medium | low
**Requestor:** <name or team>
**Date:** <YYYY-MM-DD>

## Context

<2–4 sentences: current situation, who is affected, what triggers this request>

## Task

<2–4 sentences: desired new behavior or capability, definition of success from the
stakeholder's perspective>

## Requirements

### Must Have
- <requirement>

### Out of Scope
- <explicit exclusion>

### Constraints
- <compliance, performance, compatibility, or other constraint>

### Open Questions
- <anything the Architect should resolve before or during spec>

## Acceptance Signal

<How the stakeholder will know this is done: observable behavior, metric, or event>
```

---

## Lifecycle Integration

### New Phase: Phase 0.5 — Feature Drafting

Insert between the informal request and the current **Phase 1 — Intake & Classification**:

```
[Human Request]
      ↓
Phase 0.5 — Feature Drafting  (Feature Draft Agent)
      ↓
Phase 1   — Intake & Classification  (Architect validates and classifies)
      ↓
Phase 2   — Specification  (Architect)
      ...
```

### Linear State Machine Update

Add one new state: **`Drafting`**

```
Drafting → Draft → Planning → Plan Review → Backlog → Selected → In Progress → Blocked → In Review → Done
```

| State | Owner | Meaning | Entry Condition | Exit Condition |
|-------|-------|---------|-----------------|----------------|
| `Drafting` | Feature Draft Agent | Agent is conducting intake conversation with stakeholder | Human invokes agent with raw request | Design prompt confirmed; issue written to Linear |
| `Draft` | Architect | Issue exists with design prompt; awaiting Architect assignment | Feature Draft Agent completes and transitions | Architect assigned, objective validated |

If the system does not adopt the `Drafting` state, the Feature Draft Agent creates the
issue directly in `Draft` state upon completion — the distinction is whether in-flight
conversations are tracked in Linear.

### Director Dispatch

The Director does **not** dispatch the Feature Draft Agent. This agent is invoked
directly by a human (via CLI, Slack, or web interface). It is the entry point into the
system, not a phase the Director orchestrates.

Once the issue is written in `Draft` state, the Director's existing polling picks it up
and dispatches the Architect per the current T-1 gate.

---

## Agent Specification

### Model

**claude-haiku-4-5** — conversational agent requiring low reasoning; the task is
structured elicitation, not deep analysis. Latency matters for interactive use.

If conversation depth suggests technical complexity warranting Explorer invocation,
escalate to **claude-sonnet-4-6** for that session only.

### Tool Access

| Tool | Purpose |
|------|---------|
| `AskUserQuestion` | Conduct the intake conversation |
| `mcp__linear-server__save_issue` | Create the Draft issue |
| `mcp__linear-server__get_issue_status` | Verify state transitions |
| `mcp__linear-server__list_teams` | Resolve team assignment |
| `Write` | Persist `design-prompt.md` if specs directory exists |

No code reading, no web search, no repository exploration.

### Entry Conditions

- Human provides a raw feature request (any format)
- No existing `Draft` or `Drafting` issue for the same request (agent checks for
  duplicates before creating)

### Exit Conditions

- Design prompt confirmed by stakeholder (explicit approval or no objection after
  summary)
- Linear issue created in `Draft` state with design prompt as description
- Execution log entry written: timestamp, agent role, design prompt summary, issue ID,
  next step (Architect assignment)

### Failure Modes

| Condition | Behavior |
|-----------|----------|
| Stakeholder cannot answer a required question | Capture as open question; do not block |
| Request is clearly out of scope for the system | Inform stakeholder; do not create issue |
| Duplicate issue detected | Surface existing issue; offer to update rather than create |
| Stakeholder abandons conversation | Persist partial design prompt as a `Drafting` issue; do not promote to `Draft` |

---

## Execution Log Entry Format

Upon completing intake, the agent appends to the Linear issue:

```
[<YYYY-MM-DDTHH:MM:SSZ>] Feature Draft Agent
Action: Completed intake conversation (<N> turns)
Outcome: Design prompt confirmed by <stakeholder>
Artifacts: design-prompt.md (embedded in issue description)
Next step: Assign Architect; transition to Planning
```

---

## Platform Definitions Required

Create agent definition files at:

- `.claude/agents/feature-draft.md`
- `.codex/agents/feature-draft.md`
- `.gemini/agents/feature-draft.md`

The Claude Code definition requires:

```yaml
---
name: feature-draft
description: >
  Conducts a structured intake conversation with a human stakeholder
  and produces a CTR-framed design prompt as a Draft Linear issue.
  Invoke when a human arrives with a raw feature request and no
  existing Draft issue.
model: claude-haiku-4-5
tools:
  - AskUserQuestion
  - mcp__linear-server__save_issue
  - mcp__linear-server__get_issue_status
  - mcp__linear-server__list_teams
  - Write
---
```

---

## Relationship to Existing Agents

| Agent | Relationship |
|-------|-------------|
| **Director** | Does not dispatch Feature Draft Agent; picks up its output via `Draft` state polling |
| **Architect** | Receives completed design prompt as input to Phase 2 spec work; benefits from pre-resolved context and open questions |
| **Explorer** | Not invoked by Feature Draft Agent directly; Architect may invoke Explorer if design prompt surfaces technical unknowns |
| **Coordinator, Engineer, Tech Lead** | Unaffected; downstream of the new phase |

---

## Impact on AGENTS.md

Add the following to the agent roster section:

```markdown
### Feature Draft Agent

**Phase:** 0.5 — Feature Drafting
**Model:** claude-haiku-4-5
**Invocation:** Human (direct); not Director-dispatched
**Responsibility:** Conduct structured CTR intake conversation; produce design prompt;
create Draft Linear issue
**Input:** Raw feature request (any format)
**Output:** Draft Linear issue with design-prompt.md content; issue in `Draft` state
**Tool access:** AskUserQuestion, Linear (create/read), Write
```

---

## Open Questions Resolved

This proposal resolves **OQ-06** ("Should a future Triage agent create `Draft` issues
from raw requests?") with a specific design. The following new open questions arise:

| ID | Question |
|----|----------|
| OQ-33 | Is the `Drafting` Linear state worth the configuration cost, or is `Draft` sufficient for in-flight conversations? |
| OQ-34 | Should the Feature Draft Agent validate that a `Draft` issue does not already exist before creating, or is duplication management the Architect's responsibility? |
| OQ-35 | Should the design prompt be stored only in the Linear issue description, or also committed to `specs/<###>/design-prompt.md`? (Issue: spec directory requires a Linear issue number that may not exist until after creation.) |
| OQ-36 | Who is the designated stakeholder when a request has no named owner (e.g., generated by monitoring alert or automated process)? |

---

## Acceptance Criteria for This Proposal

- [ ] Agent added to agent roster in `AGENTS.md`
- [ ] `Drafting` Linear state created (or decision documented to skip it)
- [ ] Agent definition files created in `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`
- [ ] Director documentation updated to note Feature Draft Agent is not Director-dispatched
- [ ] Phase 0.5 added to lifecycle overview in `AGENTS.md`
- [ ] OQ-06 closed; OQ-33 through OQ-36 added to open questions
