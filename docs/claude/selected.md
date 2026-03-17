# Selection: Codex Merged Proposal

**Selected**: `docs/codex/merged.md`
**Date**: 2026-03-17

---

## Verdict

The Codex version is the strongest and most coherent of the three merged proposals.

---

## Analysis

### Gemini (`docs/gemini/merged.md`)

**Strengths:** Concise. The three-pass table is easy to scan. The success criteria
section is a readable summary.

**Fatal weaknesses:** At 79 lines, this is an executive brief, not a ratifiable
proposal. It doesn't make the hard decisions it's supposed to make:

- CTR third pass is named **"Result"** — inconsistent with the Architect's "Refine"
  vocabulary and therefore inconsistent with the system it proposes to join
- "9–12 questions" is a soft cap; the system rewards precision over flexibility
- The optional `Idea` state question is left open rather than decided — the merge was
  supposed to resolve this
- No tool access, no failure modes beyond a passing mention, no platform definitions, no
  execution log format, no open question IDs to cross-reference with `open-questions.md`
- Success criteria ("Architect reports reduced time spent") are process metrics that
  cannot be verified at ratification time

This document would need to be substantially expanded before it could be acted on.

---

### Claude (`docs/claude/merged.md`)

**Strengths:** Operationally complete. Tool access table, platform YAML, execution log
format, OQ IDs, acceptance criteria checklist, hard 9-question cap, a mandatory
verification gate, the CTR comparison table showing how the framework shifts from
engineering to product perspective.

**Weaknesses:**

- The design prompt template is over-specified. It defines seven subsections including
  "Suggested Research" (optional, yet listed) and "Intake Traceability" (useful, but
  makes the template feel bureaucratic). It also omits **"Risks"** as a named
  subsection — Codex catches this; Claude doesn't.
- There is no **Acceptance Signal** concept. "Success Criteria" is close but different.
  The stakeholder signing off on what done looks like is distinct from a list of
  criteria.
- The proposal ends on an Acceptance Criteria checklist rather than a Recommendation.
  A proposal should close with an explicit ask; this one doesn't.
- The "Impact on AGENTS.md" section shows the code block to paste in — that belongs in
  the implementation work, not the ratification document. It conflates the proposal
  (what and why) with the implementation spec (how).
- The tool access table and YAML frontmatter are implementation artifacts. Their
  presence makes the proposal feel like it's already implementing itself before it has
  been ratified.

---

### Codex (`docs/codex/merged.md`)

**Strengths:**

- The dedicated **"Why It Is Pre-Lifecycle, Not a New State"** section is the single
  best piece of writing across all three documents. No other version elevates this as a
  first-class design decision. It names the principle directly — "once an issue exists,
  state determines dispatch" — and explains clearly why adding a new state would
  undermine that without delivering equivalent value.
- **"Classification Contract"** and **"Linear Handoff Contract"** as section titles
  signal binding agreements between agents, not advisory suggestions. This language is
  appropriate for a system built on gate enforcement and strict role boundaries.
- The design prompt template includes **"Acceptance Signal"** as a mandatory field. This
  is the most important question the Drafter can ask — how will the stakeholder know
  this is done — and Codex is the only document that makes it structurally required
  rather than optional.
- The failure mode **"Intake drifts into solution design"** is named and handled. This
  is the most likely failure mode for any intake agent: the risk that it starts doing
  the Architect's job. Claude and Gemini don't name it.
- The **Recommendation** section closes with an explicit ask, as a proposal document
  should.
- The prose is authoritative and direct. "The recommended model is simpler:" followed
  by four tight bullets is more persuasive than paragraphs of hedged analysis.
- `/speckit.draft` is listed as an **open question**, not a decided output. This is
  intellectually honest — it correctly reads the boundary between what this proposal
  decides and what follows if it is accepted.

**Weaknesses:**

- No tool access table
- No platform-specific agent definition YAML
- No execution log entry format
- Open questions are prose bullets without IDs — harder to track against
  `open-questions.md`
- No model specification

---

## Defense

A proposal document has one job: make the key architectural decisions, define the role
boundaries, and give a ratifier enough to say yes or no. It is not an implementation
spec. The missing pieces in Codex — tool access, YAML, execution log format — all belong
in the agent definition files that the proposal's own follow-on changes list calls for.
Their absence keeps the proposal at the right level of abstraction. The Claude version
confuses the proposal with the implementation artifact it is calling for.

The Codex document also makes the one decision that matters most — no new Linear state,
pre-lifecycle as the architectural pattern, existing `Draft` as the output target — and
gives it its own section with a direct, principled argument. The other two documents
treat this as a footnote or an alternative to reject. Codex treats it as the spine of
the design, because it is.

The contract language is the other decisive factor. "Classification Contract" and
"Linear Handoff Contract" don't just describe what the agent does — they define what
other agents can depend on. That is the vocabulary of a system built on strict role
boundaries and gate enforcement. Gemini and Claude describe the same things with softer
language and lose the binding quality that makes the proposal actionable.

Finally, the Acceptance Signal in the design prompt template and the "intake drifts into
solution design" failure mode show that the Codex version was written by someone who
thought through how this agent fails, not just how it succeeds. In a system built on
compliance gates and evidence-based completion, that matters more than completeness of
operational detail.
