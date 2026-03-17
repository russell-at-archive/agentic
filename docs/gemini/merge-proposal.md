# Merge Proposal: Feature Draft Agent (Drafter)

**Status**: Draft
**Date**: 2026-03-17
**Merged From**: 
- `docs/gemini/feature-draft-agent-proposal.md`
- `docs/claude/feature-draft-agent-proposal.md`
- `docs/codex/feature-draft-agent-proposal.md`

## 1. Executive Summary

This proposal merges three independent designs for a **Feature Draft Agent** (or **Drafter**). The Drafter acts as the essential bridge between unstructured human ideation and the disciplined, artifact-driven planning performed by the Architect. By conducting a structured, conversational intake and producing a high-fidelity **Draft Design Prompt** using the **CTR (Context, Task, Result)** method, this agent ensures that every feature begins with a clear statement of intent, reducing rework and planning loops.

## 2. Role and Mission

- **Name**: Feature Draft Agent (Drafter)
- **Mission**: Refine vague human intent into a structured, planning-ready Draft Design Prompt.
- **Positioning**: A "Pre-Lifecycle" or "Phase 0.5" role. It operates before the formal state-driven delivery lifecycle begins.
- **Model Recommendation**: A conversational model optimized for interactive dialogue (e.g., `claude-3.5-haiku` or `gemini-1.5-flash`) for low latency, with escalation to higher reasoning models for technical complexity.

## 3. Core Responsibilities

1. **Structured Elicitation**: Conduct a time-bounded, focused conversation (max 9-12 questions) to extract the "Why", "What", and "How" from a stakeholder.
2. **CTR Synthesis**: Transform the raw conversation into a **Draft Design Prompt**:
    - **Context**: Problem statement, target user, current system state, and urgency.
    - **Task**: Desired behavior, specific scope, and stakeholder-defined success.
    - **Result (Refine)**: Success criteria, explicit non-goals, known constraints, and open questions for the Architect.
3. **Classification**: Assign a planning taxonomy (feature, bug fix, refactor, etc.) per `docs/planning-process.md`.
4. **Linear Integration**: Create a Linear issue in the `Draft` state with the CTR prompt as the description.
5. **Clean Handoff**: Stop at the creation of the `Draft` issue. It does *not* produce specs, plans, or tasks.

## 4. The Conversation Protocol (The "Three-Pass" Rule)

To ensure efficiency and prevent "interrogation fatigue," the Drafter follows a three-pass structure:

- **Pass 1: Intake (Context)**: Establish situational grounding (Who, Why, Why now?).
- **Pass 2: Desired Outcome (Task)**: Define the target state and "definition of success."
- **Pass 3: Constraints (Result/Refine)**: Bound the work (Non-goals, must-haves, known risks).

**Guardrails**:
- Maximum of 3 questions per pass.
- Capture unknowns as "Open Questions" rather than blocking the conversation.
- Show the final CTR block to the human for approval before committing to Linear.

## 5. Workflow and Lifecycle Integration

### New Phase: Phase 0.5 (Drafting)

```text
[Human Idea] 
      ↓
Phase 0.5: Drafting (Feature Draft Agent / /speckit.draft)
      ↓
Phase 1: Intake & Classification (Draft issue exists in Linear)
      ↓
Director Dispatches Architect (Existing Workflow)
```

### Linear State Machine Update
While the system remains state-driven starting at `Draft`, an optional **`Drafting`** state can be added to track in-flight ideation. If not added, the agent operates locally/interactively until it persists the result as a `Draft` issue.

## 6. Proposed Tooling: `/speckit.draft`

A new command added to the Speckit suite:
- **Invocation**: `/speckit.draft "I want to add a search bar"`
- **Interaction**: Starts the Drafter's conversational protocol.
- **Output**: 
    1. A `design-prompt.md` block.
    2. A Linear issue link.
    3. (Optional) A `specs/<###>/design-prompt.md` file if the issue number is known.

## 7. Comparative Analysis & Strongest Ideas Retained

| Idea | Source | Why Retained? |
| --- | --- | --- |
| **CTR Method** | All | Provides a consistent "Source of Truth" for the Architect. |
| **Three-Pass Protocol** | Claude | Prevents aimless conversation and ensures all CTR pillars are covered. |
| **Pre-Lifecycle Status** | Codex | Maintains the integrity of the state-driven model while solving the intake gap. |
| **`/speckit.draft` Tooling** | Gemini | Gives humans a clear, discoverable entry point for starting work. |
| **9-Question Limit** | Claude | Ensures the agent stays in "intake" mode and doesn't drift into "planning." |

## 8. Success Criteria for Adoption

- `drafter.md` agent definitions exist for all platforms (Claude, Codex, Gemini).
- `docs/agentic-team.md` and `docs/tracking-process.md` are updated to reflect Phase 0.5.
- `OQ-06` is resolved in `docs/open-questions.md`.
- A human can start with a vague idea and end with a high-fidelity Linear ticket without the Architect's intervention.
