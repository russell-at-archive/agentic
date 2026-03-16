# Implementation Process

## Purpose

This document defines the implementation process for Archive Agentic. It
operates downstream of the planning process (`planning-process.md`) and task
tracking process (`tracking-process.md`). Implementation begins only after
gates 1 through 5 of the planning process are satisfied and the relevant
Linear issue is in `Selected`.

The intent is a delivery loop that is:

- disciplined enough to preserve engineering quality
- small-batch enough to keep review fast and reliable
- explicit enough for both human developers and AI agents to collaborate safely
- strict enough to prevent unverified code from reaching review

---

## Core Principles

- Approved plans drive implementation, not fresh interpretations of the
  problem.
- Test-driven development is the default implementation method. New behavior
  starts with a failing test.
- One task maps to one branch, one stack frame, and one pull request.
- Graphite stacks express task dependency order — they are the review
  transport, not the planning system.
- All required local checks must pass before a pull request is opened or
  updated for review.
- Scope change during implementation is a planning problem, not an execution
  decision.
- Significant architectural changes require an ADR before implementation
  continues.
- Every exception to this process must be documented explicitly.

---

## Preconditions

Implementation may start only when all of the following are true:

- the task exists in `tasks.md` and approved planning artifacts
- the Linear issue is in `Selected`
- all upstream dependency tasks are `Done`
- acceptance criteria and required tests are explicit
- any required ADRs exist and are linked
- the local repository is clean and the stack is synced

If any precondition is missing, the task must not enter active
implementation. Return to planning or wait for upstream work to complete.

---

## Tooling Reference

| Tool | Purpose | Key Commands |
| --- | --- | --- |
| Graphite (`gt`) | Stacked PR and branch management | `gt create`, `gt submit`, `gt restack`, `gt sync`, `gt modify` |
| Test runner | Automated test execution | Project-defined (see canonical test command) |
| Linter | Code style and static analysis | Project-defined |
| Type checker | Type correctness | Project-defined |
| `/speckit.implement` | Structured task execution strategy | — |
| Linear issues | Live execution state and evidence | — |

---

## Workflow

### 1. Pre-Implementation Checklist

Before writing any code, confirm:

- [ ] Linear issue is `Selected` and all upstream tasks are `Done`.
- [ ] `spec.md`, `plan.md`, and `tasks.md` are reviewed and understood.
- [ ] The acceptance criteria and required tests for this task are clear.
- [ ] The task's non-goals are understood.
- [ ] Any dependent tasks already merged or available in the active stack are
  identified.
- [ ] The local stack is synced: `gt sync`.

### 2. Create the Branch

Branch names must include both the Linear issue ID and the task ID:

```text
<linear-id>-t-<##>-<short-slug>
```

Example: `arc-42-t-07-token-expiry`

For the first task in a feature (no upstream task in the stack):

```sh
gt sync
gt create <linear-id>-t-<##>-<slug>
```

For a task that depends on an upstream task already in the stack, create the
branch while checked out on the upstream branch:

```sh
gt create <linear-id>-t-<##>-<slug>
```

Graphite tracks the parent automatically. Update the Linear issue: add the
branch name and move the state to `In Progress`.

### 3. Implement Using TDD

The default implementation loop is red-green-refactor, repeated until all
acceptance criteria are covered by passing tests.

#### Red — write a failing test

1. Select one acceptance criterion or behavior slice from the task.
2. Write the smallest automated test that would prove it is satisfied.
3. Run the test and confirm it **fails for the expected reason** — not
   because of a setup error, syntax problem, or missing import. Fix
   infrastructure failures before proceeding.
4. Do not write production code yet.

#### Green — write minimum production code

1. Write the smallest production code change that makes the failing test
   pass.
2. Run the full test suite. All tests — including pre-existing ones — must
   pass.
3. If pre-existing tests break, fix them before continuing. Do not proceed
   with a broken suite.

#### Refactor — improve without changing behavior

1. With a green suite, improve code clarity, remove duplication, or tighten
   abstractions.
2. Run the full test suite after every refactor step.
3. Commit the completed cycle.

Commit message format:

```text
<type>(<scope>): <short description> (T-##, <LINEAR-ID>)
```

