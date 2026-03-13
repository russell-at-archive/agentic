# Implementation Proposal Analysis

Three implementation proposals were produced independently by Claude
(`docs/claude/`), Gemini (`docs/gemini/`), and Codex (`docs/codex/`). This
report compares their approaches across the key decision areas and identifies
where the proposals agree, diverge, and where each has unique value.

---

## High-Level Character

| Dimension | Claude | Gemini | Codex |
| --- | --- | --- | --- |
| Tone | Prescriptive and operational | Concise and structured | Principled and pragmatic |
| Length | Longest; most detailed | Shortest; most scannable | Medium; most nuanced |
| Primary focus | Step-by-step execution | Lifecycle phases with commands | Principles and exception handling |
| Agent specificity | Dedicated agent protocol section | No agent/human distinction | Dedicated agent section |
| Exception handling | No exceptions stated | Not addressed | Explicit exceptions section |
| Open questions | Surfaced explicitly | Not surfaced | Not surfaced |

---

## Where All Three Agree

All three proposals share the same foundational commitments:

- **TDD is mandatory.** Every proposal opens with the red-green-refactor
  cycle as the implementation method, not an optional practice.
- **One task, one branch, one PR.** All three require a direct mapping
  between a planned task and a single reviewable unit of work.
- **Local tests must pass before review.** This is stated as a hard
  requirement in all three, not a recommendation.
- **Graphite stacked PRs are the review transport.** All three use Graphite
  to express task dependency order as a stack.
- **Scope changes return to planning.** None of the proposals allow an
  implementer to absorb scope changes during execution. All three require a
  return to planning artifacts when scope or architecture becomes unclear.
- **Traceability in the PR.** Every proposal requires the PR description to
  link back to the spec, plan, and task.

The core loop is identical across all three: confirm the task, write failing
tests, write minimum code, run tests locally, submit via Graphite.

---

## Where They Diverge

### TDD strictness

**Claude** is the most absolute. TDD has no stated escape hatch. The
requirement to confirm a test fails before writing production code is
described as a hard gate with no exceptions.

**Gemini** is also strict but frames TDD as the implementation method rather
than explicitly prohibiting exceptions. The absence of an exceptions section
implies zero tolerance without stating it.

**Codex** is the most pragmatic. It explicitly acknowledges that some changes
cannot be driven by automated tests (infrastructure, emergency fixes) and
requires that exceptions be documented — what rule was bypassed, why, the
risk introduced, and the follow-up action. For bug fixes specifically, Codex
requires a regression test "when technically feasible," which is a softer
requirement than the other two.

This is the most meaningful philosophical difference. Claude and Gemini treat
TDD as unconditional. Codex treats it as the default with a documented escape
hatch.

### Validation gate scope

**Claude** scopes the local gate to the test suite — tests must pass.

**Gemini** has the broadest gate: unit tests, integration/E2E tests, linting,
type checking, and a successful build must all pass locally before `gt
submit`.

**Codex** takes a middle position: all required tests plus lint, static
analysis, type checks, and contract checks required by the repository. Like
Gemini, it includes static analysis, but frames it as repository-defined
requirements rather than a fixed checklist.

This is a practical difference. Claude's gate could allow a PR with passing
tests but failing lint. Gemini's gate catches that; Codex's gate does too,
but defers to what the repository requires.

### Graphite CLI commands

**Claude** uses `gt branch create`, `gt sync`, `gt restack`, and `gt merge`.

**Gemini** uses `gt create` and `gt submit --no-edit --publish`, with `gt
restack` for rebasing. It also specifies `git checkout main && git pull`
before creating a branch.

**Codex** does not specify Graphite CLI commands at all. It describes the
behavior required (stack dependency order, small reviewable units) without
prescribing the exact commands.

The two proposals that specify commands use different command names for
branch creation and PR submission. This needs to be reconciled against the
actual Graphite CLI version in use before the process is adopted.

### Stack depth and discipline

**Claude** has the most explicit stack guidance. It defines when to stack
(upstream dependency exists) vs. when not to stack (independent tasks branch
from main), sets a soft limit of three to four stack frames, and specifies
bottom-up merge order.

**Codex** focuses on signals that a branch is too large rather than stack
depth, and emphasizes that Graphite is the review transport, not the planning
system — the stack should mirror approved task decomposition.

**Gemini** is minimal on stack discipline. It covers the basic `gt restack`
pattern for keeping stacks current but does not define when to stack or what
limits apply.

### PR title format

**Gemini** is the only proposal that specifies a PR title format: `[T-##]
<Task Title>`. Claude and Codex require the task ID in commits and PR
descriptions but do not specify title format.

### Agent protocol

**Claude** and **Codex** both have dedicated agent sections with specific
requirements beyond the human-implementer workflow. Claude requires failing
test output in the execution log before any production code commit, and
mandates execution log entries after each meaningful step. Codex requires
agents to read the approved task and linked ADRs before changing code, avoid
speculative cleanup, and leave resumable notes when blocked.

**Gemini** makes no distinction between human and agent implementers. It
applies the same process to both.

---

## Unique Contributions by Proposal

### Claude's unique contributions

- **Pre-implementation checklist.** An explicit, checkable list before code
  is written — confirming issue state, upstream dependencies, artifact
  review, and stack sync.
- **Restack before writing code.** Explicit requirement to `gt sync` and `gt
  restack` at the start of every session if the upstream has changed.
- **Stack size limit.** Soft cap of three to four frames with guidance on
  when to merge earlier frames before adding depth.
- **Open questions.** The only proposal to surface unanswered questions:
  canonical test command, coverage thresholds, stack naming conventions, and
  TDD policy for infrastructure tasks.

### Gemini's unique contributions

- **PR title format.** `[T-##] <Task Title>` as a required naming convention.
- **Build gate.** Includes a successful project build as a required local
  check, which neither other proposal requires.
- **Gate responsibility column.** The gate table names who owns each gate
  (implementer vs. reviewer), making accountability explicit.
- **Most scannable reference.** The compact structure makes it the most
  usable as a quick reference during execution.

### Codex's unique contributions

- **Exceptions framework.** The only proposal with a structured approach to
  rule exceptions. Exceptions are permitted but must document the bypassed
  rule, justification, risk, and follow-up action.
- **Definition of Done.** Explicit statement of what constitutes
  implementation complete (distinct from task fully closed after merge).
- **Stack signals.** Behavioral signals that indicate a branch is too large,
  rather than a fixed frame count limit.
- **Proposed Adoption section.** Explicitly states the intent to adopt this
  as the repository standard.

---

## Synthesis Recommendations

The three proposals are compatible. A merged process would draw:

**From all three (universal):** TDD red-green-refactor as the default, one
task per branch per PR, local tests pass before review, Graphite stacks
express dependency order, traceability in every PR.

**From Gemini:** Expand the local validation gate to include lint, type
checks, and build — not just tests. Add PR title format convention.

**From Codex:** Adopt the exceptions framework. TDD should be the default
with a documented escape hatch rather than a rule with no stated relief valve.
Add the Definition of Done and the stack size signals.

**From Claude:** Keep the pre-implementation checklist, the open questions
section, and the explicit stack depth guidance. Resolve the Graphite command
discrepancy against the installed CLI version before publishing the merged
process.

**Unresolved items that need a decision before adoption:**

1. Which Graphite CLI commands are correct — `gt create`/`gt submit` or `gt
   branch create`/`gt merge`?
2. Is TDD unconditional, or are documented exceptions permitted?
3. Does the local gate include build and lint, or tests only?
4. What is the canonical test command for this repository?
5. Is a coverage threshold part of the local gate?
