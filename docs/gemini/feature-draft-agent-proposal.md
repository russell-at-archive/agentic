# Proposal: Feature Draft Agent (Drafter)

**Status**: Draft
**Date**: 2026-03-17

## Purpose

The **Feature Draft Agent** (Drafter) is designed to bridge the gap between vague human ideation and the structured `Draft` state required by the Architect. It formalizes the "pre-planning" conversation, ensuring that the input to the Architect is high-fidelity and follows the CTR (Context, Task, Result) method.

## Role Definition

- **Name**: Drafter
- **Mission**: Refine vague human intent into a structured Draft Design Prompt.
- **Entry State**: `Idea` (New state) or direct human invocation.
- **Exit State**: `Draft` (Ready for Architect).

## Responsibilities

1. **Iterative Clarification**: Engage the human in a conversation to extract the "Why", "What", and "How" (at a high level).
2. **CTR Generation**: Summarize the conversation into a **Draft Design Prompt** following the CTR pattern:
    - **Context**: Current state, problem statement, target user.
    - **Task**: Specific changes or features to be built.
    - **Result**: Success criteria and key constraints.
3. **Linear Integration**: Create (or update) a Linear issue in the `Draft` state with the CTR prompt as the description.
4. **Handoff**: Signal the Architect that the feature is ready for formal specification and planning.

## Workflow Integration

### Phase -1: Ideation (New Phase)

1. **Invocation**: A human starts a conversation with the Drafter (e.g., via `/speckit.draft`).
2. **Refinement**: The Drafter and human iterate until a clear objective is reached.
3. **Drafting**: The Drafter generates the CTR-based Draft Design Prompt.
4. **Handoff**: The Drafter creates a Linear issue in the `Draft` state.

## Proposed State Changes

| State | Owner | Phase | Meaning |
| --- | --- | --- | --- |
| `Idea` | Drafter | Ideation | Raw idea; Drafter refining with human |
| `Draft` | Architect | Planning | Feature drafted; Architect not yet assigned |

## Proposed Tooling

### `/speckit.draft`

A new command to facilitate the conversation. It will prompt for:
- **Context**: The background and problem.
- **Task**: The desired outcome.
- **Result**: The definition of "done".

## Benefits

- **Reduces Architect Burden**: The Architect starts with a clear, structured prompt rather than a vague request.
- **Improves Alignment**: Human-agent consensus is reached *before* formal planning begins.
- **Standardization**: All new features enter the pipeline with a consistent CTR-based description.

## Next Steps

1. Ratify this proposal.
2. Create agent definitions for Gemini, Claude, and Codex.
3. Update `docs/agentic-team.md` and `docs/tracking-process.md`.
4. Implement `/speckit.draft`.
