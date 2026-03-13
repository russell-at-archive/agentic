# Planning Process

## Purpose

This repository follows spec-driven development. Planning happens before
implementation, and planning artifacts are written for implementing engineers
and coding agents.

Implementation does not begin until the required planning gates have passed.

## Core Principles

- Use hard gates before implementation starts.
- Plan work as thin, independently shippable vertical slices by default.
- Resolve critical ambiguity before planning continues.
- Write plans for implementers, not for status reporting.
- Default to one task per branch or pull request.
- Require an explicit test matrix in every implementation plan.
- Require an ADR only for cross-cutting architectural decisions.

## Workflow

### 1. Intake and Classification

Every request starts with a short intake record. Classify the change as one of:

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

The classification determines planning depth:

- `feature`: full spec, full plan, task breakdown
- `bug fix`: focused spec, focused plan, task breakdown
- `refactor`: goal and risk spec, migration-aware plan, task breakdown
- `dependency/update`: impact and validation plan, task breakdown
- `architecture/platform`: full spec, ADR if cross-cutting, full plan, task
  breakdown

### 2. Specification

The specification defines intent, scope, and success. It does not define the
implementation unless implementation detail is required to remove ambiguity in
behavior.

Every spec should define:

- user-visible behavior
- in-scope and out-of-scope outcomes
- acceptance scenarios
- measurable success criteria
- important edge cases and failure modes

Spec rules:

- Keep specs small enough to describe a shippable vertical slice.
- Block on critical ambiguity instead of passing it into implementation.
- Use explicit open questions only when the ambiguity cannot be resolved from
  existing context.
- Prefer testable requirements over broad intent statements.

The spec is complete only when a reviewer can tell what success looks like
without inferring missing product decisions.

### 3. Planning

Planning converts the approved spec into an executable engineering approach.
Use the CTR method for every plan:

- `Context`: inspect the real repository, the current implementation shape,
  constraints, dependencies, and existing patterns.
- `Task`: define the engineering outcome, interfaces, sequencing, risks,
  dependencies, and rollout concerns.
- `Refine`: tighten the plan until it is decision complete for the implementer.

Every plan should define:

- intended engineering approach
- important interfaces, contracts, or type changes
- affected subsystems
- sequencing and dependencies
- risks and mitigations
- validation steps
- test coverage expectations

Planning is complete only when an implementer can execute the work without
making new product or architecture decisions.

### 4. Task Decomposition

Break the plan into independently reviewable work items. The default unit of
execution is one task per branch or pull request.

Each task must define:

- objective
- dependency order
- likely files or subsystems involved
- required tests
- completion criteria
- explicit non-goals

If a task cannot be reviewed independently, the plan is too coarse and should
be split again.

### 5. Implementation

Implementation follows the approved task, not a fresh interpretation of the
problem.

Implementation rules:

- Implement only the approved task.
- Do not silently expand scope.
- If new ambiguity appears, return to planning instead of improvising.
- If the work changes a shared architectural pattern or public contract,
  escalate to an ADR decision when required.

### 6. Review

Review validates the implementation against the planning artifacts.

Every pull request should trace back to:

- the approved spec
- the approved plan
- the specific task being implemented

Review should verify:

- the change satisfies the acceptance criteria
- the planned tests were added or updated
- the implementation stayed within task scope
- no new architecture decisions were introduced without escalation

## Required Artifacts

### `spec.md`

Defines user-facing intent, scope, scenarios, requirements, and success
criteria.

### `plan.md`

Defines the engineering approach, interfaces, constraints, sequencing, risks,
and test strategy.

### `tasks.md`

Defines ordered execution tasks. Tasks should normally map to one branch or
pull request each.

### ADR

Required only when the work changes shared architecture, long-lived technical
direction, platform rules, or public contracts used across multiple areas.

## Approval and Gate Rules

The required stage gates are:

1. intake and classification completed
2. `spec.md` approved by the tech lead
3. critical ambiguity resolved
4. `plan.md` approved by the tech lead
5. `tasks.md` complete and sequenced
6. implementation begins
7. review verifies traceability back to spec, plan, and task

Implementation must not start before the plan and task stages are complete.

## Testing Expectations

Test intent is part of planning, not something deferred to implementation.

Each plan must explicitly choose the applicable coverage:

- unit
- integration
- contract
- acceptance
- regression
- migration or compatibility

The plan should state which categories are required, what they validate, and
what evidence will show the work is complete.

## ADR Trigger Conditions

Create an ADR when the work changes:

- a cross-cutting architectural pattern
- a shared API, schema, or contract
- a platform-wide infrastructure or workflow rule
- a long-lived technical direction
- a compatibility or migration strategy affecting multiple areas

Routine feature work does not need an ADR.

## Repo-Specific Next Steps

This repository already contains the `.specify` scaffolding for a
spec-driven workflow, but `.specify/memory/constitution.md` is still a
placeholder.

To make this process enforceable:

- replace the placeholder constitution with real project rules
- define required artifacts by change type
- define approval standards and exception handling
- define test expectations as enforceable quality gates
- define when ADRs are mandatory

Until the constitution is real, the workflow exists but the governance layer is
still incomplete.