Example: `feat(auth): add token expiry validation (T-07, ARC-42)`

Repeat the cycle until all acceptance criteria are covered.

**TDD expectations by change type:**

| Change type | TDD requirement |
| --- | --- |
| New behavior | Failing test required before production code |
| Bug fix | Regression test required when technically feasible |
| Refactor | Existing coverage preserved or improved before structure changes |
| Infrastructure or config | Document alternate validation method if automated test is not feasible |

TDD is the default, not an aspiration. Skipping it requires an explicit
reason documented in the task or pull request notes. See the Exceptions
section.

### 4. Run the Full Local Validation Pass

Before opening a pull request — and again after addressing review feedback —
run the full local validation pass. This is a hard gate with no implicit
exceptions.

Required checks:

- [ ] **All tests pass** — the full suite, not just tests for the changed
  subsystem.
- [ ] **Linting passes** — all project linting rules.
- [ ] **Type checking passes** — no type errors introduced.
- [ ] **Build succeeds** — the project builds without errors or warnings.

If the task is part of a stack, every branch in the stack must remain locally
valid relative to its parent branch.

If a test failure is caused by an unmerged upstream task, the current task is
`Blocked`. Document the blocker in the Linear issue and do not open the PR
until the suite is green.

### 5. Open the Pull Request

Submit via Graphite:

```sh
gt submit --stack
```

**PR title format:**

```text
[T-##] <Task Title>
```

**PR description must include:**

- Link to the Linear issue
- Link to `spec.md` and the relevant acceptance criteria
- Link to `plan.md`
- Link to the specific task in `tasks.md`
- Summary of what was implemented
- Tests added or updated
- Output of the local validation pass, or a link to a passing CI run
- Any deviation from the plan and its justification

Move the Linear issue to `In Review`.

Signals that a branch is too large for a single PR:

- Multiple acceptance criteria sets from different tasks are included.
- The branch mixes refactor, feature work, and cleanup without necessity.
- A reviewer would need to reconstruct design intent from code alone.
- The branch cannot be validated quickly with the task's required tests.

When these signals appear, stop. Split the work at the planning or task layer
before submitting.

### 6. Respond to Review

If review finds defects:

1. Move the Linear issue back to `In Progress`.
2. Fix the defects on the same branch.
3. Run the full local validation pass again. All checks must pass.
4. Push the fix — `gt modify` updates the open PR in place.
5. Restack if an upstream frame changed: `gt restack`.
6. Move the Linear issue back to `In Review`.

If review uncovers a missing requirement or design change, return to
planning. Do not silently widen scope on the current branch.

### 7. Merge

Stack frames are merged from the bottom up. Graphite manages rebase order
when upstream frames merge. After the PR is approved and CI passes:

```sh
gt submit --stack
```

Update the Linear issue:

- Attach final test and validation evidence.
- Check off all acceptance criteria.
- Move to `Done`.

---

## Stack Discipline

**When to stack:** Stack when one task produces interfaces, types, or data
that a downstream task directly depends on. The downstream task cannot be
correctly implemented without the upstream code in place.

**When not to stack:** Independent tasks branch from the trunk and ship as
separate PRs. Do not stack tasks that have no dependency relationship —
coupling their review is unnecessary.

**Stack depth:** Prefer stacks of three or fewer frames. When a stack grows
beyond three to four frames, look for opportunities to merge earlier frames
before adding more depth. Deep stacks are harder to rebase, review, and
reason about.

**Merge order:** Merge from the bottom up. Do not merge a downstream frame
before its upstream frame is merged and restacked.

**Graphite is the review transport, not the planning system.** The stack
structure should mirror the approved task dependency order from `tasks.md`.
It should not introduce sequencing that is not in the plan.

---

## Definition of Done for Implementation

Implementation work is ready to enter review — and only then — when:

- the approved task behavior is fully implemented
- all acceptance criteria have corresponding passing tests
- the branch is scoped to the intended task only
- the full local validation pass has completed without errors
- the PR is opened in the correct Graphite stack position
- reviewer-facing traceability and validation evidence are present in the PR
  description
- no unresolved planning or architecture ambiguity remains

