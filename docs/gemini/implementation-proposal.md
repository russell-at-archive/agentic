# Implementation Process Proposal

## Purpose

This document defines the implementation process for the Archive Agentic workflow, focusing on high-quality, verifiable delivery through Test-Driven Development (TDD) and high-velocity review via Graphite stacked pull requests.

The goal is to move from an approved task in `ready` state to a merged pull request in `done` state while maintaining a high bar for correctness and architectural integrity.

## Core Principles

1. **Test-Driven Development (TDD) is Mandatory**: Implementation begins with a failing test that defines the expected behavior. Code is written only to satisfy tests.
2. **Small, Atomic Units of Work**: Tasks are scoped to be thin, independently shippable vertical slices.
3. **Stacked Pull Requests**: Use [Graphite](https://graphite.dev/) to manage stacks of small, dependent pull requests, enabling faster reviews and parallel development.
4. **Local-First Validation**: All tests must pass locally before work is submitted for review.
5. **Traceability**: Every commit and pull request must trace back to an approved task, plan, and spec.

---

## Implementation Lifecycle

### 1. Pre-Implementation: Task Intake

Before writing any code, the implementer (human or agent) must:

- Confirm the task is in `ready` state (dependencies met).
- Review the `spec.md` and `plan.md` to ensure full understanding of the requirement.
- Identify the exact files and subsystems affected.
- Verify the local environment is clean and up-to-date with the main branch.

**Graphite Setup:**

```bash
# Ensure you are on the main branch and it is up-to-date
git checkout main
git pull
# Start a new stack or branch from the current tip
gt create <task-id>-<short-description>
```

---

### 2. Test-Driven Development (TDD) Workflow

The implementation follows the **Red-Green-Refactor** cycle for every sub-feature or logical change within the task.

#### Phase A: Red (Define the Outcome)

1. Write a new automated test (unit, integration, or contract) that describes the desired behavior.
2. Run the test and confirm it **fails** for the expected reason (e.g., "Function not found" or "Assertion failed").
3. This test serves as the executable acceptance criterion.

#### Phase B: Green (Implement the Solution)

1. Write the **minimum** amount of code necessary to make the failing test pass.
2. Do not implement "just-in-case" features or refactor unrelated code in this phase.
3. Run all tests in the suite to ensure no regressions.

#### Phase C: Refactor (Clean the Code)

1. With the tests passing, clean up the implementation.
2. Improve variable naming, remove duplication, and align with project style guides.
3. Ensure the code is idiomatic and follows the approved architectural plan.
4. Run tests again to verify the refactor didn't break functionality.

---

### 3. Commit and Stack Management

Once a logical unit of the task is complete and verified:

1. **Commit the changes**:

   ```bash
   git add .
   git commit -m "feat: <description> (<task-id>)"
   ```

2. **Handle Dependencies**: If the task depends on another in-progress task, ensure your branch is stacked on top of the dependency's branch using `gt create` or `gt stack`.

---

### 4. Validation Gate (Local Checks)

Before submitting for review, the implementer MUST execute the project's validation suite. A task is not ready for review if it fails any local check.

Required checks:

- [ ] **Unit Tests**: All tests in the relevant subsystem pass.
- [ ] **Integration/End-to-End Tests**: Critical paths related to the task are verified.
- [ ] **Linting**: Code passes all project linting rules (e.g., `npm run lint`, `ruff check`).
- [ ] **Type Checking**: No type errors introduced (e.g., `tsc`, `mypy`).
- [ ] **Build**: The project builds successfully without warnings.

---

### 5. Submission via Graphite

Submit the work for review using Graphite. This creates or updates a pull request that is part of a stack.

```bash
# Submit the current branch to GitHub
gt submit --no-edit --publish
```

**PR Requirements:**

- The PR title must include the Task ID: `[T-##] <Task Title>`.
- The PR description must link to the GitHub Issue, Spec, and Plan.
- Verification evidence (test output, screenshots) must be attached.

---

### 6. Review and Iteration

1. **Collaborative Review**: Address feedback by modifying the code on the same branch.
2. **Restacking**: If a PR lower in the stack is modified, restack your branch:

   ```bash
   gt restack
   ```

3. **Approval**: Once approved and all checks pass, the PR is ready to be merged.

---

## Tooling and Commands Reference

| Tool | Purpose | Primary Commands |
| --- | --- | --- |
| **Git** | Source control | `git commit`, `git add` |
| **Graphite (gt)** | Stacked PR management | `gt create`, `gt submit`, `gt restack`, `gt modify` |
| **Test Runner** | Automated validation | (Project specific: `jest`, `pytest`, `vitest`, etc.) |
| **Linter/Formatter** | Code quality | (Project specific: `eslint`, `prettier`, `black`, etc.) |

## Summary of Gates

| Gate | Condition | Responsibility |
| --- | --- | --- |
| **I-1: Test Failure** | A new test fails before implementation begins | Implementer |
| **I-2: Local Pass** | All tests pass locally before `gt submit` | Implementer |
| **I-3: Traceability** | PR description links to Spec, Plan, and Task | Implementer |
| **I-4: Review Pass** | Tech lead/peer approves the implementation | Reviewer |

---

## Failure Modes and Mitigations

| Risk | Mitigation |
| --- | --- |
| Skipping TDD for "simple" changes | Enforce test coverage checks and review for test-first commits. |
| Large, monolithic PRs | Split tasks earlier in the planning phase; enforce atomic commits. |
| Stale stacks | Regular use of `gt restack` and merging base PRs quickly. |
| Submitting broken code | CI will catch it, but implementers must run local checks to reduce CI noise. |
