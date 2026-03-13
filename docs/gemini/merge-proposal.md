# Unified Spec-Driven Development (SDD) Thoughtstream

This document proposes a single, cohesive approach to development in this repository, merging the best aspects of the Claude (Operational), Codex (Governance), and Gemini (Strategic) planning models.

---

## 1. Core Philosophy: Why Spec-Driven?

Spec-Driven Development (SDD) is the practice of defining **intent** and **design** in plain text before writing a single line of implementation code. In this repository, we treat the specification as the authoritative source of truth.

### The AI Synergy

AI agents thrive on unambiguous context. A well-defined `spec.md` and `plan.md` reduce "hallucinations" and rework by providing clear boundaries and success criteria. By separating the *What* (Stakeholder Intent) from the *How* (Engineering Design), we enable parallel review and higher-quality execution.

---

## 2. Intake & Classification

Every change request must be classified to determine the required planning depth. This ensures we don't over-engineer trivial fixes while providing enough rigor for complex features.

| Classification | Meaning | Required Planning Depth |
| :--- | :--- | :--- |
| `feature` | New user-facing behavior | Full Spec, Full Plan, Task Breakdown |
| `bug fix` | Correcting unintended behavior | Focused Spec, Focused Plan, Task Breakdown |
| `refactor` | Internal restructuring, no behavior change | Goal & Risk Spec, Migration Plan, Task Breakdown |
| `architecture` | Cross-cutting system changes | Full Spec, **ADR**, Full Plan, Task Breakdown |
| `chore` | Trivial updates (e.g., dependencies) | Minimal Plan, Task Breakdown |

---

## 3. The Lifecycle: From Discovery to Delivery

### Phase 1: Discovery & Clarification

Before committing to a spec, we must resolve "unknown unknowns."

- **Action:** Run `/speckit.clarify` to challenge assumptions.
- **Goal:** Define the problem, target audience, and explicit **non-goals**.
- **Gate:** No critical ambiguity remains.

### Phase 2: Specification (The "What")

Define user-visible behavior and success criteria in technology-agnostic language.

- **Tool:** `/speckit.specify`
- **Artifact:** `spec.md`
- **Gate:** All checklist items in `checklists/requirements.md` pass. No implementation details (frameworks, APIs) are present.

### Phase 3: Technical Planning (The "How")

Convert the approved spec into an executable engineering approach using the **CTR Method** (Context → Task → Refine).

- **Tool:** `/speckit.plan`
- **Sub-Phase 0 (Research):** Explicitly resolve technical unknowns and record findings in `research.md`.
- **Sub-Phase 1 (Design):** Define data models, interface contracts, and the **Test Matrix**.
- **Gate:** `plan.md` is approved by a Tech Lead; "Constitution Check" passes.

### Phase 4: Task Decomposition

Break the plan into independently reviewable, atomic work items.

- **Tool:** `/speckit.tasks`
- **Artifact:** `tasks.md`
- **Rule:** Default to one task per branch or pull request. Each task must have explicit completion criteria and required tests.

### Phase 5: Implementation & Review

Execute tasks exactly as planned.

- **Tool:** `/speckit.implement`
- **Strategy:** Build in thin vertical slices. The MVP (User Story 1) must be demonstrable before P2 work begins.
- **Review:** Every PR must trace back to a specific task, plan, and spec.

---

## 4. Governance & Quality Gates

### The Constitution

The Project Constitution (`.specify/memory/constitution.md`) is the foundational law. It contains non-negotiable engineering principles.

- **Mandate:** A ratified Constitution is a prerequisite for the entire SDD workflow.

### Architecture Decision Records (ADR)

Significant architectural decisions require a formal ADR.

- **Trigger:** Changes to shared patterns, public contracts, platform-wide infrastructure, or long-lived technical direction.

### Testing Expectations

Test intent is defined during **Planning**, not Implementation. Every plan must specify:

- Unit, Integration, Contract, and Acceptance test strategies.
- Regression and migration/compatibility considerations.

---

## 5. Tooling Reference

| Command | Lifecycle Phase | Primary Outcome |
| :--- | :--- | :--- |
| `/speckit.constitution` | Foundation | Ratifies project principles |
| `/speckit.clarify` | Discovery | Resolves critical ambiguity |
| `/speckit.specify` | Specification | Produces stakeholder-aligned `spec.md` |
| `/speckit.plan` | Planning | Produces `plan.md`, `research.md`, and contracts |
| `/speckit.tasks` | Decomposition | Generates atomic `tasks.md` |
| `/speckit.analyze` | Validation | Cross-artifact consistency check |
| `/speckit.implement` | Execution | Step-by-step implementation of tasks |

---

## Next Steps

1. **Ratify the Constitution:** Populate `.specify/memory/constitution.md` with these unified principles.
2. **Unify Templates:** Update the templates in `.specify/templates/` to reflect the merged requirements (e.g., adding the Test Matrix to `plan-template.md`).
3. **Update Agent Prompts:** Align the `speckit.*` command instructions with these quality gates and the 5-tier classification system.
