# Implementation Proposal Analysis

## Purpose

This report compares the three implementation process proposals in:

- `docs/codex/implementation-proposal.md`
- `docs/claude/implementation-proposal.md`
- `docs/gemini/implementation-proposal.md`

The goal is to identify where they agree, where they differ, and which ideas
should carry forward into a final implementation standard.

## Executive Summary

All three proposals agree on the core operating model:

- implementation starts only from approved planning artifacts and ready tasks
- test-driven development is the default execution method
- Graphite stacked pull requests are the required review mechanism
- local validation must pass before work is submitted for review

The main differences are in emphasis:

- the `codex` proposal is the most process-balanced and governance-oriented
- the `claude` proposal is the most operationally strict and command-specific
- the `gemini` proposal is the most concise and approachable, but also the
  least complete

If the goal is a repository standard for both human and AI implementers, the
strongest foundation is the `codex` proposal, with selected operational detail
borrowed from `claude`.

## Areas of Agreement

All three documents align on the most important requirements.

### 1. TDD is mandatory or near-mandatory

Each proposal treats test-first development as a primary quality control:

- `codex` defines TDD as the default and requires explicit justification to
  skip it
- `claude` is stricter and treats a failing test as the entry condition for
  writing production code
- `gemini` states TDD is mandatory and structures the workflow around
  red-green-refactor

This is a strong point of consensus.

### 2. Work should be small and traceable

Each proposal reinforces that implementation should stay tightly scoped:

- one approved task should map to one branch and one PR
- changes should remain reviewable as small vertical slices
- commits and PRs should trace back to the task, plan, and spec

This is consistent with the repository's planning and tracking documents.

### 3. Graphite stacks are the review mechanism

All three proposals accept stacked PRs as a core part of implementation:

- `codex` frames Graphite as a transport for approved task decomposition
- `claude` ties stack frames directly to task dependency order
- `gemini` focuses on Graphite as the enabler of small dependent reviews

There is no substantive disagreement here.

### 4. Local validation is a hard pre-review gate

All three proposals reject opening review requests on unvalidated code:

- `codex` requires all task-relevant tests and checks to pass locally
- `claude` makes the full local test suite a hard gate
- `gemini` requires tests, lint, type checks, and build success before submit

The only real difference is how broad the required local validation should be.

## Key Differences

### 1. Strictness of the local test gate

This is the clearest substantive difference.

The `claude` proposal is the strictest:

- it requires the full local test suite before every PR submission
- it states there are no exceptions
- it treats failures caused by upstream work as blockers rather than allowing
  partially valid review requests

The `codex` proposal is slightly more flexible:

- it requires all task tests plus any broader subsystem checks required by the
  touched area
- it allows explicit exceptions for infrastructure constraints and unrelated
  repository-level failures

The `gemini` proposal sits between them:

- it requires a broad validation set
- it is clear about categories of checks
- it is less explicit about what happens when a full repository suite is
  impractical

Trade-off:

- `claude` maximizes review safety and predictability
- `codex` is more practical for large repositories or flaky environments
- `gemini` is directionally correct but under-specified for edge cases

### 2. Level of Graphite operational detail

The `claude` proposal is the most concrete:

- branch naming is specified
- `gt sync`, `gt restack`, and `gt pr create` are built into the workflow
- stack freshness and parent relationships are explicitly managed

The `gemini` proposal also includes commands, but it mixes `git` and `gt`
usage more loosely and is less precise about stack discipline.

The `codex` proposal intentionally stays at the policy level:

- it says what the stack must represent
- it avoids prescribing exact commands
- it focuses on review boundaries rather than CLI mechanics

Trade-off:

- `claude` is better as an operator playbook
- `codex` is better as a durable policy document
- `gemini` is useful for quick orientation but not as strong as a standard

### 3. Treatment of governance and ambiguity

The `codex` proposal is strongest here:

- it explicitly ties implementation back to approved tasks, planning, and ADRs
- it states that scope or architecture changes must return to planning
- it adds agent-specific requirements and an exception model

