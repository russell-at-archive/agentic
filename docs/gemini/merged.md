# Proposal: Feature Draft Agent (Drafter)

**Status**: Proposed
**Date**: 2026-03-17

## 1. Executive Summary

This document proposes the addition of the **Feature Draft Agent** (Drafter) to the agentic delivery lifecycle. The Drafter bridges the gap between unstructured human ideation and formal planning by conducting a structured, conversational intake. It produces a high-fidelity **Draft Design Prompt** using the **CTR (Context, Task, Result)** method, ensuring that every feature begins with clear intent, reducing rework, and improving planning quality.

## 2. Role Definition

- **Name**: Feature Draft Agent (Drafter)
- **Mission**: Refine vague human intent into a structured, planning-ready Draft Design Prompt.
- **Positioning**: A "Phase 0.5" role. It operates as the entry point to the system, before formal state-driven orchestration begins.
- **Model Specification**: Optimized for interactive dialogue (e.g., `gemini-1.5-flash` or `claude-3.5-haiku`) to minimize latency during conversational intake.

## 3. Core Responsibilities

- **Structured Elicitation**: Conduct a focused, time-bounded conversation with human stakeholders.
- **CTR Synthesis**: Transform raw ideas into a structured **Draft Design Prompt**:
    - **Context**: Problem statement, target user, current state, and urgency.
    - **Task**: Desired behavior, specific scope, and definition of success.
    - **Result (Refine)**: Success criteria, non-goals, constraints, and open questions for the Architect.
- **Classification**: Assign a planning taxonomy (feature, bug, refactor, etc.) per repository standards.
- **Linear Integration**: Create a Linear issue in the `Draft` state with the CTR prompt as its primary description.

## 4. The Conversation Protocol (The "Three-Pass" Rule)

To prevent "interrogation fatigue" and ensure situational grounding, the Drafter follows a strict three-pass structure:

| Pass | Focus | Target Questions |
| --- | --- | --- |
| **Pass 1: Intake (Context)** | Grounding the "Why" and "Who". | Max 3 |
| **Pass 2: Outcome (Task)** | Defining the "What" and "Success". | Max 3 |
| **Pass 3: Constraints (Result)** | Bounding the "Scope" and "Risks". | Max 3 |

**Guardrails**:
- Total conversation limit of 9-12 questions.
- Unresolved technical details are captured as **Open Questions** for the Architect/Explorer rather than blocking the intake.
- Final CTR output must be confirmed by the human before ticket creation.

## 5. Workflow and Lifecycle Integration

The Drafter introduces a new **Phase 0.5: Drafting** before the existing Phase 1.

```text
[Human Request]
      ↓
Phase 0.5: Drafting (Drafter Agent / /speckit.draft)
      ↓
Phase 1: Intake & Classification (Linear: Draft)
      ↓
[Director Dispatches Architect]
```

### Linear State Machine
- **Entry State**: `Idea` (Optional) or direct invocation.
- **Exit State**: `Draft` (Ready for Architect).

## 6. Proposed Tooling: `/speckit.draft`

A new command added to the Speckit workflow to facilitate this interaction:
- **Invocation**: `/speckit.draft "high-level idea"`
- **Outcome**: A structured CTR block written to a new Linear issue in `Draft` state.

## 7. Implementation Roadmap

1. **Step 1**: Ratify the Drafter role through an ADR.
2. **Step 2**: Create agent definitions in `.gemini/agents/`, `.claude/agents/`, and `.codex/agents/`.
3. **Step 3**: Update `docs/agentic-team.md` and `docs/tracking-process.md` to reflect the new Phase 0.5.
4. **Step 4**: Resolve `OQ-06` in `docs/open-questions.md`.
5. **Step 5**: Deploy the `/speckit.draft` command.

## 8. Success Criteria

- All new features enter the `Planning` state with a pre-populated CTR design prompt.
- The Architect reports reduced time spent on initial clarification loops.
- Stakeholders have a clear, interactive entry point for proposing changes.
