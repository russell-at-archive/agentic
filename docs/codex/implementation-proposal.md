# Implementation Process Proposal

## Purpose

This document proposes the implementation process for Archive Agentic after
planning is complete and an approved task is ready to execute.

The intent is to create a delivery loop that is:

- disciplined enough to preserve engineering quality
- small-batch enough to keep review fast and reliable
- explicit enough for both human developers and implementation agents
- strict enough to prevent unverified code from reaching review

This proposal assumes the planning and task tracking processes already define
scope, sequencing, ownership, and execution state. This document defines how
approved tasks move from `ready` to review-ready code.

## Summary

The proposed implementation process uses the following operating model:

1. Implement only approved tasks from planning artifacts and issue tracking.
1. Use test-driven development as the default implementation method.
1. Keep changes small and reviewable by using Graphite stacked pull requests.
1. Require a passing local validation run before any pull request is opened or
   updated for review.
1. Return to planning when scope, acceptance criteria, or architecture become
   unclear.

## Principles

- Approved plans drive implementation.
- Red tests come before production code when behavior changes.
- Every task should produce the smallest useful change that can be reviewed
  independently.
- Stacks should express dependency order, not bundle unrelated work.
- A pull request is not review-ready until required local tests pass.
- Scope change during implementation is a planning problem, not an execution
  decision.
- Significant architectural changes require an ADR before implementation
  continues.

## Preconditions

Implementation may start only when all of the following are true:

- the task exists in approved planning artifacts
- the task is marked `ready` in the tracker
- upstream dependencies are complete
- acceptance criteria and required tests are explicit
- any required ADRs already exist and are linked

If any precondition is missing, the task should not enter active
implementation.

## Standard Workflow

### 1. Start from a Single Approved Task

Before writing code, the implementer confirms:

- the exact task objective
- the acceptance criteria
- the required tests
- the task's non-goals
- any dependent tasks already merged or available in the active stack

The implementer should not begin with a broad feature interpretation. The
implementation target is the approved task, not the general problem space.

### 2. Create or Extend a Graphite Stack

Each implementation task should be represented as the smallest practical unit
of review in a Graphite stack.

Use the following defaults:

- one planned task maps to one branch and one pull request
- dependent tasks are stacked in dependency order
- unrelated work must not be added to an existing stack
- follow-up fixes discovered during review should stay in the same branch only
  if they do not expand scope

Graphite is the review transport, not the planning system. The stack should
mirror approved task decomposition rather than replace it.

### 3. Apply Test-Driven Development

The default implementation loop is:

1. select one acceptance criterion or behavior slice
1. write or update a failing automated test that expresses the behavior
1. run the relevant test to confirm it fails for the expected reason
1. write the minimum production code needed to satisfy the test
1. rerun the targeted tests
1. refactor while keeping tests green
1. repeat until the task acceptance criteria are covered

TDD expectations:

- new behavior starts with a failing test
- bug fixes start with a regression test when technically feasible
- refactors preserve or improve existing coverage before structure changes
- if a change cannot be driven by an automated test, the task must document why
  and define the alternate validation method

TDD is the default, not an aspiration. Skipping it requires an explicit reason
in the task or pull request notes.

### 4. Keep the Batch Small

Implementation branches should stay narrow enough that a reviewer can verify:

- what changed
- why it changed
- how it was tested
- whether it matches the task scope

Signals that a branch is too large:

- multiple acceptance criteria sets from different tasks are being implemented
- the branch mixes refactor, feature work, and cleanup without necessity
- the reviewer would need to reconstruct design intent from code alone
- the branch cannot be validated quickly with the task's required tests

When these signals appear, stop and split the work at the planning or task
layer before continuing.

### 5. Run Local Validation Before Review

Before opening a pull request, or requesting another review round, the
implementer must complete a local validation pass.

The local validation pass must include:

- all tests required by the task
- any broader suite required by the touched subsystem
- lint or static analysis checks required by the repository
- type checks or contract checks required by the repository

The minimum rule is simple: all required local tests must pass before the
branch enters review.

If the task is part of a stack, every branch in the stack should remain locally
valid relative to its parent branch.

### 6. Open the Pull Request for Review

A pull request is ready for review only when:

- the branch maps cleanly to one approved task
- stack position and dependency order are clear
- acceptance criteria traceability is present
- required local validation has passed
- unresolved scope or architecture questions are absent

The pull request description should state:

- the task being implemented
- the behavior or acceptance criteria addressed
- the tests added or updated
- the local validation run performed
- any known reviewer focus areas

### 7. Handle Review Without Losing Scope Discipline

During review:

- fix defects on the same branch when they stay within approved scope
- return to planning if review uncovers a missing requirement or design change
- preserve stack order and rebase carefully when upstream branches change
- rerun required local validation before re-requesting review

Review feedback should improve the task outcome, not silently widen it.

## Required Gates

The following gates are mandatory:

| Gate | Condition |
| --- | --- |
| I-1 | Task is approved, explicit, and startable before code changes begin |
| I-2 | Implementation starts with a failing automated test for each new behavior slice when technically feasible |
| I-3 | Each branch or pull request maps to a single approved task |
| I-4 | Graphite stack order matches task dependency order |
| I-5 | All required local tests and checks pass before review is requested |
| I-6 | Scope or architecture changes return to planning or ADR work before implementation continues |

Failure at any gate blocks the task from moving forward.

## Definition of Done for Implementation

Implementation is complete only when:

- the approved task behavior is implemented
- required tests exist and pass locally
- the branch is scoped to the intended task
- the pull request is opened in the correct Graphite stack position
- reviewer-facing traceability and validation evidence are present
- no unresolved planning or architecture ambiguity remains

Merge completion still depends on the review and tracking processes. This
document defines when implementation work is ready to enter review, not when
the task is fully closed.

## Agent-Specific Requirements

Implementation agents must follow these additional rules:

- read the approved task, plan, and linked ADRs before changing code
- use TDD unless the task explicitly documents why an automated test is not
  feasible
- avoid speculative cleanup outside the active task
- leave resumable notes when blocked or when handing off a partially completed
  branch
- verify the required local test pass before marking work ready for review
- use Graphite stacked pull requests rather than isolated unrelated branches

An implementation agent should optimize for correctness, traceability, and
small review surfaces, not speed through uncontrolled code generation.

## Exceptions

Exceptions should be rare and explicit.

Acceptable exception cases may include:

- infrastructure limitations that prevent meaningful automated tests
- emergency fixes where the shortest safe path differs from the normal stack
  flow
- repository-level failures unrelated to the task that block full local
  validation

Every exception must document:

- what rule was bypassed
- why it was necessary
- the risk introduced
- the follow-up action required to restore the standard process

Exceptions should be visible in the issue and pull request, not implied.

## Proposed Adoption

Adopt this process as the default implementation standard for all human and AI
implementers in this repository.

The practical rule set is:

1. Start from one approved task.
1. Drive behavior with tests first.
1. Keep work in Graphite stacks of small reviewable branches.
1. Pass required local tests before review.
1. Return to planning when implementation reveals unresolved scope or
   architecture questions.

This process keeps implementation aligned with planning, preserves review
quality, and makes agent-driven delivery more predictable.