The `claude` proposal also respects planning boundaries, but it is more
focused on execution mechanics than governance structure.

The `gemini` proposal mentions traceability and architectural integrity, but it
does not define exception handling or decision-return rules in the same depth.

Trade-off:

- `codex` integrates best with the repository's planning and ADR rules
- `claude` is strong in execution discipline, weaker in exception design
- `gemini` is the least complete in governance terms

### 4. Quality of definition-of-done style gates

The `codex` proposal has the clearest gate model:

- explicit implementation gates
- explicit definition of done for implementation readiness
- explicit exception documentation requirements

The `claude` proposal has strong workflow constraints, but its gates are more
distributed throughout the procedure rather than consolidated into a reusable
policy model.

The `gemini` proposal has a compact gate summary, but it is lighter-weight and
less robust for handling non-happy-path cases.

### 5. Suitability for agents versus humans

The `codex` proposal is the most explicit about implementation agents:

- read task, plan, and ADRs first
- avoid speculative cleanup
- leave resumable notes
- optimize for traceability and small review surfaces

The `claude` proposal is strong for disciplined agents because it is highly
procedural, but it does not address handoff behavior or exception recording as
directly.

The `gemini` proposal reads well for humans onboarding into the process, but
it leaves more room for interpretation by agents.

## Strengths by Proposal

### `codex`

Best qualities:

- strongest alignment with planning and tracking governance
- clearest handling of ambiguity, scope change, and ADR boundaries
- best definition of required gates and implementation-ready conditions
- best explicit guidance for AI implementation agents

Primary weakness:

- less specific about daily Graphite operating commands

### `claude`

Best qualities:

- strongest operational discipline around TDD and stack management
- clearest command-level guidance for Graphite workflow
- strongest stance on full local validation before review

Primary weaknesses:

- less flexible for large or partially unstable repositories
- no-exceptions language may be too rigid in practice
- less explicit exception and handoff handling

### `gemini`

Best qualities:

- easiest to read quickly
- good concise explanation of red-green-refactor
- clear validation categories

Primary weaknesses:

- least complete on edge cases and governance
- weaker process detail around blocking conditions and replanning
- Graphite guidance is serviceable but not as rigorous as `claude`

## Recommendation

The best final process would use the `codex` proposal as the base document and
merge in selected operational specifics from `claude`.

Recommended combination:

- keep `codex` as the policy backbone
- add `claude`'s concrete Graphite operating steps such as `gt sync` and
  `gt restack`
- keep `codex`'s explicit exception handling rather than `claude`'s
  no-exceptions framing
- keep `codex`'s agent-specific rules and governance tie-ins
- optionally borrow `gemini`'s concise wording in places where the final
  document needs to be easier to scan

This combination would produce a standard that is:

- rigorous enough for agents
- practical enough for real repositories
- specific enough for everyday execution
- aligned with the existing planning, tracking, and ADR expectations

## Suggested Final Direction

The final implementation standard should explicitly require:

1. one approved task at a time
1. red-green-refactor as the default execution loop
1. one task to one branch to one stacked PR
1. Graphite stack order matching task dependency order
1. required local validation passing before review
1. return to planning or ADR creation when scope or architecture changes
1. resumable execution notes for agent-driven work

The main unresolved policy choice is this:

- whether "all tests pass locally" means the entire repository suite every
  time, or the full required validation set for the affected subsystem and task

If the repository is small and stable, `claude`'s full-suite rule is stronger.
If the repository is large, multi-language, or occasionally flaky, the
`codex` formulation is more sustainable.

## Conclusion

All three proposals are directionally aligned and compatible. The real choice
is not between competing process models, but between levels of strictness and
operational detail.

`codex` provides the best repository-standard document.
`claude` provides the best operator detail.
`gemini` provides the lightest presentation but the weakest policy coverage.

The strongest final process should therefore be a `codex`-led standard with
targeted `claude` workflow detail added where execution precision matters most.