Merge completion depends on the review and tracking processes. This process
defines when implementation is ready for review, not when the task is closed.

---

## Gate Rules

| Gate | Condition | Owner |
| --- | --- | --- |
| I-1 | Task is approved, `Selected`, and all upstream tasks are `Done` before code changes begin | Implementer |
| I-2 | Branch created and issue updated to `In Progress` before any code is written | Implementer |
| I-3 | Each new behavior slice has a failing automated test before production code is written | Implementer |
| I-4 | One branch and one PR map to exactly one approved task | Implementer |
| I-5 | Graphite stack order matches task dependency order from `tasks.md` | Implementer |
| I-6 | Full local validation pass — tests, lint, type checks, build — passes before review is requested | Implementer |
| I-7 | PR description includes spec, plan, task traceability, and validation evidence | Implementer |
| I-8 | Full local validation pass repeated after review feedback before re-requesting review | Implementer |
| I-9 | Scope or architecture changes return to planning or ADR work before implementation continues | Implementer + Tech Lead |

Failure at any gate blocks the task from progressing.

---

## Agent Execution Protocol

Agent-run implementation follows the same workflow and gates as human
implementation with these additional requirements.

**Before starting:**

- Read the approved task, `plan.md`, `spec.md`, and any linked ADRs before
  changing any code.
- Report the current state of the Linear issue.
- Confirm all upstream dependencies are `Done`.
- Confirm the local repository is clean and the stack is synced.

**During implementation:**

- Write a failing test and confirm it fails before writing any production
  code. Record the failing test output in the issue execution log.
- Do not assume a test is correct without running it.
- Run the full test suite after every green cycle, not only at the end.
- Add an execution log entry to the issue after each meaningful step.
- Avoid speculative cleanup or refactoring outside the active task.

**Before opening a PR:**

- Run the full local validation pass.
- Include the validation output in the PR description or as a linked
  artifact.

**On uncertainty:**

- Stop work and document the blocker in the Linear issue.
- Move the issue to `Blocked`.
- Do not resolve product or architectural ambiguity autonomously.
- Do not improvise scope or design. Return to planning.

An agent that completes implementation updates the issue state identically to
a human developer: attach validation evidence, verify acceptance criteria,
and move to `In Review` after the PR opens.

---

## Exceptions

Exceptions to this process are permitted only when they are explicit and
documented. Undocumented exceptions are process violations.

Acceptable exception cases may include:

- infrastructure or configuration changes where meaningful automated tests
  are not technically feasible
- emergency fixes where the shortest safe path differs from the standard
  stack flow
- repository-level failures unrelated to the task that prevent full local
  validation

Every exception must document all of the following in the Linear issue and
PR:

| Field | Required content |
| --- | --- |
| Rule bypassed | Which specific gate or requirement was skipped |
| Justification | Why the exception was necessary |
| Risk introduced | What could go wrong as a result |
| Follow-up action | What will be done to restore the standard process |

Exceptions are visible in the issue and pull request. They are never implied.

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Agent or implementer skips red phase and writes production code first | High | Gate I-3 requires failing test output before production code; execution log enforces this for agents |
| Stack becomes stale relative to upstream merges | High | Run `gt sync` at the start of every session; run `gt restack` after any upstream frame changes |
| Local validation passes but CI fails due to environment differences | Medium | Use the same commands locally as CI; flag environment divergence as a blocker |
| Scope creep discovered during TDD cycle reveals missing requirements | Medium | Stop, document in the issue, return to planning before continuing |
| Stack grows too deep and becomes difficult to review and rebase | Medium | Soft cap of three to four frames; merge earlier frames before adding depth |
| PR opened with a failing validation pass | Low | Gate I-6 is a hard requirement; CI provides a second check but does not substitute for local validation |
| Exceptions used to avoid the process rather than address genuine constraints | Low | Exceptions require documented justification and follow-up; reviewers verify exception entries |

---

## Open Questions

See [docs/open-questions.md](open-questions.md) for the consolidated
and deduplicated question backlog. Questions originating here are tracked as OQ-07,
OQ-14, OQ-15, OQ-18, OQ-19, OQ-26.
