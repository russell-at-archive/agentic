# Plan: Spec-Driven Development Process

## Summary

Establish a clear, repeatable spec-driven development (SDD) workflow for this project that leverages the existing Speckit toolchain. Every feature begins as a specification written for human stakeholders before any implementation decision is made. This ensures alignment, reduces rework, and produces a traceable record from intent to delivery.

## Goals

- [ ] Define the canonical SDD lifecycle for this project (spec → plan → tasks → implement)
- [ ] Establish when and how each Speckit command is used within the lifecycle
- [ ] Clarify the role of the Constitution as the immutable foundation for all decisions
- [ ] Define quality gates that must pass before moving between lifecycle phases
- [ ] Document team roles and ownership at each phase
- [ ] Make the process understandable to developers new to the project

## Non-Goals

- Changing or replacing the existing Speckit toolchain
- Prescribing specific technology choices (those belong in the Constitution or individual plan artifacts)
- Covering post-deployment operations (monitoring, incident response, on-call)
- Defining branching strategies beyond what Speckit already creates

## Context

### Existing Toolchain

This repository already ships a fully operational Speckit workflow under `.specify/` and `.claude/commands/`. The commands and their roles are:

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

### What "Spec-Driven" Means Here

Spec-driven development means the written specification is the authoritative source of truth for a feature. Code must satisfy the spec; the spec is not reverse-engineered from code. This separates *what* (stakeholder concern) from *how* (engineering concern) and enables:

- Async review before expensive implementation begins
- Independent testability of each user story
- Traceable decisions from business intent through to commit

### Affected Areas

The process governs every feature branch in this repository. It does not affect hotfixes or trivial chores that have no user-visible behavior change.

---

## Approach

### Sub-goal 1: Ratify the Constitution

**Why first**: The Constitution contains the non-negotiable principles that every plan's *Constitution Check* section must satisfy. Without a ratified Constitution, quality gates in `/speckit.plan` are undefined.

Steps:
1. Run `/speckit.constitution` to populate `.specify/memory/constitution.md`.
2. Review with the team — every principle needs an owner who can justify it.
3. Commit the ratified constitution. All future plan reviews reference it.

**Assumption**: The project has a set of existing engineering principles that need to be encoded. If not, the `/speckit.constitution` command walks you through creating them from scratch.

---

### Sub-goal 2: Write the Specification

**Entry condition**: A feature idea exists — written in plain language, ideally one sentence of intent.

Steps:
1. Run `/speckit.specify <feature description>`.
2. The command auto-generates a feature branch (`<###-feature-name>`), creates `specs/<###>/spec.md`, and validates the spec against the quality checklist in `checklists/requirements.md`.
3. If `[NEEDS CLARIFICATION]` markers remain (max 3), resolve them interactively in the same session.
4. If deeper ambiguity exists, run `/speckit.clarify` to ask targeted questions before proceeding.

**Quality gate**: All checklist items in `checklists/requirements.md` must pass. No implementation detail (framework, language, API) may appear in the spec. Success criteria must be measurable and technology-agnostic.

---

### Sub-goal 3: Build the Technical Plan

**Entry condition**: `spec.md` passes its quality gate.

Steps:
1. Run `/speckit.plan` on the feature branch.
2. The command executes in two phases:
   - **Phase 0 (Research)**: Resolves all technical unknowns from the spec and records decisions in `research.md`.
   - **Phase 1 (Design)**: Produces `data-model.md`, interface contracts in `contracts/`, and `quickstart.md`.
3. After Phase 1, the *Constitution Check* section in `plan.md` is re-evaluated. Any violation must be justified in the *Complexity Tracking* table.

**Quality gate**: All `[NEEDS CLARIFICATION]` items in `plan.md` resolved. Constitution Check passes or all violations have documented justification. Do not proceed to tasks if gates are unresolved.

---

### Sub-goal 4: Generate Tasks

**Entry condition**: `plan.md` and `spec.md` are both complete and passing gates.

Steps:
1. Run `/speckit.tasks`.
2. Tasks are organized by user story (P1, P2, P3 …). Each phase must be independently testable before the next begins.
3. Run `/speckit.analyze` to verify consistency across all artifacts (spec ↔ plan ↔ tasks).

**Quality gate**: Every task has a checkbox, task ID, optional parallelism marker, story label (where applicable), and an explicit file path. No task should be so vague that an implementer must infer scope.

**Optional**: Run `/speckit.taskstoissues` to push tasks to GitHub Issues for sprint tracking.

---

### Sub-goal 5: Implement in Phases

**Entry condition**: `tasks.md` is validated and consistent.

Steps:
1. Run `/speckit.implement` to begin execution.
2. Phases execute in order: Setup → Foundational → User Story 1 (MVP) → User Story 2 → … → Polish.
3. Stop at each phase checkpoint to validate the story independently before advancing.
4. Commit after each logical task group.

**Quality gate**: The MVP (User Story 1 alone) must be demonstrable before any P2 story begins. This is a hard stop, not advisory.

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Spec written with implementation details leaking in | High | Quality checklist enforces technology-agnostic language; use `/speckit.clarify` to surface hidden assumptions early |
| Constitution is empty or incomplete at plan time | Medium | Treat an empty constitution as a blocker; `/speckit.plan`'s Constitution Check will surface this |
| Tasks become stale relative to spec changes | Medium | Re-run `/speckit.tasks` after any spec amendment; always run `/speckit.analyze` before implementing |
| Team skips spec phase for "small" features | Medium | Define a size threshold in the Constitution: any user-visible behavior change requires a spec |
| Clarification questions delay planning unnecessarily | Low | `/speckit.specify` caps clarifications at 3; use informed defaults for non-critical decisions |
| Feature branches diverge before tasks are complete | Low | Each user story phase is independently deployable; merge P1 before starting P2 where possible |

## Open Questions

- [ ] What is the size threshold below which a spec is optional (e.g., single-line copy change vs. new screen)? — owner: TBD
- [ ] Who has authority to approve the Constitution and merge constitution amendments? — owner: TBD
- [ ] Should `/speckit.taskstoissues` be run on every feature or only for sprint-planned work? — owner: TBD
- [ ] What is the team's TDD posture? Tasks template marks tests as optional — should they be mandatory for P1 stories? — owner: TBD

## Acceptance Criteria

- [ ] The Constitution is ratified and committed to the repository
- [ ] A worked example feature runs through the full Speckit lifecycle (specify → plan → tasks → implement) and produces all artifacts in the correct `specs/<###>/` directory
- [ ] Every developer on the team can describe the five lifecycle phases and the quality gate for each, without referring to this document
- [ ] The `checklists/requirements.md` gate catches at least one instance of implementation detail leaking into a spec during the worked example
- [ ] The MVP checkpoint (end of User Story 1) is demonstrated independently before any P2 work begins
