# Merge Proposal: ADR Backlog

## Purpose

This document compares the three existing ADR backlog proposals in
`docs/codex/`, `docs/claude/`, and `docs/gemini/`, then proposes a merged ADR
plan that preserves the strongest ideas from each.

The goal is not just to list ADRs, but to produce a coherent sequence that:

- matches the decisions already embedded in the repository docs
- distinguishes blockers from follow-on work
- avoids both over-fragmentation and under-specification

## Source Comparison

### Codex Proposal

Strongest ideas:

- best alignment with the repository's current documents and explicit ADR
  backlog
- strongest filename-ready numbering and ordering
- clear distinction between the minimum strict set and the fuller set required
  to cover all decisions already assumed by the docs
- good coverage of operational gaps that are strongly implied but not
  explicitly named

Weaknesses:

- treats some large decisions as separate ADRs even when they may be better
  grouped
- does not prioritize by implementation unblock value as clearly as the Claude
  version
- reads more like an inventory than a decision program

### Claude Proposal

Strongest ideas:

- best sequencing logic through tiers
- strongest distinction between "required before implementation" and "required
  before full autonomy"
- identifies several conceptual decisions that the docs already rely on but
  which the Codex proposal leaves implicit
- strongest articulation of methodology-level ADRs such as review model, CTR,
  and TDD

Weaknesses:

- some proposed ADRs are too fine-grained and may create unnecessary document
  overhead
- a few ADRs are better captured as part of broader workflow ADRs rather than
  standalone records
- numbering and titles are less directly usable as a repository file plan

### Gemini Proposal

Strongest ideas:

- clean thematic grouping into orchestration, security, workflow, and
  governance
- strongest mapping between ADRs and specific open questions
- appropriately emphasizes security, infrastructure, and PR traceability as
  first-class decisions

Weaknesses:

- too compressed to serve as the canonical merged plan on its own
- omits several repo-wide methodological decisions already assumed in the docs
- uses broader buckets that need more explicit sequencing

## Areas of Agreement

All three proposals converge on the following facts:

- the current docs assume architectural decisions that are not yet recorded in
  ADRs
- Director orchestration, failure policy, locking, auth, and AWS ownership all
  require ADRs
- the Feature Draft Agent decision requires ADR coverage
- the Linear state machine and workflow governance need explicit ratification
- ADR process and Constitution governance both need formalization

These shared points should be treated as the non-negotiable center of the
merged plan.

## Main Differences

### 1. Inventory vs. decision architecture

- Codex treats the backlog primarily as a document inventory.
- Claude treats it as a staged architecture program.
- Gemini treats it as a themed governance map.

Merged position:

Use Claude's staged architecture program as the organizing principle, Codex's
 filename-ready structure as the concrete output, and Gemini's thematic
grouping as a review aid.

### 2. Granularity of ADRs

- Claude proposes separate ADRs for some concepts that can reasonably be
  grouped, such as CTR, spec-driven planning, and compliance gate semantics.
- Codex groups more aggressively around major workflow decisions.
- Gemini sits in the middle.

Merged position:

Prefer one ADR per durable architectural boundary, not one ADR per sentence in
the docs. A good ADR should capture one coherent decision surface that is
likely to evolve as a unit.

That means:

- keep large structural decisions separate
- fold supporting mechanics into the ADR that governs them
- avoid splitting methodology into tiny fragments unless there is evidence the
  decisions will change independently

### 3. What is a blocker

- Claude is strongest here, with explicit tiers.
- Codex distinguishes "minimum strict set" from "full set".
- Gemini implies priority through grouping, but not as clearly.

Merged position:

Use explicit tiers:

- Tier 1: governance and operating-model blockers
- Tier 2: implementation blockers
- Tier 3: autonomy and infrastructure blockers
- Tier 4: important follow-on governance records

## Merged ADR Program

### Tier 1: Governance and Operating-Model Blockers

