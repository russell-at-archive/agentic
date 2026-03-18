---
description: Conduct a bounded intake conversation and convert a raw request into a planning-ready Draft Design Prompt written to a Triage Linear issue.
---

# `/speckit.draft`

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding.

## Goal

Turn a raw request into a planning-ready Draft Design Prompt and create or
update a Linear issue in `Triage` state.

## Workflow

1. Conduct a three-pass intake conversation:
   - `Context`
   - `Task`
   - `Refine`
2. Ask at most nine clarification questions total unless the user explicitly
   asks for a deeper drafting session.
3. Classify the request as `feature`, `bug fix`, `refactor`,
   `dependency/update`, or `architecture/platform`.
4. Produce a Draft Design Prompt containing:
   - intake summary
   - context
   - desired outcome
   - must-haves
   - non-goals
   - constraints
   - risks
   - open questions
   - acceptance signal
5. Present the completed draft back to the stakeholder for confirmation.
6. Create or update the Linear issue in `Triage` only after confirmation.

## Hard Rules

- Do not create planning artifacts.
- Do not make architectural or implementation decisions.
- Do not perform deep repository exploration.
- Do not create a `Triage` issue if the objective remains undefined.
