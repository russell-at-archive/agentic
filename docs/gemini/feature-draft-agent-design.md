# Design: Feature Draft Agent (Drafter)

**Status**: Draft
**Date**: 2026-03-17

## Overview

The **Drafter** is a specialized agent that manages the **Ideation Phase** (Phase -1). It converts unstructured human input into a structured **Draft Design Prompt** using the CTR (Context, Task, Result) method.

## Architecture

### 1. Agent Definition (`.gemini/agents/drafter.md`)

The Drafter will be defined with a high-reasoning model (e.g., `gemini-3.1-pro`) to handle the conversational nuances of human ideation.

```markdown
---
name: drafter
description: Conversational ideation specialist that produces CTR-based feature drafts.
kind: local
tools: [run_shell_command, read_file, write_file]
model: gemini-3.1-pro
---

# Mission
Your mission is to bridge the gap between human intuition and agentic planning. You transform vague ideas into structured "Draft Design Prompts" using the CTR (Context, Task, Result) method.

## Responsibilities
- Engage the user in a clarifying dialogue to extract the core problem and desired outcome.
- Identify the target user and the current state of the system (Context).
- Define the specific engineering or product task to be performed (Task).
- Establish clear, verifiable success criteria (Result).
- Summarize the conversation into a single, high-fidelity CTR block.
- Create or update a Linear issue in the `Draft` state.
```

### 2. Command Definition (`.gemini/commands/speckit.draft.toml`)

The `/speckit.draft` command will be the entry point for the ideation workflow.

```toml
name = "speckit.draft"
description = "Start a conversational drafting session for a new feature or change."

[[steps]]
agent = "drafter"
instruction = """
1. Greet the user and ask for the high-level idea they have in mind.
2. Follow the CTR method to clarify:
    - Context: Why are we doing this? What is the current state?
    - Task: What exactly should be built?
    - Result: What does success look like?
3. Once the human is satisfied, generate a summary block.
4. Create a Linear issue in the 'Draft' state with this summary.
"""
```

## Workflow: The CTR Method

The Drafter enforces the CTR method to ensure the Architect has a solid foundation for planning.

| Component | Description | Drafter's Goal |
| --- | --- | --- |
| **Context** | The "Why" and "Where". | Establish the problem statement and the baseline system state. |
| **Task** | The "What". | Define the specific scope of work (e.g., "Add a search bar to the dashboard"). |
| **Result** | The "Definition of Done". | Identify measurable outcomes (e.g., "Search returns matching items within 200ms"). |

## Linear Integration

The Drafter will use the `run_shell_command` tool to interact with the Linear CLI or API.

- **Issue Creation**: `linear issue create --title "[Draft] <Feature Name>" --description "<CTR Block>" --state "Draft"`
- **State Transition**: If an `Idea` state is added, the Drafter moves it from `Idea` to `Draft`.

## Validation

- **Human Verification**: The Drafter must show the final CTR block to the human and ask for approval before creating the Linear issue.
- **Traceability**: The Linear issue description must include a link to the original ideation conversation (if possible) or a transcript summary.

## Implementation Plan

1. **Step 1**: Create the `.gemini/agents/drafter.md` file.
2. **Step 2**: Create the `.gemini/commands/speckit.draft.toml` file.
3. **Step 3**: Update the Director's dispatch logic (if applicable) to handle the new `Idea` state.
4. **Step 4**: Test the workflow by drafting a simple feature.
