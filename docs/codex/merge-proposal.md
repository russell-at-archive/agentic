# Unified Review Process Proposal

## Purpose

This proposal merges the strongest elements of the three review-process drafts
into a single operating model for Archive Agentic.

The result keeps the Codex/Claude structure because it is the most complete and
operationally durable, while incorporating Gemini's strongest additions:

- a four-tier mental model for review depth
- stronger expectations for agent-authored work
- explicit architectural scrutiny before approval
- a concise checklist that sharpens reviewer judgment

The goal is a review process that is rigorous without becoming theatrical,
blunt without becoming hostile, and structured enough to work consistently for
both humans and agents.

## Review Philosophy

- Review is a quality gate, not a ceremony.
- The standard is justified confidence, not polite approval.
- Correctness, clarity, traceability, and maintainability take priority over
  merge speed.
- Small, well-scoped changes are easier to review rigorously than large,
  mixed-purpose changes.
- The burden of clarity is on the author, not the reviewer.
- Missing explanation, missing evidence, or unresolved risk are defects in the
  submission.
- Review should reject ambiguity, hidden coupling, and deferred-risk thinking.

## Review Goals

Every review should answer these questions:

1. Is the change correct relative to `spec.md`, `plan.md`, and `tasks.md`?
1. Is the behavior safe in normal, edge, and failure conditions?
1. Is the design coherent with the existing system and relevant ADRs?
1. Are tests and validation proportionate to the change's risk?
1. Is the scope tight enough to review with confidence?
1. Is the code understandable enough that a future engineer can change it
   safely?

If any answer is "not clearly," the review is not complete.

## Four-Tier Review Model

Every formal review should pass through four tiers. These tiers do not replace
the workflow below; they provide the lens through which the workflow is
executed.

### Tier 1: Automated Validation

Before deep review begins, the change must prove basic viability.

- required build, lint, and type checks pass
- the existing relevant test suite passes
- new or updated tests required by the task are present
- validation evidence is attached or linked
- the PR links the governing planning artifacts

### Tier 2: Implementation Fidelity

The reviewer confirms the change does what the approved task says it should do,
and does not quietly expand scope.

- the change maps to one approved task unless an exception is explicit
- implementation matches the intended behavior in `spec.md` and `plan.md`
- differences from the plan are justified and documented
- unrelated cleanup or speculative refactoring is excluded

### Tier 3: Architectural Integrity

This is the deepest technical review layer.

- abstractions remain coherent
- interfaces and invariants remain explicit
- concurrency, retry, ordering, security, migration, and data risks are
  considered where relevant
- side effects on adjacent subsystems are examined
- significant architectural choices are backed by ADRs
- the implementation does not create avoidable future debt

### Tier 4: Final Polish

Once the change is correct and sound, the reviewer confirms it is maintainable.

- names are clear and idiomatic
- structure and control flow are understandable
- tests assert meaningful behavior
- documentation and comments explain genuinely non-obvious logic
- diagnostics, logging, and failure behavior are sufficient for support and
  debugging

## Inputs and Preconditions

No submission may enter formal review unless all of the following are present:

- a linked issue in `status:in-review`
- links to the parent `spec.md`, `plan.md`, and `tasks.md`
- any required ADR links
- a concise summary of what changed and why
- a list of tests added, updated, or intentionally omitted
- local validation evidence or a passing CI run
- explicit disclosure of risks, trade-offs, and deferred work

If any input is missing, the reviewer should stop and return the PR without
starting deep review.

## Roles

### Author

The author is responsible for making the change reviewable.

Author duties:

- keep scope aligned to one approved task unless an exception is approved
- provide traceability to planning artifacts
- make architectural changes explicit
- supply validation evidence
- respond to every material review finding
- preserve review history unless repository policy requires otherwise

### Reviewer

The reviewer is responsible for independently deciding whether the change
should merge.

Reviewer duties:

- review the diff, not just the summary
- inspect adjacent code paths when the local diff is not enough
- test claims against code, artifacts, and validation evidence
- identify correctness, risk, maintainability, and scope defects
- block when confidence is insufficient
- separate mandatory findings from optional suggestions

### Reviewing Agent

A reviewing agent acts as a strict reviewer, not a summarizer.

