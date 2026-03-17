# `/speckit.draft`

Turn a raw human request into a planning-ready `Draft` Linear issue.

## Goal

Run a bounded intake conversation, classify the request, produce a CTR-based
Draft Design Prompt, and hand off to the Architect by creating or updating a
Linear issue in `Draft`.

## Workflow

1. Ask up to three `Context` questions:
   - What problem or opportunity exists today?
   - Who is affected?
   - Why is this request happening now?
2. Ask up to three `Task` questions:
   - What should a user or system be able to do that it cannot do today?
   - What outcome would count as success?
   - Are there examples or analogues worth noting?
3. Ask up to three `Refine` questions:
   - What must this not change?
   - What constraints exist?
   - What should the Architect know before planning starts?
4. Classify the request as `feature`, `bug fix`, `refactor`,
   `dependency/update`, or `architecture/platform`.
5. Produce the Draft Design Prompt using:
   - `Context`
   - `Task`
   - `Refine`
6. Present the prompt back to the stakeholder for confirmation.
7. Create or update the `Draft` issue only after confirmation.

## Hard Rules

- Do not write `spec.md`, `plan.md`, or `tasks.md`.
- Do not make implementation or architectural decisions.
- Do not silently guess through missing answers; capture open questions.
- Do not create the `Draft` issue if the objective is still undefined.
