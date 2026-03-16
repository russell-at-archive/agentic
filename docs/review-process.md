# Software Review Process

## Purpose

This document defines the software review process for Archive Agentic.

Review is the final quality gate in the delivery workflow. Planning decides
what should be built. Task tracking decides what is active. Implementation
decides how code changes. Review decides whether a change is safe, correct,
maintainable, and worthy of merge.

The standard is not polite approval. The standard is justified confidence.

## Review Philosophy

- Review is a quality gate, not a ceremony.
- Correctness over speed.
- Clarity over cleverness.
- Proven reliability over theoretical elegance.
- Absolute traceability from approved intent to implementation.
- Small, focused changes are easier to review rigorously than large,
  mixed-purpose changes.
- The burden of clarity is on the author, not the reviewer.
- Missing explanation, missing evidence, or unresolved risk are defects in the
  submission.
- Review should optimize for long-term maintainability, not short-term merge
  velocity.

## Review Goals

Every review should answer these questions:

1. Is the change correct relative to `spec.md`, `plan.md`, and `tasks.md`?
1. Is the behavior safe in normal, edge, and failure conditions?
1. Is the design coherent with the existing system and relevant ADRs?
1. Are tests and validation sufficient for the risk of the change?
1. Is the change scoped tightly enough to review with confidence?
1. Is the code understandable enough that a future engineer can modify it
   safely?

If any answer is "not clearly," the review is not complete.

## Design Principles

- Default to one task, one branch, one pull request, one review unit.
- Prefer rejection of unclear work over acceptance of ambiguous work.
- Demand evidence, not assurances.
- Review behavior, interfaces, invariants, and failure modes, not just syntax.
- Separate mandatory defects from optional improvement suggestions.
- Make review findings resumable and auditable for both humans and agents.

## Four-Tier Review Lifecycle

Every formal review should pass through four tiers. These tiers define review
depth and help reviewers avoid shallow approval.

### Tier 1: Automated Validation

Before deep review begins, the PR must prove baseline viability.

- required build, lint, and type checks pass with no unresolved failures
- the relevant existing test suite passes
- task-required new or updated tests are present and passing
- traceability to the relevant `spec.md`, `plan.md`, and `tasks.md` is present
- validation evidence is attached or linked

### Tier 2: Implementation Fidelity

The reviewer confirms the change does what the approved task says it should do,
and does not silently expand scope.

- the PR maps to one approved task unless an explicit exception exists
- implementation matches the intended behavior in `spec.md` and `plan.md`
- any deviation from the plan is justified and documented
- speculative cleanup or unrelated refactoring is excluded

### Tier 3: Architectural Integrity

This is the deepest technical review layer.

- abstractions remain coherent
- interfaces and invariants remain explicit
- concurrency, ordering, retry, migration, and security concerns are evaluated
  where relevant
- hidden impacts on adjacent subsystems are considered
- significant architectural choices are backed by ADRs
- the implementation does not introduce avoidable future debt

### Tier 4: Final Polish

Once the change is correct and sound, the reviewer confirms it is maintainable.

- names are clear and idiomatic
- structure and control flow are understandable
- types are appropriately narrow and descriptive
- comments and documentation explain genuinely non-obvious logic
- diagnostics, logging, and failure behavior are sufficient where needed

## Inputs and Preconditions

No submission may enter formal review unless all of the following are present:

- a linked Linear issue in `In Review`
- links to the parent `spec.md`, `plan.md`, and `tasks.md`
- any required ADR links for architectural decisions
- a concise PR summary explaining what changed and why
- a list of tests added, updated, or intentionally omitted
- evidence that required local validation passed, or a passing CI run
- explicit disclosure of known risks, trade-offs, and deferred work

If any input is missing, the reviewer should stop and return the PR without
starting deep review.

## Review Roles

### Author

The author is responsible for making the change reviewable.

Author duties:

- keep scope aligned to one approved task unless an approved exception exists
- provide traceability to planning artifacts
- make architectural changes explicit
- supply validation evidence
- respond to every material review finding
- avoid force-pushing away review history unless repository policy requires it

### Reviewer

The reviewer is responsible for independently evaluating whether the change
should merge.

Reviewer duties:

- review the actual diff, not just the PR summary
- inspect impacted code paths beyond the changed lines when necessary
- test the author's claims against code and artifacts
- identify correctness, risk, maintainability, and scope issues
- block when confidence is insufficient
- distinguish mandatory findings from optional suggestions

### Reviewing Agent

A reviewing agent acts as a strict reviewer, not a summarizer.

Agent duties:

- read the approved task context before judging the diff
- inspect changed files and adjacent implementation paths
- reason explicitly about regressions, edge cases, and missing validation
- cite concrete file and line references for every finding
- avoid praise, filler, or vague review comments
- state "no findings" only when the review actually reached that conclusion

## Agent-Specific Review Rules

When agents are involved as authors or reviewers, apply these additional
requirements:

- agent-authored changes should receive explicit scrutiny for hallucinated
  assumptions, weak edge-case handling, and unjustified abstractions
- agents should review each other's work before human review when practical,
  but peer-agent review does not replace final approval authority
- reviewers should inspect agent execution logs or equivalent work records when
  they are needed to verify process claims
- if an implementation claims test-first development, the evidence should be
  verifiable
- if an agent receives review feedback, it should document its understanding of
  the critique before attempting the fix
- final Tier 3 architectural review for high-risk or architecturally
  significant changes should be performed by a human or a designated senior
  reviewer agent

## Review States

Use a simple verdict model inside the PR review itself:

- `reject`: the submission is not mergeable in its current state
- `revise`: the direction is acceptable, but defects must be fixed before merge
- `approve`: the reviewer has sufficient confidence for merge

Interpretation:

- `reject` means the PR is fundamentally unreviewable, out of scope, unsafe, or
  inconsistent with the approved plan
- `revise` means the review found specific defects, gaps, or missing evidence
- `approve` means the reviewer believes the change satisfies the task with
  sufficient evidence and acceptable risk

Do not approve with known unresolved correctness issues.

## Review Workflow

### 1. Intake Check

Before reading the diff in detail, confirm:

- the PR maps to one approved task
- the PR description links the governing artifacts
- the branch appears review-sized
- validation evidence exists
- the change does not introduce an undocumented architectural decision

If this check fails, stop and request correction before deep review.

### 2. Intent Reconstruction

The reviewer reads:

- the task in `tasks.md`
- the relevant acceptance criteria in `spec.md`
- the implementation approach in `plan.md`
- any linked ADRs

The reviewer should be able to state the intended behavior and constraints in
plain language before judging the code.

### 3. Diff Review

Review the patch with emphasis on:

- correctness of the new behavior
- deleted or altered behavior that may regress existing users
- interface, schema, and contract changes
- state transitions, invariants, and error handling
- concurrency, idempotency, retries, and ordering risks where applicable
- authorization, data exposure, and security boundaries where applicable
- migration, rollout, rollback, and backward compatibility concerns
- naming, structure, and readability

Reviewing agents should inspect neighboring code when the local diff is not
enough to evaluate a claim safely.

### 4. Validation Review

Check that the evidence is proportionate to the risk of the change.

Minimum expectations:

- new behavior has tests
- bug fixes have regression tests when technically feasible
- refactors preserve or improve coverage
- integration points have integration or end-to-end validation where risk
  warrants it
- manual validation is documented when automation is not feasible

A passing test suite does not override an obviously weak test strategy.

### 5. Verdict

The reviewer leaves one of three outcomes:

- `reject` with clear reasons and the required next step
- `revise` with enumerated findings ordered by severity
- `approve` with any residual non-blocking suggestions clearly marked as such

### 6. Re-Review

After the author updates the PR:

- re-check every blocking finding
- verify no new regressions were introduced
- re-run any critical validation relevant to the changed area when needed
- avoid re-reviewing only the comment threads if the diff materially changed

## Required Review Lenses

Every formal review must examine these lenses explicitly.

### Scope Control

- Does the PR implement only the approved task?
- Are unrelated cleanups mixed into the submission?
- Is the PR small enough that a reviewer can reason about it completely?

### Correctness

- Does the implementation satisfy the stated acceptance criteria?
- Do edge cases and failure paths behave correctly?
- Are important invariants preserved?

### Architecture and Design

- Is the design consistent with the approved plan and ADRs?
- Does the change introduce hidden coupling or leakage across boundaries?
- Is the solution the simplest sound approach rather than an over-engineered
  one?

### Test Adequacy

- Would the current tests catch the most likely regression?
- Are tests asserting meaningful behavior rather than implementation trivia?
- Are important branches, failure modes, and integration seams covered?

### Operability

- Is rollout or migration risk addressed?
- Are logs, metrics, alerts, or diagnostics adequate when needed?
- If this breaks under real use, will the failure be understandable and
  recoverable?

### Maintainability

- Can a future engineer explain the code without reverse-engineering intent?
- Are names, module boundaries, and control flow coherent?
- Does the code add needless complexity or special cases?

## Findings Standard

Every blocking finding must contain:

- a clear statement of the problem
- why it matters
- the affected file and line reference when available
- the expected correction or the question that must be resolved

Findings should be written as defects, not as vague discomfort.

Good findings:

- identify a specific regression path
- point out missing validation for a concrete risk
- identify a design inconsistency with the approved plan
- identify a test gap tied to behavior

Weak findings:

- "this feels off"
- "maybe simplify?"
- "can we improve naming?"

Optional suggestions are allowed, but they must never be mixed with mandatory
defects.

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

## Review Comment Taxonomy

Use explicit prefixes in review comments:

- `blocking:` must be resolved before approval
- `question:` must be answered before confidence is sufficient
- `suggestion:` optional improvement, not required for merge
- `note:` context or observation with no action required

