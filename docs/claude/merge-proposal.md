# Merge Proposal: Unified Planning Process Document

## Rationale

Three agents produced three planning process documents with complementary strengths:

- **Gemini** explains *why* SDD works and connects it to AI agent effectiveness
- **Claude** frames the process as an adoptable plan with risks, open questions, and Speckit tooling detail
- **Codex** provides the most operationally complete process: intake classification, the CTR planning method, a formal Review phase, typed testing requirements, and ADR trigger conditions

A unified document should open with Gemini's accessible framing, use Codex's lifecycle structure (which is the most complete at 6 phases), incorporate Claude's Speckit tooling inventory and risk table, and close with Codex's repo-specific next steps.

---

## Proposed Structure

```
1. Philosophy (why SDD — from Gemini)
2. Core Principles (from Codex, expanded)
3. Tooling Reference (from Claude)
4. Lifecycle
   0. Constitution (from Claude — hard prerequisite)
   1. Intake & Classification (from Codex — unique, valuable)
   2. Specification (merged)
   3. Planning — CTR method (from Codex)
   4. Task Decomposition (merged)
   5. Implementation (merged)
   6. Review (from Codex — absent in the others)
5. Gate Rules & Approvals (from Codex)
6. Testing Expectations (from Codex)
7. ADR Trigger Conditions (from Codex)
8. Risks & Mitigations (from Claude)
9. Open Questions (from Claude)
10. Repo-Specific Next Steps (from Codex)
```

---

## Proposed Document

---

# Spec-Driven Development: Planning Process

## Philosophy

Spec-driven development (SDD) separates *what* from *how*. The specification is the authoritative source of truth for a feature. Code must satisfy the spec; the spec is never reverse-engineered from code.

Clarifying intent in plain text is cheaper, faster, and less error-prone than refactoring code. A spec written before implementation enables async stakeholder review, independent testability of each user story, and a traceable record from business intent to commit.

AI agents amplify this benefit. A vague request forces an agent to guess architecture, tools, and UX patterns. A well-formed `spec.md` and `plan.md` allow an agent to generate accurate `tasks.md` documents and execute isolated tasks with high fidelity, reducing hallucinations and increasing delivery speed.

---

## Core Principles

- Write the spec before writing code.
- Use hard gates before implementation starts.
- Separate *what* (stakeholder concern) from *how* (engineering concern).
- Block on critical ambiguity instead of passing it into implementation.
- Plan work as thin, independently shippable vertical slices.
- Write plans for implementers, not for status reporting.
- Default to one task per branch or pull request.
- Require an explicit test matrix in every implementation plan.
- Require an ADR only for cross-cutting architectural decisions.
- The MVP (User Story 1) must be demonstrable before any P2 work begins. This is a hard stop.

---

## Tooling Reference

This repository ships a fully operational Speckit workflow under `.specify/` and `.claude/commands/`.

| Command | Purpose |
|---|---|
| `/speckit.constitution` | Author or amend the project constitution — the authoritative set of non-negotiable principles |
| `/speckit.specify` | Turn a plain-language feature description into a structured, technology-agnostic specification |
| `/speckit.clarify` | Ask up to 5 targeted questions to resolve ambiguities in the spec before planning |
| `/speckit.plan` | Produce a technical implementation plan (research, data model, interface contracts) from the spec |
| `/speckit.tasks` | Break the plan into dependency-ordered, independently testable implementation tasks |
| `/speckit.analyze` | Cross-artifact consistency check across spec, plan, and tasks |
| `/speckit.checklist` | Generate a domain-specific quality checklist for the current feature |
| `/speckit.implement` | Execute tasks in order using a structured, phase-based strategy |
| `/speckit.taskstoissues` | Convert tasks.md into GitHub Issues ordered by dependency |

Artifacts live in `specs/<###-feature-name>/`:

```text
specs/<###-feature-name>/
├── spec.md            # What and why — stakeholder language
├── plan.md            # How — technical decisions and structure
├── research.md        # Phase 0 findings that resolve unknowns
├── data-model.md      # Entities and relationships
├── quickstart.md      # End-to-end validation scenario
├── contracts/         # Public interface definitions
└── tasks.md           # Ordered, labeled implementation checklist
```

---

## Lifecycle

### Phase 0: Constitution

**Prerequisite for all other phases.** The Constitution contains the non-negotiable engineering principles that every plan's quality gate must satisfy. An empty or placeholder constitution means governance is incomplete and planning cannot be fully validated.

Steps:
1. Run `/speckit.constitution` to populate `.specify/memory/constitution.md`.
2. Review with the team — every principle needs an owner who can justify it.
3. Commit the ratified constitution. All future plan reviews reference it.

**Gate**: Constitution is ratified and committed before any feature planning begins. Treat an absent constitution as a blocker.

---

### Phase 1: Intake and Classification

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

| Type | Planning Depth |
|---|---|
| `feature` | full spec, full plan, task breakdown |
| `bug fix` | focused spec, focused plan, task breakdown |
| `refactor` | goal and risk spec, migration-aware plan, task breakdown |
| `dependency/update` | impact and validation plan, task breakdown |
| `architecture/platform` | full spec, ADR if cross-cutting, full plan, task breakdown |

**Gate**: Intake record complete before spec work begins.

---

### Phase 2: Specification

The specification defines intent, scope, and success. It does not define implementation unless implementation detail is required to remove ambiguity in behavior.

Every spec must define:
- user-visible behavior
- in-scope and out-of-scope outcomes
- acceptance scenarios
- measurable, technology-agnostic success criteria
- important edge cases and failure modes

Spec rules:
- Keep specs small enough to describe a shippable vertical slice.
- No implementation detail (framework, language, specific API) may appear in the spec.
- Block on critical ambiguity instead of passing it into planning.
- Use `/speckit.clarify` when ambiguity cannot be resolved from existing context (capped at 5 questions).

The spec is complete only when a reviewer can determine what success looks like without inferring missing product decisions.

**Tooling**: `/speckit.specify`, `/speckit.clarify`

**Gate**: All checklist items in `checklists/requirements.md` pass. No `[NEEDS CLARIFICATION]` markers remain. Approved by tech lead.

---

### Phase 3: Planning

Planning converts the approved spec into an executable engineering approach. Use the **CTR method**:

- **Context**: Inspect the real repository — current implementation shape, constraints, dependencies, and existing patterns.
- **Task**: Define the engineering outcome, interfaces, sequencing, risks, dependencies, and rollout concerns.
- **Refine**: Tighten the plan until it is decision-complete for the implementer.

Every plan must define:
- intended engineering approach
- important interfaces, contracts, or type changes
- affected subsystems
- sequencing and dependencies
- risks and mitigations
- validation steps
- test coverage expectations (see Testing Expectations below)

Two phases of plan execution:
1. **Phase 0 (Research)**: Resolve all technical unknowns from the spec; record decisions in `research.md`.
2. **Phase 1 (Design)**: Produce `data-model.md`, interface contracts in `contracts/`, and `quickstart.md`.

After Phase 1, the *Constitution Check* section in `plan.md` is evaluated. Any violation must be justified in the *Complexity Tracking* table.

Planning is complete only when an implementer can execute the work without making new product or architecture decisions.

**Tooling**: `/speckit.plan`

**Gate**: All `[NEEDS CLARIFICATION]` items resolved. Constitution Check passes or all violations have documented justification. Approved by tech lead.

---

### Phase 4: Task Decomposition

Break the plan into independently reviewable work items. The default unit of execution is one task per branch or pull request.

Each task must define:
- objective
- dependency order
- likely files or subsystems involved
- required tests
- completion criteria
- explicit non-goals

Run `/speckit.analyze` to verify consistency across all artifacts (spec ↔ plan ↔ tasks). If a task cannot be reviewed independently, the plan is too coarse and must be split further.