These should exist before the system is treated as a real architectural
standard.

#### 0001: Record Architectural Decisions

Define ADRs as the repository's architectural record, including location,
format, and append-only policy.

Why it stays:

- all three proposals require a meta-level ADR baseline
- the rest of the backlog is unstable until this exists

#### 0002: Adopt Agentic Team Operating Model

Ratify the multi-agent operating model in `docs/agentic-team.md`, including:

- role roster
- state-driven dispatch
- single-responsibility boundaries
- compliance gate expectations
- failure behavior

Why it stays:

- this is the broadest cross-cutting decision the docs already depend on
- Claude's "Seven-Agent Delivery Lifecycle" and Codex's "Adopt Agentic Team
  Operating Model" are the same underlying decision

#### 0003: Linear State Machine as Canonical Tracking Standard

Ratify Linear as the execution system of record and adopt the canonical state
machine and gate model.

Why it stays:

- Codex and Gemini are both right that this needs its own ADR
- Claude is right that the gate semantics are part of the same decision surface

Recommended scope:

- canonical state names
- gate transitions
- `Blocked` semantics
- Linear as source of truth for live execution state

#### 0004: Feature Draft Agent as Pre-Lifecycle Intake Exception

Ratify the Feature Draft Agent, the human-invoked pre-lifecycle exception, and
the no-new-state decision.

Why it stays:

- all three proposals agree this is a distinct architectural exception
- it should not be buried inside the broader team ADR

#### 0005: Spec-Driven Development and Planning Method

Ratify the spec-first development model and the planning artifact system,
including:

- specification as source of truth
- planning-before-implementation
- planning artifacts
- CTR as the canonical planning method

Why it stays:

- this merges the strongest parts of Claude's methodology ADRs with Codex's
  more practical grouping
- CTR should not be a standalone ADR unless it truly evolves independently from
  planning

### Tier 2: Implementation Blockers

These should exist before implementation is treated as production-grade.

#### 0006: Software Review and Merge Readiness Model

Ratify the review model, including:

- four-tier review
- verdict taxonomy
- blocker semantics
- traceability requirements

Why it stays:

- Claude is right that review is a major cross-cutting architectural choice
- Codex is right that this should be anchored to the review process as a whole

#### 0007: Graphite Stacked Pull Requests as Implementation Transport

Ratify Graphite stacks as the review and implementation transport, including:

- one task to one branch to one PR as the default
- stack order rules
- branch naming contract
- when to stack vs. split

Why it stays:

- all implementation flow docs rely on this decision
- Claude's stack-specific detail is stronger than the simpler Codex wording

#### 0008: Concurrency, Locking, and Worktree Management

Define:

- ticket locks
- branch namespace locks
- acquisition and release rules
- worktree creation and cleanup
- lock reconciliation and orphan recovery

Why it stays:

- Codex split this into two ADRs
- Gemini grouped parts of it
- Claude treated it as part of failure and implementation semantics

Merged decision:

Treat locking and worktree isolation as one decision surface because they are
operationally inseparable in this system.

#### 0009: Canonical Validation Command and Merge Gate Policy

Define:

- one standard local validation command
- local vs CI merge gate expectations
- who may grant exceptions and where they are recorded

Why it stays:

- Codex and Gemini both surfaced this as missing but necessary
- the current implementation and review docs already assume the decision exists

### Tier 3: Autonomy and Infrastructure Blockers

These are required before the system can operate autonomously at scale.

#### 0010: Director Invocation and Dispatch Strategy

Decide polling vs webhook vs hybrid dispatch for the Director.

Why it stays:

- all three proposals include it
- it directly affects runtime architecture and operating cost

#### 0011: Retry, Failure Recovery, and Escalation Policy

Define:

- retry bounds
- backoff strategy
- blocked-state escalation
- session crash recovery

Why it stays:

- Claude's failure-recovery framing is stronger than a generic retry ADR
- this should be broader than API retry alone