Agent duties:

- read the approved task context before judging the diff
- inspect changed files and neighboring implementation paths
- reason explicitly about regressions, edge cases, and missing validation
- cite concrete file and line references for findings
- avoid praise, filler, and vague commentary
- state "no findings" only after a real review reaches that conclusion

## Agent-Specific Review Rules

When agents are involved as authors or reviewers, apply these additional
requirements:

- agent-authored changes should receive explicit scrutiny for hallucinated
  assumptions, weak edge-case handling, and unjustified abstractions
- reviewers should inspect execution logs or equivalent work records when they
  are needed to verify process claims
- if the implementation claims test-first development, the evidence should be
  verifiable
- agent-to-agent review is useful as an early filter, but it does not replace
  final approval authority
- Tier 3 architectural review for high-risk or architecturally significant
  changes should be performed by a human or a designated senior reviewer agent

## Review States

Use a simple verdict model in the PR review itself:

- `reject`: the change is fundamentally unreviewable, unsafe, or out of scope
- `revise`: the direction is acceptable, but defects must be fixed before merge
- `approve`: the reviewer has sufficient confidence for merge

Do not approve with known unresolved correctness issues.

## Review Workflow

### 1. Intake Check

Before reading the diff in detail, confirm:

- the PR maps to one approved task
- the PR links the governing artifacts
- the branch is review-sized
- validation evidence exists
- the change does not introduce an undocumented architectural decision

If this check fails, stop and request correction before deep review.

### 2. Intent Reconstruction

The reviewer reads:

- the task in `tasks.md`
- the relevant acceptance criteria in `spec.md`
- the implementation approach in `plan.md`
- any linked ADRs

The reviewer should be able to restate the intended behavior and constraints in
plain language before judging the code.

### 3. Diff Review

Review the patch with emphasis on:

- correctness of the new behavior
- regression risk in changed or deleted behavior
- interface, schema, and contract changes
- invariants, state transitions, and failure handling
- security, privacy, and data-exposure boundaries where relevant
- migration, rollout, rollback, and backward compatibility concerns
- architectural integrity and maintainability

Inspect adjacent code when necessary to evaluate the diff safely.

### 4. Validation Review

Check that the evidence is proportionate to risk.

Minimum expectations:

- new behavior has tests
- bug fixes have regression tests when feasible
- refactors preserve or improve coverage
- integration points receive integration or end-to-end validation where needed
- manual validation is documented when automation is not feasible

A passing suite does not override an obviously weak test strategy.

### 5. Verdict

The reviewer leaves one of three outcomes:

- `reject` with clear reasons and the required next step
- `revise` with findings ordered by severity
- `approve` with any non-blocking suggestions clearly marked as optional

### 6. Re-Review

After the author updates the PR:

- re-check every blocking finding
- verify no new regressions were introduced
- re-run critical validation where needed
- do not rely only on comment-thread resolution if the diff materially changed

## Required Review Lenses

Every formal review should explicitly examine these lenses.

### Scope Control

- Does the PR implement only the approved task?
- Are unrelated cleanups mixed into the submission?
- Is the PR small enough to reason about completely?

### Correctness

- Does the implementation satisfy the acceptance criteria?
- Do edge cases and failure paths behave correctly?
- Are important invariants preserved?

### Architecture and Design

- Is the design consistent with the approved plan and ADRs?
- Does the change introduce hidden coupling or boundary leakage?
- Is the solution the simplest sound approach rather than an over-engineered
  one?

### Test Adequacy

- Would the tests catch the most likely regression?
- Are tests validating behavior rather than implementation trivia?
- Are important branches, failure modes, and integration seams covered?

### Operability

- Is rollout or migration risk addressed?
- Are logs, metrics, alerts, or diagnostics adequate where needed?
- If this breaks under real use, will the failure be understandable and
  recoverable?

### Maintainability

- Can a future engineer explain the code without reverse-engineering intent?
- Are naming, module boundaries, and control flow coherent?
- Does the change add needless complexity or future rewrite pressure?

## Findings Standard

Every blocking finding must contain:

- a clear statement of the problem
- why it matters
- the affected file and line reference when available
- the expected correction or the question that must be resolved