**Tooling**: `/speckit.tasks`, `/speckit.analyze`, `/speckit.checklist`, `/speckit.taskstoissues` (optional, for sprint tracking)

**Gate**: Every task has an objective, dependency order, file scope, required tests, and completion criteria. `/speckit.analyze` passes.

---

### Phase 5: Implementation

Implementation follows the approved task, not a fresh interpretation of the problem.

Implementation rules:
- Implement only the approved task.
- Do not silently expand scope.
- If new ambiguity appears, return to planning instead of improvising.
- If the work changes a shared architectural pattern or public contract, escalate to an ADR.
- Stop at each phase checkpoint to validate the story independently before advancing.
- The MVP (User Story 1) must be demonstrable before any P2 story begins. This is a hard stop.
- Commit after each logical task group.

**Tooling**: `/speckit.implement`

---

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
- no new architecture decisions were introduced without escalation to an ADR

---

## Gate Rules and Approvals

| Gate | Condition |
|---|---|
| 1 | Intake and classification completed |
| 2 | `spec.md` approved by tech lead |
| 3 | Critical ambiguity resolved |
| 4 | `plan.md` approved by tech lead |
| 5 | `tasks.md` complete and sequenced; `/speckit.analyze` passes |
| 6 | Implementation begins |
| 7 | Review verifies traceability back to spec, plan, and task |

Implementation must not start before gates 1–5 are complete.

---

## Testing Expectations

Test intent is part of planning, not something deferred to implementation. Each plan must explicitly choose the applicable coverage categories:

- unit
- integration
- contract
- acceptance
- regression
- migration or compatibility

The plan must state which categories are required, what they validate, and what evidence will show the work is complete.

---

## ADR Trigger Conditions

Create an ADR when the work changes:

- a cross-cutting architectural pattern
- a shared API, schema, or contract
- a platform-wide infrastructure or workflow rule
- a long-lived technical direction
- a compatibility or migration strategy affecting multiple areas

Routine feature work does not require an ADR.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Spec written with implementation details leaking in | High | Quality checklist enforces technology-agnostic language; `/speckit.clarify` surfaces hidden assumptions early |
| Constitution is empty or incomplete at plan time | Medium | Treat an absent constitution as a blocker; Constitution Check in `/speckit.plan` will surface this |
| Tasks become stale relative to spec changes | Medium | Re-run `/speckit.tasks` after any spec amendment; always run `/speckit.analyze` before implementing |
| Team skips spec phase for "small" features | Medium | Define a size threshold in the Constitution: any user-visible behavior change requires a spec |
| New ambiguity discovered during implementation | Medium | Return to planning; do not improvise. If it changes shared architecture, escalate to ADR |
| Clarification questions delay planning unnecessarily | Low | `/speckit.specify` caps inline clarifications at 3; use informed defaults for non-critical decisions |
| Feature branches diverge before tasks are complete | Low | Each user story phase is independently deployable; merge P1 before starting P2 where possible |

---

## Open Questions

- [ ] What is the size threshold below which a spec is optional (e.g., single-line copy change vs. new screen)? — owner: TBD
- [ ] Who has authority to approve the Constitution and merge constitution amendments? — owner: TBD
- [ ] Should `/speckit.taskstoissues` be run on every feature or only for sprint-planned work? — owner: TBD
- [ ] What is the team's TDD posture? The tasks template marks tests as optional — should they be mandatory for P1 stories? — owner: TBD

---

## Repo-Specific Next Steps

This repository already contains the `.specify/` scaffolding, but `.specify/memory/constitution.md` is still a placeholder. The workflow exists; the governance layer is incomplete.

To make this process fully enforceable:

- Replace the placeholder constitution with real project principles
- Define the size threshold for when a spec is required vs. optional
- Define approval standards and exception handling
- Define test expectations as enforceable quality gates
- Define when ADRs are mandatory
- Run a worked example feature through the full lifecycle (specify → plan → tasks → implement) to validate all artifacts land correctly in `specs/<###>/`
