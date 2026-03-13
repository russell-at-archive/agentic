# Standard Implementation Process

## Purpose

This document defines the unified implementation process for the Archive Agentic workflow. It prioritizes high-quality, verifiable delivery through Test-Driven Development (TDD), high-velocity review via Graphite stacked pull requests, and rigorous local validation.

## Core Principles

1. Test-Driven Development (TDD) is Mandatory: Implementation begins with a failing test that defines expected behavior. Code is written only to satisfy tests.
2. Small, Atomic Units of Work: Tasks are scoped to be thin, independently shippable vertical slices.
3. Stacked Pull Requests: Use [Graphite](https://graphite.dev/) to manage stacks of small, dependent pull requests to enable parallel development without review bloat.
4. Local-First Validation: All tests, linting, and type-checks must pass locally before work is submitted for review.
5. Traceability: Every commit and pull request must trace back to an approved task, plan, and spec.

---

## 1. Pre-Implementation: Intake & Preconditions

Implementation may start ONLY when the following preconditions are met:

- The task exists in approved planning artifacts (`tasks.md`).
- The task is marked `ready` in the tracker (all upstream dependencies are `done`).
- Acceptance criteria and required tests are explicit and understood.
- The local environment is clean and the stack is synced (`gt sync`).

**Workflow Start**:

1. Assign yourself to the GitHub Issue.
2. Update the issue status to `in-progress`.
3. Create the branch: `gt branch create t-<##>-<short-slug>`.

---

## 2. TDD Workflow (Red-Green-Refactor)

Every logical change follows the rigorous red-green-refactor cycle.

### Phase A: Red (Define the Outcome)

1. **Read**: Identify the specific acceptance criterion from the GitHub Issue.
2. **Test**: Write the smallest automated test that proves the criterion is satisfied.
3. **Fail**: Run the test and confirm it fails for the right reason (not a syntax error).
4. **Wait**: Do not write production code yet.

### Phase B: Green (Implement the Solution)

1. **Code**: Write the **minimum** production code necessary to make the failing test pass.
2. **Verify**: Run the targeted test to confirm it passes.
3. **Regression**: Run the full test suite to ensure no existing behavior broke.

### Phase C: Refactor (Clean & Commit)

1. **Clean**: Improve code clarity, remove duplication, and align with project style.
2. **Verify**: Run tests again after every refactor step.
3. **Commit**: Use format `<type>(<scope>): <description> (T-##)`.
   - *Multiple commits per task are encouraged (at each green cycle).*

---

## 3. Stack & Commit Management

- One Task, One Branch: Each planned task maps to one branch and one pull request.
- When to Stack: Stack when a task directly depends on interfaces, types, or data from an upstream task.
- When NOT to Stack: Logically independent tasks should branch from `main`.
- Stack Discipline:
  - Limit stack depth to **3-4 frames** to maintain review quality.
  - Run `gt restack` frequently to keep the branch rebased onto its parent.
  - Merge from the bottom up (base first).

---

## 4. Validation Gate (Local Checks)

Before `gt submit`, the implementer MUST pass the following local gate.

| Check | Requirement |
| :--- | :--- |
| **Targeted Tests** | All tests added/modified for the specific task pass. |
| **Full Suite** | The complete project test suite passes locally. |
| **Linting** | Zero errors from project linting rules (e.g., `eslint`, `ruff`). |
| **Type Checking** | No type errors introduced (e.g., `tsc`, `mypy`). |
| **Build** | The project builds successfully without warnings. |

---

## 5. Submission & Review

1. **Submit**: `gt submit --no-edit --publish`.
2. **PR Requirements**:
   - Title includes Task ID: `[T-##] <Task Title>`.
   - Description links to the GitHub Issue, Spec, and Plan.
   - Attach **Validation Evidence**: Test logs, screenshots, or links to a passing CI run.
3. **Address Review**: Fix defects on the same branch. Re-run the full local gate before re-requesting review.

---

## 6. Agent Execution Protocol

Autonomous agents must adhere to these additional requirements:

- **Session Initialization**: Report current issue state and confirm stack synchronization.
- **Procedural Transparency**: Confirm test failure in the execution log *before* writing production code.
- **Handoff Quality**: Leave **resumable notes** in the issue when blocked or when handing off partially completed work.
- **On Uncertainty**: Stop work and document the blocker. Do not resolve architectural or product ambiguity autonomously; return to planning.

---

## 7. Exceptions Framework

Exceptions should be rare and must be documented explicitly in the PR.

- **Infrastructural**: When environment limitations prevent automated tests.
- **Emergency**: Critical hotfixes where the shortest safe path is required.
- **External**: Repository failures unrelated to the task that block full validation.

*Every exception must state the rule bypassed, the justification, the risk, and the follow-up action required.*