Findings should be written as defects, not vague discomfort.

Weak findings include:

- "this feels off"
- "maybe simplify?"
- "can we improve naming?"

Optional suggestions are allowed, but they must never be mixed with mandatory
defects.

## Comment Taxonomy

Use explicit prefixes in review comments:

- `blocking:` must be resolved before approval
- `question:` must be answered before confidence is sufficient
- `suggestion:` optional improvement, not required for merge
- `note:` context or observation with no action required

This keeps reviews machine-readable and easier to triage.

## Blockers

Any one of the following is sufficient to block approval:

- missing traceability to approved planning artifacts
- scope expansion beyond the approved task
- undocumented architectural change
- incorrect behavior or likely regression
- insufficient test evidence for the risk level
- unclear code where correctness cannot be confidently established
- unresolved security, privacy, data loss, or migration risk
- missing rollback or recovery thinking for a high-impact change

When in doubt between blocking and approving, block and explain why.

## Review Depth by Change Type

### Low-risk change

Examples:

- typo fixes
- copy-only updates
- isolated non-behavioral refactors with strong coverage

Expectations:

- fast review
- basic artifact traceability
- confirmation that risk is actually low

### Standard change

Examples:

- most feature work
- bug fixes in known subsystems
- schema-safe API changes

Expectations:

- full artifact review
- code-path review
- test adequacy review
- explicit verdict

### High-risk change

Examples:

- authentication or authorization logic
- persistence, migration, or deletion logic
- distributed workflow or concurrency changes
- platform, infrastructure, or architectural boundary changes

Expectations:

- deeper Tier 3 architectural review
- stronger evidence than unit tests alone
- explicit failure-mode and rollback review
- a human or designated senior reviewer for final architectural sign-off when
  feasible
- no approval under residual ambiguity

## Reviewer Checklist

Before approval, the reviewer should be able to answer "yes" to these
questions:

1. Is this the simplest sound way to solve the problem?
1. Do I understand what the changed code is doing and why?
1. Are edge cases and failure modes handled, not just the happy path?
1. If this breaks in production, will diagnosis and recovery be practical?
1. Does the change align with the approved plan, ADRs, and repository
   standards?

If the reviewer cannot answer yes, approval should wait.

## Escalation Rules

Escalate beyond the normal reviewer when:

- the PR conflicts with planning artifacts
- the author and reviewer disagree on intended behavior
- a significant architectural choice lacks an ADR
- the review uncovers a missing product decision rather than a coding defect
- the risk is cross-cutting and cannot be resolved inside one task

Escalation targets:

- tech lead for design and task-boundary disputes
- product owner for behavior or scope disputes
- architecture owner for ADR-required changes

## Service Levels

Use these targets:

- first review on standard PRs within one business day
- first review on high-risk PRs within two business days
- author response to blocking findings within one business day when practical
- re-review within one business day after substantive updates

Missing service levels is a process issue. Lowering review quality is not the
fix.

## Metrics and Calibration

Track review quality with a small, useful set of metrics:

- review turnaround time
- rework rate after first review
- escaped defect rate by PR
- percentage of PRs rejected for scope or traceability problems
- percentage of PRs approved with no findings
- percentage of review findings later confirmed as real defects

Then run recurring calibration:

- sample recently merged PRs
- compare findings with post-merge outcomes
- identify false negatives, false positives, and recurring blind spots
- refine checklists, prompts, and upstream process rules

If review repeatedly catches the same failure class, the upstream process is
too weak.

## Adoption Plan

1. Adopt this process through an ADR.
1. Add PR template sections for traceability, validation evidence, risks, and
   explicit verdict.
1. Add the reviewer checklist and comment taxonomy to review guidance.
1. Require stronger architectural review for high-risk changes.
1. Add agent-review guidance covering execution evidence and senior sign-off.
1. Pilot the merged process, then adjust based on calibration results.

## Definition of Done for Review

Review is complete only when:

- all blocking findings are resolved
- all four review tiers have been satisfied at the appropriate depth
- planning traceability is intact
- required ADRs are present
- evidence matches the risk of the change
- the reviewer can explain why the change is safe enough to merge
- the final verdict is explicit

If review ends with uncertainty that cannot be named, the review was not deep
enough.