This keeps agent and human reviews machine-readable and easier to triage.

## Review Depth by Change Type

### Low-risk change

Examples:

- typo fix
- copy-only change
- isolated non-behavioral refactor with strong existing coverage

Expectations:

- fast review
- basic artifact traceability
- confirmation that risk is actually low

### Standard change

Examples:

- most feature tasks
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
- platform, infra, or architectural boundary changes

Expectations:

- two reviewers when feasible, one of whom is a domain owner
- linked ADR if the design is materially significant
- explicit failure mode and rollback review
- stronger evidence than unit tests alone
- final Tier 3 architectural sign-off by a human or designated senior reviewer
  agent when feasible
- no approval under residual ambiguity

## Agent Review Protocol

Reviewing agents should follow a fixed protocol:

1. Read the PR summary and linked issue.
1. Read the relevant `spec.md`, `plan.md`, `tasks.md`, and any ADRs.
1. Inspect the diff.
1. Inspect adjacent code needed to evaluate the diff safely.
1. Evaluate tests and validation evidence.
1. Review execution logs or equivalent artifacts when needed to verify process
   claims.
1. Produce findings ordered by severity with file references.
1. State open assumptions or missing context.
1. End with a verdict: `reject`, `revise`, or `approve`.

Agent output should never lead with summary. Findings come first.

## Reviewer Checklist

Before approval, the reviewer should be able to answer "yes" to these
questions:

1. Is this the simplest sound way to solve the problem?
1. Do I understand what the changed code is doing and why?
1. Are edge cases and failure modes handled, not just the happy path?
1. If this breaks at 3 AM, can an engineer diagnose and recover quickly?
1. Does the change align with the approved plan, ADRs, and repository
   standards?

If the reviewer cannot answer yes, approval should wait.

## Feedback and Revision Protocol

Review is a technical dialogue, not a personal critique.

- be constructive but direct
- do not negotiate away correctness, safety, or maintainability
- if a change introduces debt or risk, it must be fixed or explicitly tracked
  and approved
- changes made in response to review should trigger re-validation appropriate to
  the affected area

## Escalation Rules

Escalate beyond the normal reviewer when:

- the PR conflicts with planning artifacts
- the author and reviewer disagree on intended behavior
- a significant architectural choice lacks an ADR
- review reveals a missing product decision rather than a coding defect
- a risk is cross-cutting and cannot be resolved inside one task

Escalation target:

- tech lead for design and task boundary disputes
- product owner for behavior or scope disputes
- architecture owner for ADR-required changes

## Service Levels

Fast review matters, but quality matters more. Use these targets:

- first review on standard PRs within one business day
- first review on high-risk PRs within two business days
- author response to blocking findings within one business day when practical
- re-review within one business day after substantive updates

Missing the service level is a process issue. Lowering review quality is not
the fix.

## Metrics

Track review quality with a small set of metrics:

- review turnaround time
- rework rate after first review
- escaped defect rate by PR
- percentage of PRs rejected for scope or traceability problems
- percentage of PRs approved with no findings
- percentage of review findings later confirmed as real defects

Do not optimize for comment count. Optimize for defect detection and merge
confidence.

## Calibration

Run a recurring review calibration:

- sample recently merged PRs
- compare reviewer findings with post-merge outcomes
- identify false negatives, false positives, and recurring blind spots
- refine the reviewer checklist and agent prompts
- update planning or implementation rules when review catches the same class of
  failure repeatedly

If review repeatedly catches the same issue class, the process upstream is too
weak.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Rubber-stamp approvals | High | Require checklist use and deeper review for high-risk changes. |
| Review delays implementation | Medium | Keep tasks small so review is fast and focused. |
| Agents miss subtle architectural flaws | High | Require final Tier 3 sign-off by a human or senior reviewer agent for high-risk changes. |
| Tone drift makes review unproductive | Medium | Keep feedback direct, technical, and non-personal. |

## Adoption Plan

1. Adopt this process as the project standard through an ADR.
1. Add PR template sections for traceability, validation evidence, risks, and
   explicit verdict.
1. Add the reviewer checklist and comment taxonomy to review guidance.
1. Add agent-review guidance covering execution evidence and senior sign-off.
1. Pilot the process on a small number of active tasks.
1. Review pilot outcomes and adjust weak points before broader rollout.

## Definition of Done for Review

Review is complete only when:

- all blocking findings are resolved
- all relevant review tiers have been satisfied
- planning traceability is intact
- required ADRs are present
- evidence matches the risk of the change
- the reviewer can explain why the change is safe enough to merge
- the final verdict is explicit

If review ends with uncertainty that cannot be named, the review was not deep
enough.

## Open Questions

See [docs/open-questions.md](open-questions.md) for the consolidated
and deduplicated question backlog. Questions originating here are tracked as OQ-25,
OQ-26, OQ-27, OQ-28, OQ-32.