#### 0012: Progressive Task Promotion Mechanism

Define how dependency completion promotes downstream tasks from `Backlog` to
`Selected`.

Why it stays:

- explicit in the current docs
- sufficiently specific and automation-relevant to merit its own ADR

#### 0013: Agent Authentication and Secrets Management

Define how agents authenticate to Linear, GitHub, Graphite, AWS, and other
systems.

Why it stays:

- Gemini is especially strong here
- this is a clear security boundary, not just an implementation note

#### 0014: AWS Tool Scope and Agent Ownership

Define what AWS actions agents may perform and which role owns them.

Why it stays:

- explicit unresolved gap in current docs
- separate from auth and secrets because it governs authority and operational
  scope, not just credentials

#### 0015: Execution Substrate and Runtime Integration Model

Define the relationship between:

- Director orchestration
- runtime-specific agents
- Codex, Claude, and Gemini execution layers

Why it stays:

- Claude's "lifecycle" ADR and Codex's "Codex pipeline" ADR both point at the
  same deeper need
- the repo now has multiple runtime-specific agent definitions, so this is a
  real architectural concern

### Tier 4: Governance Completion ADRs

These are not immediate blockers, but the docs already depend on them
conceptually.

#### 0016: Constitution Governance and Minimum Contents

Define:

- who ratifies the Constitution
- required sections
- update process
- how Constitution exceptions are handled

Why it stays:

- strongly supported by Codex and Gemini
- the planning docs cannot be fully enforced without it

#### 0017: Pull Request Template and Traceability Standard

Define the required PR structure for:

- links to spec, plan, tasks, and Linear
- validation evidence
- deviation disclosure
- reviewer verdict recording

Why it stays:

- Gemini is right to elevate this as a governance artifact
- the review system assumes this structure already exists

## What Should Not Be Separate ADRs

To avoid over-fragmentation, the merged plan intentionally does not create
standalone ADRs for:

- CTR intake standards separate from planning methodology
- one-task-one-branch-one-PR separate from Graphite transport
- compliance gate semantics separate from the operating model
- ADR requirement policy separate from the foundational ADR adoption decision

These are important, but they fit better as scoped parts of the larger ADRs
listed above.

## Recommended Final Backlog

1. `0001-record-architectural-decisions.md`
2. `0002-adopt-agentic-team-operating-model.md`
3. `0003-linear-state-machine-as-canonical-tracking-standard.md`
4. `0004-feature-draft-agent-as-pre-lifecycle-intake-exception.md`
5. `0005-spec-driven-development-and-planning-method.md`
6. `0006-software-review-and-merge-readiness-model.md`
7. `0007-graphite-stacked-pull-requests-as-implementation-transport.md`
8. `0008-concurrency-locking-and-worktree-management.md`
9. `0009-canonical-validation-command-and-merge-gate-policy.md`
10. `0010-director-invocation-and-dispatch-strategy.md`
11. `0011-retry-failure-recovery-and-escalation-policy.md`
12. `0012-progressive-task-promotion-mechanism.md`
13. `0013-agent-authentication-and-secrets-management.md`
14. `0014-aws-tool-scope-and-agent-ownership.md`
15. `0015-execution-substrate-and-runtime-integration-model.md`
16. `0016-constitution-governance-and-minimum-contents.md`
17. `0017-pull-request-template-and-traceability-standard.md`

## Recommended Sequencing

### Before treating the docs as a ratified architecture

- `0001` through `0005`

### Before implementation at production quality

- `0006` through `0009`

### Before autonomous operation at scale

- `0010` through `0015`

### To complete governance coverage

- `0016` and `0017`

## Recommendation

Use the Codex proposal as the base inventory, the Claude proposal as the
sequencing model, and the Gemini proposal as the thematic governance check.

The merged result should be a 17-ADR program, not a 9-ADR minimum, because the
current docs already depend on more architectural decisions than the original
backlog explicitly named.
