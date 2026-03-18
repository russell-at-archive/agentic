# Spec-Driven Development Planning Process

## Philosophy

Spec-driven development separates *what* from *how*. The specification is the
authoritative source of truth for a feature. Code must satisfy the spec; the
spec is never reverse-engineered from code.

Clarifying intent in plain text is cheaper, faster, and less error-prone than
refactoring code later. A spec written before implementation enables async
stakeholder review, independent testability of each user story, and a
traceable record from business intent to commit.

AI agents amplify this benefit. A vague request forces an agent to guess
architecture, tools, and user experience patterns. A well-formed `spec.md` and
`plan.md` allow an agent to generate accurate `tasks.md` documents and execute
isolated tasks with higher fidelity, reducing hallucinations and increasing
delivery speed.

## Core Principles

- Write the spec before writing code.
- Use hard gates before implementation starts.
- Separate *what* from *how*.
- Block on critical ambiguity instead of passing it into implementation.
- Plan work as thin, independently shippable vertical slices.
- Write plans for implementers, not for status reporting.
- Default to one task per branch or pull request.
- Require an explicit test matrix in every implementation plan.
- Require ADRs for significant architectural decisions.
- The MVP must be demonstrable before lower-priority work begins.

## Tooling Reference

This repository ships a Speckit workflow under the following directories.
`.specify/`
`.claude/commands/`
`.codex/prompts/`
`.gemini/commands/`

| Command | Purpose |
| --- | --- |
| `/speckit.draft` | Turn a raw request into a CTR-based Draft Design Prompt and create a `Triage` Linear issue |
| `/speckit.constitution` | Author or amend the project constitution |
| `/speckit.specify` | Turn a plain-language feature description into a structured, technology-agnostic specification |
| `/speckit.clarify` | Ask targeted questions to resolve ambiguities in the spec before planning |
| `/speckit.plan` | Produce a technical implementation plan from the spec |
| `/speckit.tasks` | Break the plan into dependency-ordered, independently testable implementation tasks |
| `/speckit.analyze` | Check consistency across spec, plan, and tasks |
| `/speckit.checklist` | Generate a quality checklist for the current feature |
| `/speckit.implement` | Execute tasks in order using a structured strategy |
| `/speckit.taskstoissues` | Convert `tasks.md` into GitHub issues ordered by dependency |

Artifacts live in `specs/<###-feature-name>/`:

