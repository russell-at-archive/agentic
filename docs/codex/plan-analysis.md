# Plan Analysis

## Summary

The three planning documents in `docs/` share the same core recommendation:
use a spec-driven workflow that resolves ambiguity before implementation,
separates product intent from engineering design, decomposes work into small
tasks, and implements only after planning artifacts are complete.

They diverge in rigor, specificity, and governance.

## Shared Recommendations

All three documents recommend the same backbone:

- clarify the problem before committing to implementation
- write a feature specification before code
- derive a technical plan from the approved specification
- decompose the plan into small, testable tasks
- implement against the approved artifacts instead of improvising

They also all assume the repository should use the Speckit workflow already
present in `.specify/`, even though they differ in how explicitly they tie the
process to Speckit commands.

## Comparison

### Codex

The Codex document is the strongest on governance and execution discipline.
It introduces:

- intake and change classification by type
- planning depth based on change type
- explicit approval gates before implementation
- traceability from pull request back to spec, plan, and task
- a required testing matrix in each plan
- explicit ADR trigger conditions

Its strongest recommendations are the hard gates and test expectations in
[planning-process.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/planning-process.md).

Its main weakness is ADR scope. It says ADRs are required only for
cross-cutting architectural changes, which is narrower than the repository-wide
mandate in `~/.agents/AGENTS.md` that all significant architectural decisions
must be recorded as ADRs.

### Claude

The Claude document is the most operational and the most tightly aligned to the
existing Speckit toolchain. It is the strongest guide for how a team would
actually run the process day to day.

It adds:

- a command-by-command mapping of the Speckit lifecycle
- concrete artifact expectations beyond `spec.md`, `plan.md`, and `tasks.md`
- entry conditions and quality gates for each stage
- explicit risk management and open questions
- an MVP checkpoint before lower-priority work continues

Its strongest recommendation is treating the Constitution as a prerequisite for
the workflow, since that makes Speckit's Constitution Check meaningful.

Its main weakness is that it is less explicit than Codex on intake,
classification, review traceability, and repo-wide governance policy.

### Gemini

The Gemini document is the clearest high-level explanation of spec-driven
development and why it works well with AI agents.

It adds:

- the most accessible explanation of the philosophy
- a simple explanation of the "what" versus the "how"
- a good framing of why planning reduces hallucination and rework

Its main weakness is that it is too lightweight to serve as the canonical
repository process. It does not define enforceable gates, owners, approval
rules, ADR policy, or concrete quality thresholds.

## Contrast by Dimension

### Operational detail

- Claude is the most concrete and executable.
- Codex is moderately concrete and process-oriented.
- Gemini is the least concrete and mostly explanatory.

### Governance and policy

- Codex is the strongest.
- Claude is moderate.
- Gemini is minimal.

### Speckit alignment

- Claude is the strongest fit to the current toolchain.
- Gemini references Speckit clearly but at a lighter level.
- Codex assumes the same workflow but is less command-specific.

### Onboarding value

- Gemini is the easiest for a new reader to understand.
- Claude is strong once a reader is ready to operate the workflow.
- Codex is best for maintainers defining enforcement.

## Overall Assessment

If one document were chosen as the base for the repository process, Claude's is
the best operational starting point because it aligns most closely with the
existing Speckit workflow and defines stage-by-stage quality gates.

Codex contributes the most valuable governance additions:

- intake and classification
- review traceability
- explicit testing expectations
- stronger approval gates

Gemini should be treated as supporting material rather than the canonical
process. It is useful as an introduction, but not sufficient as an enforceable
standard.

## Recommended Synthesis

The strongest final process would combine:

- Claude's command-level and artifact-level workflow
- Codex's intake, approval, testing, and review controls
- Gemini's short introductory framing for onboarding

That combined version should also correct ADR policy to match the repository
mandate: significant architectural decisions require ADRs, not only
cross-cutting ones.
