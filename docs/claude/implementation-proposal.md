# Implementation Process Proposal

## Context

This proposal defines the implementation process for Archive Agentic. It
operates downstream of the planning process (`planning-process.md`) and task
tracking process (`tracking-process.md`). Implementation begins only after
gates 1 through 5 of the planning process are satisfied and the relevant
GitHub Issue is in `status:ready`.

This process governs three non-negotiable requirements:

1. Test-driven development — tests are written before production code.
2. Graphite stacked pull requests — each task ships as a stacked PR.
3. Local test passage gate — all tests must pass locally before a PR is
   submitted for review.

---

## Philosophy

Implementation is the execution of an approved plan, not a fresh design
session. The spec and plan have already answered what to build and how to
build it. The job at implementation time is to build it with quality,
traceability, and verifiability.

TDD enforces this discipline. Writing a failing test first forces the
implementer to understand the acceptance criterion before writing a single
line of production code. The test becomes an executable specification that
either passes or fails — there is no ambiguity about whether the work is
complete.

Graphite stacked PRs enforce the planning principle that each task is one
independently reviewable unit. Stacking allows dependent tasks to proceed in
sequence without waiting for upstream merges, while keeping each layer of
the stack narrow enough for a focused review.

The local test gate protects reviewers. A PR that ships with failing tests
is not ready for review regardless of the quality of the implementation.
Tests are verified locally before the reviewer's time is consumed.

---

## Core Principles

- Write the test before writing the code.
- A failing test is the entry condition for writing production code.
- A passing test suite is the exit condition for submitting a PR.
- One task maps to one branch, one stack frame, and one pull request.
- Stack frames are created in dependency order from the plan.
- Never push a stack frame that does not pass all tests locally.
- Do not expand scope during implementation; return to planning instead.
- Commit after each logical red-green-refactor cycle.
- Commit messages reference the task ID.

---

## Tooling

| Tool | Purpose |
| --- | --- |
| Graphite CLI (`gt`) | Branch, stack, and PR management |
| Language test runner | Executes the local test suite |
| `/speckit.implement` | Structured task execution strategy |
| GitHub Issues | Live execution state and evidence |

---

## TDD Cycle

Each unit of work follows the red-green-refactor cycle.

### Red — write a failing test

1. Read the acceptance criterion for the current task from `tasks.md` and the
   linked GitHub Issue.
2. Write the smallest test that would prove the criterion is satisfied.
3. Run the test suite and confirm the new test fails for the right reason.
4. Do not write production code yet.

The test must fail because the behavior does not exist — not because of a
syntax error, missing import, or test setup problem. Fix infrastructure
failures before proceeding.

### Green — write the minimum production code

5. Write the smallest production code change that makes the failing test pass.
6. Run the full test suite. All tests — including pre-existing ones — must pass.
7. If pre-existing tests break, fix them before continuing.

Do not write code that is not required to make the current failing test pass.
Additional behavior belongs in the next red-green cycle.

### Refactor — improve without changing behavior

8. With a green test suite, improve code clarity, remove duplication, or
   tighten abstractions.
9. Run the full test suite after every refactor step to confirm nothing broke.
10. Commit the completed cycle.

Commit message format:

```
<type>(<scope>): <short description> (T-##)
```

Example:

```
feat(auth): add token expiry validation (T-07)
```

Repeat the red-green-refactor cycle until all acceptance criteria for the
task are covered by passing tests.

---

## Branch and Stack Management

### Branch naming

Branch names follow the task ID and a short slug:

```
t-<##>-<short-slug>
```

Example: `t-07-token-expiry`

### Creating a stack frame

Each task is implemented on its own branch, stacked on top of its upstream
dependency branch using Graphite.

For the first task in a feature (no upstream dependency within the stack):

```
gt branch create t-01-<slug> --base main
```

For a task that depends on an upstream task already in the stack:

```
gt branch create t-02-<slug>
```

Graphite tracks the parent automatically. Do not manually set the base to
`main` when an upstream task branch is the correct parent.

### Keeping the stack current

Before beginning implementation, sync the stack with the remote:

```
gt sync
```

After upstream task PRs are merged, restack to rebase the current frame onto
the updated parent:

```
gt restack
```

Do not implement on a stale base. Restack before writing code if the upstream
frame has changed.

---

## Local Test Gate

Before submitting any PR for review, the full local test suite must pass.
This is a hard gate. There are no exceptions.

Steps:

1. Run the full test suite locally.
2. Confirm all tests pass, including tests from other tasks in the stack.
3. If any test fails, fix it before opening the PR.
4. Record the passing test output as part of the PR validation evidence.

The test command is defined in the project's `Makefile` or equivalent
entrypoint. Use the same command CI uses. Do not run a subset unless the
project explicitly scopes test execution to changed modules with a documented
rationale.

If a test failure is caused by an upstream task that has not yet been merged,
the current task is `blocked`. Document the blocker in the GitHub Issue and
do not open the PR until the upstream work is merged or the test suite is
green.

---

## Workflow

### 1. Pre-implementation checklist

Before writing any code, confirm:

- [ ] The GitHub Issue is in `status:ready`.
- [ ] All upstream dependency tasks are `status:done`.
- [ ] `spec.md`, `plan.md`, and `tasks.md` are reviewed and understood.
- [ ] The acceptance criteria and required tests for this task are clear.
- [ ] The stack is synced (`gt sync`).

### 2. Create the branch

```
gt branch create t-<##>-<slug>
```

Update the GitHub Issue: add the branch name and move to `status:in-progress`.

### 3. Implement using TDD

Repeat the red-green-refactor cycle until all acceptance criteria are covered:

1. Write a failing test for one acceptance criterion.
2. Write the minimum production code to make it pass.
3. Refactor with a green suite.
4. Commit.

Each commit references the task ID. Multiple commits per task are expected
and encouraged — commit at each green cycle, not only at the end.

### 4. Run the full local test suite

Before opening a PR:

```
<project test command>
```

All tests must pass. Capture the output.

If tests fail:
- Fix the failure.
- If the failure is in an upstream task's code, document a blocker and stop.
- Do not open a PR with a failing test suite.

### 5. Open the PR with Graphite

```
gt pr create
```

The PR description must include:

- Link to the GitHub Issue.
- Link to `spec.md` and the relevant acceptance criteria.
- Link to `plan.md`.
- Link to the specific task in `tasks.md`.
- Summary of what was implemented.
- Passing test output or a link to a CI run confirming all tests pass.
- Any deviation from the plan and its justification.

Move the GitHub Issue to `status:in-review`.

### 6. Respond to review

If review finds defects:

1. Move the issue back to `status:in-progress`.
2. Fix the defects on the same branch.
3. Re-run the full test suite locally.
4. Push the fix — Graphite updates the open PR.
5. Move the issue back to `status:in-review`.

Do not open a new PR to address review feedback on an existing task.

### 7. Merge and close

After the PR is approved and CI passes:

```
gt merge
```

Update the GitHub Issue:

- Attach final test evidence.
- Check off all acceptance criteria.
- Move to `status:done`.

---

## Stack Discipline

### When to stack

Stack when one task produces interfaces, types, or data that a downstream
task directly depends on. The downstream task cannot be implemented correctly
without the upstream code being in place.

### When not to stack

Do not stack tasks that are logically independent. Independent tasks should
branch from `main` and ship as separate PRs without a stack relationship.
Stacking independent tasks couples their review unnecessarily.

### Stack size

Keep stacks small. A stack of more than three or four frames becomes
difficult to review and rebase. If a feature requires more frames, look for
opportunities to merge earlier frames before adding more depth.

### Merging order

Stack frames are merged from the bottom up. The base of the stack merges
first. Downstream frames are rebased onto the updated base before they merge.
Graphite manages this automatically with `gt merge` and `gt restack`.

---

## Agent Execution Protocol

Agent-run implementation follows the same TDD and stack discipline as
human-run implementation with these additional requirements.

**Before starting:**

- Report the current state of the GitHub Issue.
- Confirm all upstream dependencies are `status:done`.
- Confirm the local repository is clean and the stack is synced.

**During implementation:**

- Write failing tests and confirm they fail before writing production code.
- Do not assume a test is correct without running it.
- Run the full test suite after every green cycle, not only at the end.
- Add an execution log entry to the issue after each meaningful step.

**Before opening a PR:**

- Run the full test suite and confirm all tests pass.
- Include the test output in the PR description or as a linked artifact.

**On uncertainty:**

- Stop work and document the blocker in the issue.
- Do not resolve product or architectural ambiguity autonomously.
- Do not improvise scope or design. Return to planning.

---

## Gate Rules

| Gate | Condition |
| --- | --- |
| I-1 | GitHub Issue is `status:ready` and all upstream tasks are `status:done` |
| I-2 | Branch is created and issue is updated to `status:in-progress` before code is written |
| I-3 | Each acceptance criterion has a failing test before production code is written |
| I-4 | Full local test suite passes before a PR is opened |
| I-5 | PR description includes spec, plan, and task traceability and passing test evidence |
| I-6 | Full local test suite passes again after review feedback is addressed |

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Agent skips red phase and writes production code first | High | Require failing test output in execution log before any production code commit |
| Stack becomes stale relative to upstream merges | High | Run `gt sync` and `gt restack` at the start of every implementation session |
| Local tests pass but CI fails due to environment differences | Medium | Use the same test command locally as CI; flag environment divergence as a blocker |
| Stack grows too deep and becomes hard to review | Medium | Limit stack depth; merge earlier frames before adding more depth |
| Scope creep discovered during TDD cycle exposes missing requirements | Medium | Stop, document in the issue, return to planning before continuing |
| PR opened with failing tests due to upstream dependency not yet merged | Low | Treat as a blocker; do not open the PR until the suite is green |

---

## Open Questions

- What is the canonical test command for this project? It should be defined
  in the project `Makefile` or equivalent and referenced here.
- Should test coverage thresholds be enforced as part of the local gate, or
  is a passing suite sufficient?
- Should Graphite stack names follow a naming convention tied to the feature
  or spec identifier?
- What is the policy for tasks that genuinely cannot follow TDD — for
  example, infrastructure-only tasks with no testable behavior at the unit
  level? Should acceptance tests substitute for unit tests in those cases?
