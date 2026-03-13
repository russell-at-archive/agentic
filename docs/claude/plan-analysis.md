# Review Proposal Analysis

## Documents Reviewed

| Agent  | File                              |
|--------|-----------------------------------|
| Claude | `docs/claude/review-proposal.md`  |
| Codex  | `docs/codex/review-proposal.md`   |
| Gemini | `docs/gemini/review-process.md`   |

## Summary Finding

All three proposals are substantively identical. They share the same
philosophy, structure, workflow steps, role definitions, verdict model, comment
taxonomy, review lenses, blockers list, metrics, and adoption plan — word for
word in almost every section.

The proposals did not diverge. There is no meaningful contrast to draw between
them on content or approach.

## Observed Differences

### 1. File naming

The Gemini agent named its output `review-process.md` rather than
`review-proposal.md`. The content is otherwise identical to the Claude version.

### 2. Heading capitalization (Codex only)

In the "Review Depth by Change Type" section, the Codex proposal uses title
case for the three risk-level sub-headings while Claude and Gemini use sentence
case:

| Heading          | Claude / Gemini     | Codex               |
|------------------|---------------------|---------------------|
| Low-risk heading | `### Low-risk change` | `### Low-risk Change` |
| Standard heading | `### Standard change` | `### Standard Change` |
| High-risk heading | `### High-risk change` | `### High-risk Change` |

This is a formatting variance with no semantic significance.

## Shared Content (all three proposals)

Since the documents are effectively one document, the following describes what
all three agents agreed on:

### Philosophy

- Review is a quality gate, not a ceremony.
- Burden of clarity falls on the author.
- Unresolved risks block; they are never deferred.
- Optimize for long-term maintainability over merge velocity.

### Workflow (6 steps)

1. Intake check — verify preconditions before reading the diff.
2. Intent reconstruction — read spec, plan, tasks, and ADRs first.
3. Diff review — correctness, regressions, interfaces, security, naming.
4. Validation review — test adequacy proportionate to risk.
5. Verdict — `reject`, `revise`, or `approve`.
6. Re-review — re-check every blocking finding after author updates.

### Verdict Model

Three states only: `reject`, `revise`, `approve`. No partial approvals.

### Comment Taxonomy

Four prefixes: `blocking:`, `question:`, `suggestion:`, `note:`. Machine-readable
by design.

### Required Review Lenses

Scope control, correctness, architecture and design, test adequacy,
operability, maintainability.

### Risk Tiers

Three tiers (low-risk, standard, high-risk) with proportionate expectations.
High-risk changes require two reviewers, an ADR, and explicit failure mode
review.

### Agent Review Protocol

Fixed 8-step sequence. Findings lead; summary never leads.

### Escalation

Escalation targets defined for tech lead, product owner, and architecture
owner.

### Service Levels

- Standard PRs: first review within one business day.
- High-risk PRs: first review within two business days.
- Re-review: within one business day after substantive updates.

### Metrics

Turnaround time, rework rate, escaped defect rate, scope rejection rate,
no-finding approval rate, finding confirmation rate.

### Calibration

Recurring review of merged PRs to detect blind spots and upstream process
weaknesses.

### Adoption Plan

6-step pilot rollout ending with promotion to canonical `docs/` workflow set.

## Interpretation

The convergence is near-total. Three independent agents given the same prompt
produced the same document. This either reflects:

- a shared base document or prompt that was passed to all three agents, or
- strong convergence from a well-defined problem statement with little room for
  interpretation.

Either way, the convergence functions as validation: the proposal represents a
stable, coherent answer to the review process design problem. There are no
competing approaches to adjudicate.

## Recommendation

Since all three agents agreed, the proposal is ready to move forward without
needing to reconcile divergent views. The next step is adoption, not
arbitration. Pick the Claude or Codex version (they differ only in heading
capitalization) and promote it to the canonical `docs/` workflow set.

The Gemini file should be renamed to `review-proposal.md` for consistency with
the other agents' naming convention if it is promoted.
