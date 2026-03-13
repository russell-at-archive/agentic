# Merge Proposal

## Unified Thoughtstream

Spec-driven development in this repository should be described as a single,
continuous flow:

1. understand the change well enough to state the problem clearly
1. define the intended outcome in stakeholder language
1. resolve critical ambiguity before design begins
1. turn the approved specification into an executable technical plan
1. decompose the plan into small, independently testable tasks
1. implement only within the bounds of the approved task
1. review the result against the original intent, plan, and tests

This keeps the process easy to understand for new contributors, concrete enough
for engineers to execute, and strict enough to prevent scope drift and
unreviewed architectural decisions.

## Proposed Document Shape

The merged document should read as one narrative rather than three competing
styles. A strong structure would be:

1. purpose and philosophy
1. core principles
1. lifecycle
1. artifacts
1. quality gates
1. ADR policy
1. testing expectations
1. implementation and review rules
1. repo-specific adoption steps

This sequence preserves Gemini's accessible framing, Claude's operational
specificity, and Codex's governance controls.

## Recommended Merged Content

### 1. Purpose and Philosophy

Open with Gemini's strongest framing:

- planning in text is cheaper than refactoring code later
- the specification is the source of truth for intent
- the plan explains how the repository will satisfy that intent
- AI agents and human implementers both perform better with explicit context

Then immediately ground that philosophy in repository expectations:

- implementation does not begin until planning gates pass
- plans are written for implementers, not for status reporting
- ambiguity is resolved early, not pushed into coding

This gives the document a clear reason for existing before it becomes
procedural.

### 2. Core Principles

Use Codex's principles as the main backbone, with one addition from Claude:

- use hard gates before implementation starts
- plan work as thin, independently shippable vertical slices
- separate the "what" from the "how"
- write plans that are decision-complete for the implementer
- default to one task per branch or pull request
- require explicit test intent during planning
- treat the Constitution as a binding project baseline for planning decisions
- require ADRs for significant architectural decisions

This section should be short and normative.

### 3. Lifecycle

The lifecycle should use Claude's command-aware flow, but framed with Codex's
stage discipline.

#### Stage 1: Intake and Classification

Start with Codex's intake model:

- classify the request as `feature`, `bug fix`, `refactor`,
  `dependency/update`, or `architecture/platform`
- record the problem statement, desired outcome, affected users or systems,
  urgency, and impact areas
- use the classification to determine planning depth

This is the missing front door in the other documents and prevents a vague
"start with a spec" instruction.

#### Stage 2: Constitution Check

Keep Claude's recommendation that the Constitution must be real before the
workflow can be fully enforced.

- if `.specify/memory/constitution.md` is incomplete, treat that as a process
  gap to close
- all planning decisions must satisfy the Constitution or document an explicit
  exception path

This converts the Constitution from passive documentation into an actual gate.

#### Stage 3: Specification

Use Claude's Speckit alignment and Gemini's human-readable framing:

- run `/speckit.specify` from a plain-language feature description
- use `/speckit.clarify` when ambiguity blocks planning
- keep implementation details out of the spec unless needed to remove behavior
  ambiguity
- require user-visible behavior, scope boundaries, acceptance scenarios,
  success criteria, edge cases, and failure modes

Quality gate:

- the spec must be technology-agnostic where possible
- all critical ambiguity must be resolved
- a reviewer must be able to tell what success looks like without inferring
  missing product decisions

#### Stage 4: Technical Plan

Use Claude's operational detail plus Codex's decision-complete standard:

- run `/speckit.plan` after the spec passes its gate
- capture research, design constraints, affected subsystems, interfaces,
  contracts, sequencing, risks, and rollout concerns
- produce the supporting artifacts that matter for this repository, including
  `research.md`, `data-model.md`, `contracts/`, and `quickstart.md` when
  applicable

Quality gate:

- no unresolved planning placeholders remain
- the Constitution Check passes or documented exceptions are accepted
- an implementer can execute without inventing product or architecture
  decisions during coding

#### Stage 5: Task Decomposition

This section should merge all three cleanly:

- run `/speckit.tasks`
- break the plan into small, dependency-ordered, independently reviewable tasks
- prefer one task per branch or pull request
- ensure each task is independently testable and scoped tightly enough that
  reviewers do not have to infer intent
- run `/speckit.analyze` to verify consistency across artifacts

Quality gate:

- every task has a clear objective
- dependencies are explicit
- required tests are named
- completion criteria and non-goals are defined

#### Stage 6: Implementation

This should combine Claude's phase discipline with Codex's scope control:

- implement only the approved task
- do not silently expand scope
- stop and return to planning if new ambiguity appears
- validate the MVP or highest-priority user story before moving to lower
  priority work
- commit in logical increments that preserve traceability to the task list

This keeps implementation subordinate to the artifacts instead of letting the
artifacts become ceremonial.

#### Stage 7: Review and Verification

Use Codex's review rules as the final enforcement layer:

- every pull request traces back to the spec, plan, and specific task
- review checks acceptance criteria, planned tests, task scope, and artifact
  consistency
- no architectural change is accepted without ADR coverage when required

This should be stated as part of the process, not as a reviewer preference.

## Artifact Model

The merged document should preserve Claude's more complete artifact inventory
while keeping Codex's simpler required-artifact framing.

Required core artifacts:

- `spec.md`
- `plan.md`
- `tasks.md`

Conditional supporting artifacts:

- `research.md`
- `data-model.md`
- `quickstart.md`
- `contracts/`
- checklist outputs where useful

This keeps the process compact while still acknowledging how Speckit actually
structures work.

## Quality Gates

The final document should define gates explicitly, since that is where Codex
and Claude are strongest and Gemini is weakest.

Recommended hard gates:

1. intake and classification completed
1. Constitution is present and usable, or the exception is documented
1. `spec.md` passes review and ambiguity is resolved
1. `plan.md` passes review and Constitution Check
1. `tasks.md` is complete, sequenced, and internally consistent
1. implementation begins
1. review verifies traceability and planned validation

This should be written as mandatory process language, not suggestion.

## ADR Policy

The merged document should adopt Codex's trigger-style clarity but correct the
policy to match repository rules.

Recommended wording:

- create an ADR for any significant architectural decision
- ADRs are always required for cross-cutting patterns, shared contracts,
  platform-wide rules, long-lived technical direction, and migration strategy
  changes affecting multiple areas
- if significance is uncertain, treat the change as ADR-worthy until clarified

This avoids the current inconsistency with `~/.agents/AGENTS.md`.

## Testing Expectations

Keep Codex's strongest contribution here and connect it to Claude's phase
gates.

Each plan should explicitly state which of these apply:

- unit
- integration
- contract
- acceptance
- regression
- migration or compatibility

The document should also state:

- test intent is planned, not deferred
- each task names required validation
- MVP validation is a hard checkpoint before lower-priority scope proceeds

This creates a useful bridge between planning artifacts and actual engineering
evidence.

## Tone and Style Guidance

The merged document should avoid sounding like three stitched-together sources.
To achieve that:

- use Gemini's clean explanatory tone in the introduction
- use Codex's direct normative language for rules and gates
- use Claude's concrete Speckit references inside the lifecycle stages
- avoid repeating the same idea in both philosophy and workflow sections
- keep command names and artifact names concrete, but keep the top-level
  message human-readable

The result should feel like one repository standard, not a committee summary.

## Recommended Outcome

The best merged version is not a simple average of the three documents. It
should be:

- as approachable as Gemini
- as executable as Claude
- as enforceable as Codex

In practice, that means using Claude's lifecycle as the operational core,
Codex's approval, testing, and review rules as the control layer, and Gemini's
explanation as the opening frame.

## Suggested Final Position

If this repository adopts a single canonical planning document, it should
present spec-driven development as a governed delivery system:

- clarify intent first
- formalize behavior in `spec.md`
- design execution in `plan.md`
- break work into reviewable tasks in `tasks.md`
- implement only after gates pass
- prove correctness with planned tests
- document significant architecture decisions with ADRs
- review every change against the original artifacts

That thoughtstream is cohesive, operationally realistic, and consistent with
the repository's existing workflow and governance requirements.