```text
specs/<###-feature-name>/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

## Lifecycle

### Phase 0: Constitution

The Constitution contains the non-negotiable engineering principles that every
plan's quality gate must satisfy. An empty or placeholder Constitution means
governance is incomplete and planning cannot be fully validated.

Steps:

1. Run `/speckit.constitution` to populate
   `.specify/memory/constitution.md`.
1. Review with the team.
1. Commit the ratified Constitution.

Gate:

- The Constitution is ratified and committed before feature planning begins.
- Treat an absent or placeholder Constitution as a blocker.

### Phase 0.5: Feature Drafting

Before formal planning starts, a human may invoke the Feature Draft Agent to
turn a raw request into a planning-ready intake artifact.

The output of this phase is a `Triage` Linear issue containing a Draft Design
Prompt organized as:

- `Context`
- `Task`
- `Refine`

This phase is intentionally pre-lifecycle. It does not add a new Linear state.
The Director begins state-driven dispatch only after the `Triage` issue exists.

Tooling:

- `/speckit.draft`

Gate:

- A planning-ready `Triage` issue exists before Phase 1 starts.

### Phase 1: Intake and Classification

Every request starts with a short intake record. When available, that record is
the Draft Design Prompt created during Phase 0.5. Classify the change as one
of:

- `feature`
- `bug fix`
- `refactor`
- `dependency/update`
- `architecture/platform`

Capture:

- problem statement
- desired outcome
- request owner
- affected users or systems
- urgency
- likely impact areas in the repository
- must-haves, non-goals, constraints, risks, and open questions from the
  Draft Design Prompt when available

Classification determines planning depth:

| Type | Planning Depth |
| --- | --- |
| `feature` | Full spec, full plan, task breakdown |
| `bug fix` | Focused spec, focused plan, task breakdown |
| `refactor` | Goal and risk spec, migration-aware plan, task breakdown |
| `dependency/update` | Impact and validation plan, task breakdown |
| `architecture/platform` | Full spec, ADR, full plan, task breakdown |

Gate:

- Intake and classification are complete before specification work begins.

### Phase 2: Specification

The specification defines intent, scope, and success. It does not define the
implementation unless implementation detail is required to remove ambiguity in
behavior.

Every spec must define:

- user-visible behavior
- in-scope and out-of-scope outcomes
- acceptance scenarios
- measurable success criteria
- important edge cases and failure modes

Spec rules:

- Keep specs small enough to describe a shippable vertical slice.
- Do not include implementation detail unless needed to clarify behavior.
- Block on critical ambiguity instead of passing it into planning.
- Use `/speckit.clarify` when ambiguity cannot be resolved from existing
  context.

The spec is complete only when a reviewer can determine what success looks
like without inferring missing product decisions.

Tooling:

- `/speckit.specify`
- `/speckit.clarify`

Gate:

- The specification passes the quality checklist.
- No critical ambiguity remains.
- No unresolved clarification markers remain.
- The spec is approved by a human reviewer.

### Phase 3: Planning

Planning converts the approved spec into an executable engineering approach.
Use the CTR method:

- `Context`: inspect the current implementation, constraints, dependencies, and
  patterns in the repository
- `Task`: define the engineering outcome, interfaces, sequencing, risks,
  dependencies, and rollout concerns
- `Refine`: tighten the plan until it is decision-complete for the implementer

Every plan must define:

- intended engineering approach
- important interfaces, contracts, or type changes
- affected subsystems
- sequencing and dependencies
- risks and mitigations
- validation steps
- test coverage expectations

Plan execution has two phases:

1. Research: resolve technical unknowns and record findings in `research.md`.
1. Design: produce `data-model.md`, interface contracts in `contracts/`, and
   `quickstart.md` when applicable.

After design, the Constitution Check in `plan.md` is evaluated. Any violation
must be justified and explicitly accepted.

Planning is complete only when an implementer can execute the work without
making new product or architecture decisions.

Tooling:

- `/speckit.plan`

Gate:

- All planning ambiguities are resolved.
- The Constitution Check passes or approved exceptions are documented.
- The plan is approved by a human reviewer.

### Phase 4: Task Decomposition

Break the plan into independently reviewable work items. The default unit of
execution is one task per branch or pull request.

Each task must define:

- objective
- dependency order
- likely files or subsystems involved
- required tests
- completion criteria
- explicit non-goals

Run `/speckit.analyze` to verify consistency across all artifacts. If a task
cannot be reviewed independently, the plan is too coarse and must be split.

Tooling:

- `/speckit.tasks`
- `/speckit.analyze`
- `/speckit.checklist`
- `/speckit.taskstoissues` when issue tracking is needed

Gate:

- Every task has clear scope, dependencies, required tests, and completion
  criteria.
- Tasks are sequenced and independently reviewable.
- Cross-artifact analysis passes.

### Phase 5: Implementation

Implementation follows the approved task, not a fresh interpretation of the
problem.

Implementation rules:

- Implement only the approved task.
- Do not silently expand scope.
- If new ambiguity appears, return to planning instead of improvising.
- If the work introduces a significant architectural decision, create or update
  an ADR before proceeding.
- Validate the highest-priority user story before lower-priority work begins.
- Commit after each logical task group.

Tooling:

- `/speckit.implement`

### Phase 6: Review

Review validates the implementation against the planning artifacts.

Every pull request must trace back to:

- the approved `spec.md`
- the approved `plan.md`
- the specific task being implemented

Review must verify:

- the change satisfies the acceptance criteria in the spec
- the planned tests were added or updated
- the implementation stayed within task scope
- no new architectural decision was introduced without ADR coverage

## Gate Rules and Approvals

| Gate | Condition |
| --- | --- |
| 1 | Intake and classification completed |
| 2 | `spec.md` approved by human reviewer |
| 3 | Critical ambiguity resolved |
| 4 | `plan.md` approved by human reviewer |
| 5 | `tasks.md` complete and sequenced, and `/speckit.analyze` passes |
| 6 | Implementation begins |
| 7 | Review verifies traceability back to spec, plan, and task |

Implementation must not start before gates 1 through 5 are complete.

## Testing Expectations

Test intent is part of planning, not something deferred to implementation.
Each plan must explicitly choose the applicable coverage categories:

- unit
- integration
- contract
- acceptance
- regression
- migration or compatibility

The plan must state which categories are required, what they validate, and what
evidence will show the work is complete.

## ADR Trigger Conditions

Create an ADR when the work changes:

- a cross-cutting architectural pattern
- a shared API, schema, or contract
- a platform-wide infrastructure or workflow rule
- a long-lived technical direction
- a compatibility or migration strategy affecting multiple areas
- any other significant architectural decision

Routine feature work does not require an ADR unless it crosses one of these
thresholds.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Spec written with implementation details leaking in | High | Enforce the spec quality checklist and use `/speckit.clarify` to surface assumptions early |
| Constitution is empty or incomplete at plan time | Medium | Treat an absent Constitution as a blocker and require Constitution Check during planning |
| Tasks become stale relative to spec changes | Medium | Re-run `/speckit.tasks` after spec changes and run `/speckit.analyze` before implementing |
| Team skips the spec phase for small changes | Medium | Define a size threshold in the Constitution for when a spec is optional |
| New ambiguity appears during implementation | Medium | Return to planning and escalate to ADR if the issue is architectural |
| Clarification work delays planning unnecessarily | Low | Use informed defaults for non-critical decisions and reserve clarification for true blockers |
| Feature branches diverge before tasks are complete | Low | Keep work as thin, independently reviewable slices and merge validated MVP work early |

## Open Questions

See [docs/open-questions.md](open-questions.md) for the consolidated
and deduplicated question backlog. Questions originating here are tracked as OQ-01,
OQ-10, OQ-16, OQ-17.

## Repo-Specific Next Steps

This repository already contains `.specify/` scaffolding, but
`.specify/memory/constitution.md` is still a placeholder. The workflow exists,
but the governance layer is incomplete.

To make this process fully enforceable:

- replace the placeholder Constitution with real project principles
- define the threshold for when a spec is required versus optional
- define approval standards and exception handling
- define test expectations as enforceable quality gates
- define ADR expectations in repository policy and templates
- run a worked example feature through the full lifecycle to verify the
  artifacts land correctly in `specs/<###>/`
