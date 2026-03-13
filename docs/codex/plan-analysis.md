# Review Proposal Comparison

## Scope

This report compares the three agent-authored review documents in `docs/`:

- `docs/codex/review-proposal.md`
- `docs/claude/review-proposal.md`
- `docs/gemini/review-process.md`

The Gemini document is the third review proposal, even though its filename is
`review-process.md` rather than `review-proposal.md`.

## Executive Summary

There are two distinct proposals, not three:

- Codex and Claude propose the same review model, with only trivial editorial
  differences.
- Gemini proposes a materially different review model built around a
  four-tiered "Torvalds Standard."

The Codex/Claude proposal is broader, more operational, and better specified
as a reusable process document. The Gemini proposal is sharper in tone,
stricter in philosophy, and more prescriptive about agent behavior, but it is
 narrower in scope and less complete as an end-to-end operating process.

## Shared Themes Across All Three

All three documents agree on the core intent of review:

- Review is a real quality gate, not a ceremonial approval step.
- Traceability back to planning artifacts is required.
- Small, focused PRs are easier to review correctly.
- Correctness, maintainability, and long-term code health matter more than
  merge speed.
- Reviewers should block changes when confidence is insufficient.
- Agent-authored changes need especially disciplined review.

That alignment matters. Even where the documents differ in structure and tone,
they converge on a high-rigor review culture.

## Codex and Claude

Codex and Claude are effectively the same proposal. A direct diff shows only
minor capitalization differences in the "Review Depth by Change Type" section:

- `Low-risk Change` vs. `Low-risk change`
- `Standard Change` vs. `Standard change`
- `High-risk Change` vs. `High-risk change`

Substantively, they recommend the same things:

- explicit review inputs and preconditions
- clearly defined author, reviewer, and reviewing-agent roles
- a three-state verdict model: `reject`, `revise`, `approve`
- a stepwise workflow from intake through re-review
- required review lenses such as correctness, architecture, tests, operability,
  and maintainability
- structured finding taxonomy and blocker criteria
- depth calibrated by change risk
- escalation rules, service levels, metrics, calibration, and adoption steps

This proposal reads like a full operating manual for a review process. It is
strong on auditability, repeatability, and integration with the repo's
artifact-driven workflow.

## Gemini

Gemini proposes a different model titled "The Torvalds Standard." Its main
features are:

- a four-tier lifecycle: automated validation, implementation fidelity,
  architectural integrity, and final polish
- a stronger emphasis on blunt technical gatekeeping and rejection of
  "good enough" work
- explicit requirement for TDD evidence in execution logs
- explicit agent-to-agent peer review before human review
- a stronger requirement that final architectural review be performed by a
  human or specialized senior agent
- a simpler approval checklist and a short list of next adoption steps

Gemini is more opinionated and culturally forceful. It is easier to skim and
may be easier to operationalize as a reviewer checklist. It is also more
normative than procedural: it says what standard to uphold, but gives less
detail about how the review system should operate day to day.

## Compare and Contrast

### Process Design

Codex/Claude define a comprehensive review system. They specify inputs,
workflow stages, outputs, comment taxonomy, escalation, service levels, and
metrics.

Gemini defines a review doctrine. Its four tiers are clear, but it omits much
of the operational detail that Codex/Claude provide, such as comment taxonomy,
explicit review states beyond approval, calibration loops, and service-level
targets.

### Tone and Culture

Codex/Claude are strict but institutional. The tone is sober, procedural, and
designed for consistency across humans and agents.

Gemini is intentionally sharper. The "Torvalds Standard" framing makes the
document feel more confrontational and less neutral. That may reinforce rigor,
but it may also create avoidable friction if adopted literally.

### Agent Review Expectations

Codex/Claude treat agents as strict reviewers who must inspect context,
adjacent code, and validation evidence, then produce findings with file/line
references.

Gemini goes further in a few places:

- it asks reviewers to inspect agent execution logs
- it expects evidence of a failing test before implementation
- it calls for agent peer review before human review
- it reserves final architectural sign-off for a human or specialized senior
  agent

These are concrete and useful additions, especially in an agent-heavy
workflow.

### Completeness

Codex/Claude are more complete as canonical process documentation. They cover:

- preconditions before review starts
- how to classify comments
- what blocks approval
- how review depth should scale with risk
- when to escalate
- how quickly review should happen
- how to measure and calibrate the process

Gemini does not cover these areas with the same completeness. It is better read
as a strong supplement or philosophy layer than as a full replacement.

### Strengths

Codex/Claude strengths:

- comprehensive and operational
- easy to translate into PR templates and agent prompts
- stronger support for auditability and governance
- better aligned with existing `spec.md` / `plan.md` / `tasks.md` workflows

Gemini strengths:

- memorable framing
- stronger emphasis on architectural scrutiny
- more explicit expectations for agent-produced work
- concise enough to function as a practical checklist

### Weaknesses

Codex/Claude weaknesses:

- longer and heavier
- somewhat bureaucratic if applied to every low-risk change without judgment
- less vivid on agent-specific concerns than Gemini

Gemini weaknesses:

- less complete as an operating process
- tone may over-index on harshness rather than precision
- some expectations, such as proof of TDD via execution logs, may be too rigid
  to apply universally
- lacks the stronger governance mechanics present in Codex/Claude

## Recommendation

The strongest path is to use the Codex/Claude proposal as the canonical review
process and selectively incorporate Gemini's best ideas.

Specifically, keep the Codex/Claude structure for:

- review states
- finding taxonomy
- blocker definitions
- escalation rules
- service levels
- metrics and calibration

Then pull in these Gemini elements:

- the four-tier framing as a reviewer mental model
- stronger scrutiny of agent execution logs
- explicit requirement for senior review of architectural changes
- clearer guidance that agent-generated work should receive specialized review

## Bottom Line

Codex and Claude recommend the same review system. Gemini recommends a
different but compatible philosophy that is stricter in tone and more explicit
about agent review mechanics. If one proposal must be chosen as the base,
Codex/Claude is the better foundation. Gemini is most useful as a supplement
that sharpens agent-review expectations and architectural discipline.
