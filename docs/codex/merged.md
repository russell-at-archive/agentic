# Merged Implementation Standard

## Purpose

This document merges the strongest features of the three implementation
proposals in `docs/codex`, `docs/claude`, and `docs/gemini`.

It defines the standard process for moving an approved task from `ready` to a
reviewable Graphite pull request while preserving quality, traceability, and
architectural discipline.

The process is designed to be:

- rigorous enough for AI and human implementers
- practical enough for day-to-day execution
- explicit enough to support resumable work and review
- strict enough to keep unvalidated code out of review

## Core Principles

1. Test-driven development is the default implementation method.
1. Work is executed as small, atomic, independently reviewable task slices.
1. Each task is submitted through a Graphite stacked pull request.
1. Local validation must pass before work is submitted for review.
1. Every commit and pull request must trace back to an approved task, plan,
   and spec.
1. Scope or architectural changes return to planning or ADR work before
   implementation continues.

## Preconditions

Implementation may begin only when all of the following are true:

- the task exists in approved planning artifacts
- the task is marked `ready` in the tracker
- upstream dependencies are complete
- acceptance criteria and required tests are explicit
- any required ADRs already exist and are linked

If any precondition is missing, the task must not enter active
implementation.

## Implementation Lifecycle

### 1. Pre-Implementation Task Intake

Before writing code, the implementer must:

- confirm the task is in `ready`
- review the relevant `spec.md`, `plan.md`, and `tasks.md`
- review any linked ADRs
- identify the exact files or subsystems likely to change
- confirm the task's acceptance criteria, required tests, and non-goals
- verify the local environment and branch state are current

Implementation is the execution of an approved plan, not a fresh design
session.

### 2. Graphite Stack Setup

Before implementation begins, sync the local stack state:

```bash
gt sync
```

Branch names should use the task ID and a short slug:

```text
t-<##>-<short-slug>
```

Defaults:

- one approved task maps to one branch and one pull request
- dependent tasks are stacked in dependency order
- unrelated work must not be added to an existing stack
- follow-up fixes remain on the same branch only if they stay within scope

For the first task in a stack:

```bash
gt branch create t-<##>-<slug> --base main
```

For a task that depends on the current stack parent:

```bash
gt branch create t-<##>-<slug>
```

If an upstream branch changes or merges, restack before continuing:

```bash
gt restack
```

Do not implement on a stale base.

### 3. TDD Workflow

Every behavior change should follow red-green-refactor.

#### Red

1. Select one acceptance criterion or behavior slice.
1. Write the smallest automated test that proves the expected behavior.
1. Run the test and confirm it fails for the correct reason.

The test must fail because the behavior does not exist, not because the test
is broken.

#### Green

1. Write the minimum production code needed to make the failing test pass.
1. Do not add unrelated behavior or speculative cleanup.
1. Rerun the relevant tests.

#### Refactor

1. Improve clarity, naming, duplication, or structure while tests remain green.
1. Rerun tests after each meaningful refactor step.
1. Repeat the cycle until the task acceptance criteria are covered.

Expectations:

- new behavior starts with a failing test
- bug fixes start with a regression test when technically feasible
- refactors preserve or improve coverage before structure changes
- if a change cannot be driven by an automated test, the task or pull request
  must document why and define an alternate validation method

## Commit and Scope Management

Commit after a completed red-green-refactor cycle or other small verified unit
of progress.

Commit messages should follow repository conventions and reference the task ID.

Example:

```text
feat(auth): add token expiry validation (T-07)
```

Multiple commits per task are expected.

Keep each branch small enough that a reviewer can quickly verify:

- what changed
- why it changed
- how it was tested
- whether it matches the approved task

Signals that the branch is too large:

- multiple tasks are being implemented together
- feature work, refactor work, and cleanup are mixed without necessity
- the reviewer must reconstruct intent from code alone
- validation becomes unclear because the scope is too broad

When these signals appear, stop and split the work at the planning or task
layer before continuing.

## Local Validation Gate

Before opening a pull request, or re-requesting review after changes, the
implementer must complete a local validation pass.

The local validation pass must include the full required validation set for the
task and touched subsystem:

- unit tests
- integration or end-to-end tests when applicable
- lint or static analysis checks required by the repository
- type checks required by the repository
- build or contract checks required by the repository

Use the same commands or entrypoints the repository expects, ideally the same
ones CI uses.

If the task is part of a stack, every branch in the stack should remain locally
valid relative to its parent branch.

The minimum rule is simple: required local validation must pass before the
branch enters review.

If validation fails because of an upstream dependency or unrelated repository
issue, the task is blocked until the issue is resolved or an explicit
documented exception is approved.

## Pull Request Submission

Once validation passes, open the pull request in the correct Graphite stack
position:

```bash
gt pr create
```

The pull request should include:

- link to the GitHub Issue
- link to the relevant `spec.md`
- link to the relevant `plan.md`
- link or reference to the specific task in `tasks.md`
- summary of what was implemented
- tests added or updated
- local validation run performed
- any reviewer focus areas
- any approved exception or deviation from plan

The PR title should include the task ID.

A pull request is review-ready only when:

- the branch maps cleanly to one approved task
- stack position and dependency order are clear
- acceptance criteria traceability is present
- required local validation has passed
- unresolved scope or architecture questions are absent

## Review and Iteration

During review:

- fix defects on the same branch when they stay within approved scope
- restack when upstream branch changes require it
- rerun required local validation before re-requesting review
- return to planning if review uncovers a missing requirement or design change

Review should improve the task outcome, not silently expand the task.

## Required Gates

| Gate | Condition |
| --- | --- |
| I-1 | Task is approved, explicit, and startable before code changes begin |
| I-2 | Implementation starts with a failing automated test for each new behavior slice when technically feasible |
| I-3 | Each branch and pull request maps to a single approved task |
| I-4 | Graphite stack order matches task dependency order |
| I-5 | The full required local validation set passes before review is requested |
| I-6 | Traceability to issue, spec, plan, and task is present in the PR |
| I-7 | Scope or architecture changes return to planning or ADR work before implementation continues |

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
document defines when implementation is ready to enter review, not when the
task is fully closed.

## Agent-Specific Requirements

Implementation agents must:

- read the approved task, plan, and linked ADRs before changing code
- use TDD unless the task explicitly documents why an automated test is not
  feasible
- avoid speculative cleanup outside the active task
- leave resumable notes when blocked or when handing off incomplete work
- verify the required local validation pass before marking work ready for
  review
- use Graphite stacked pull requests rather than unrelated isolated branches

Implementation agents should optimize for correctness, traceability, and small
review surfaces rather than speed through uncontrolled code generation.

## Exceptions

Exceptions should be rare and explicit.

Acceptable exception cases may include:

- infrastructure limitations that prevent meaningful automated tests
- repository-level failures unrelated to the task that block full local
  validation
- emergency fixes where the shortest safe path differs from the normal stack
  flow

Every exception must document:

- what rule was bypassed
- why it was necessary
- the risk introduced
- the follow-up action required to restore the standard process

Exceptions must be visible in the issue and pull request, not implied.

## Practical Rule Set

1. Start from one approved task.
1. Sync the stack and branch from the correct parent.
1. Drive behavior with tests first.
1. Commit small verified units.
1. Keep each branch to one task and one stacked PR.
1. Pass the full required local validation set before review.
1. Return to planning or ADR work when implementation reveals unresolved
   questions.

This merged standard preserves the strongest features of the three original
proposals while keeping the process durable, readable, and executable.
