# Manual Agent Invocations — Gemini CLI

How to manually invoke each agent role in the delivery lifecycle using the
`gemini` CLI.

Gemini's large context window makes it best suited for analysis-heavy roles:
broad codebase comprehension, cross-file planning research, and multi-file code
review. For implementation and Linear write operations, use Codex or Claude CLI
instead. This document notes where Gemini is the right tool and where it is not.

Agent prompt files live in `.codex/agents/`. Pass them as inline context using
command substitution.

---

## Gemini CLI Conventions

All commands in this document follow these rules:

- Always pass `-p` for non-interactive headless execution.
- Default to `--approval-mode plan` for analysis and review tasks.
- Use `--approval-mode auto_edit` only when Gemini should write output files.
- Capture output with `> /tmp/gemini-<role>-<id>.md 2>&1` for later review.
- Prompts are fully self-contained — Gemini has no access to prior conversation
  context.
- Pass file and directory paths as positional arguments after the prompt.
- Use unique output files per concurrent invocation.

Verify Gemini is available before running:

```bash
gemini --version
gemini -p "Respond with: OK"
```

---

## Director

**Gemini fit**: Analysis and audit only. Gemini can survey Linear issue state
and produce a dispatch report, but cannot invoke other agents or write to
Linear. Use this to audit what the Director would dispatch before committing
to a full automated run.

**Precondition**: None.

```bash
gemini --approval-mode plan \
  -p "$(cat .codex/agents/director.md)

# Task
Audit the current state of the Agentic Harness delivery pipeline.

## Context
- Linear Project: Agentic Harness (Platform & Infra team)
- Delivery lifecycle defined in: docs/agentic-team.md
- Dispatch table and compliance gate rules are in your instructions above.

## Files to Analyze
docs/agentic-team.md
.codex/agents.toml

## Questions to Answer
1. Which issues are currently in each state (Triage, Backlog, Selected,
   In Progress, In Review, Blocked)?
2. For each non-Done, non-Blocked issue: which agent should the Director
   dispatch to it, and does it pass the compliance gate?
3. Are there any stale issues (no meaningful update in two working days)?
4. Are there any concurrency violations (multiple active agents on one issue)?

## Output Requirements
- One section per issue with: issue ID, current state, recommended dispatch,
  compliance gate result (pass/fail with specific reason if fail).
- Flag stale issues and concurrency violations separately.
- Do not dispatch agents or modify any issue." \
  docs/agentic-team.md .codex/agents.toml \
  > /tmp/gemini-director-audit.md 2>&1
```

**For Linear writes and actual dispatch**: use Codex or Claude CLI Director
invocations instead.

---

## Feature Draft Agent

**Gemini fit**: Not recommended. The Feature Draft Agent requires an
interactive intake conversation with a human stakeholder. Gemini is
non-interactive by design. Use Claude CLI (`claude --agent feature-draft`)
for this role.

---

## Architect

**Gemini fit**: Strong for the research and analysis phase of planning.
Gemini can analyze the full codebase, identify affected areas, surface
architectural constraints, and produce a planning brief that feeds into
`spec.md` and `plan.md` authoring. For the artifact writing and PR steps,
hand off to Codex or Claude CLI.

**Precondition**: Linear issue is in `Triage` state. Use this before or
alongside the Architect to front-load codebase analysis.

**Codebase analysis for planning:**

```bash
gemini --approval-mode plan \
  -p "$(cat .codex/agents/architect.md)

# Task
Produce a planning analysis for feature request: <ISSUE-TITLE>.

## Context
- Linear issue: <ISSUE-ID>
- Feature description: <PASTE ISSUE DESCRIPTION>
- Repository: archive-agentic

## Files to Analyze
docs/agentic-team.md
docs/
specs/
.codex/

## Questions to Answer
1. What parts of the existing codebase are affected by this feature?
2. What significant architectural decisions will need to be made?
3. What technical unknowns or risks should be resolved before planning?
4. What existing patterns or conventions should the plan follow?
5. Are there any ADRs already in docs/adr/ that are relevant?

## Output Requirements
- Affected areas with file references.
- List of architectural decisions requiring ADRs.
- List of technical unknowns to hand off to the Explorer.
- Suggested task decomposition approach (not a full tasks.md).
- Recommended change type: feature / bug fix / refactor / dependency update /
  architecture platform." \
  docs/ specs/ .codex/ \
  > /tmp/gemini-architect-<ISSUE-ID>.md 2>&1
```

**Cross-artifact consistency check (before opening plan PR):**

```bash
gemini --approval-mode plan \
  -p "# Task
Verify cross-artifact consistency across the planning bundle for feature
<###-feature-name>.

## Files to Analyze
specs/<###-feature-name>/spec.md
specs/<###-feature-name>/plan.md
specs/<###-feature-name>/tasks.md

## Questions to Answer
1. Does tasks.md cover every acceptance criterion in spec.md?
2. Does plan.md address every behavior defined in spec.md?
3. Are there any tasks in tasks.md that cannot be traced to spec.md or plan.md?
4. Are any tasks in tasks.md too large to fit in a single PR?
5. Are dependencies between tasks correctly captured?

## Output Requirements
- Pass / Fail verdict with specific findings.
- For each failure: which artifact, which section, what is inconsistent." \
  specs/<###-feature-name>/ \
  > /tmp/gemini-analyze-<###-feature-name>.md 2>&1
```

**For artifact authoring and PR steps**: use Codex or Claude CLI Architect
invocations.

---

## Coordinator

**Gemini fit**: Limited. The Coordinator's primary work is writing Linear
issues, which Gemini cannot do. Gemini can validate `tasks.md` structure and
produce the issue content as a draft for human or Codex review.

**tasks.md validation before Coordinator runs:**

```bash
gemini --approval-mode plan \
  -p "# Task
Validate tasks.md readiness for issue creation.

## Context
- Feature: <###-feature-name>
- The Coordinator will create one Linear issue per task in tasks.md.

## Files to Analyze
specs/<###-feature-name>/tasks.md
specs/<###-feature-name>/plan.md

## Questions to Answer
1. Does every task have a clear, unambiguous title suitable for a Linear issue?
2. Does every task have explicit acceptance criteria?
3. Does every task have explicit required tests?
4. Are dependency relationships between tasks clearly stated?
5. Is each task scoped to a single PR?
6. Are tasks.md and plan.md consistent with each other?

## Output Requirements
- Pass / Fail verdict.
- For each task: readiness assessment (ready / needs revision) with reason.
- List of any inconsistencies between tasks.md and plan.md." \
  specs/<###-feature-name>/ \
  > /tmp/gemini-coordinator-preflight-<###-feature-name>.md 2>&1
```

**For Linear issue creation**: use Codex or Claude CLI Coordinator invocations.

---

## Engineer

**Gemini fit**: Not recommended for implementation. The Engineer requires
write access to the repository (worktree creation, branching, test runs,
Graphite submission) and is TDD-driven. Use Codex CLI (`codex exec`) for
implementation.

Gemini is useful for pre-implementation analysis to help the Engineer
understand scope before writing code:

**Pre-implementation scope analysis:**

```bash
gemini --approval-mode plan \
  -p "# Task
Analyze the scope of implementation task <TASK-ID> before coding begins.

## Context
- Linear task: <TASK-ISSUE-ID>
- Task: <TASK TITLE AND DESCRIPTION>

## Files to Analyze
specs/<###-feature-name>/spec.md
specs/<###-feature-name>/plan.md
specs/<###-feature-name>/tasks.md

## Questions to Answer
1. Which existing files will this task need to modify?
2. Which existing tests will this task affect?
3. Are there any existing patterns or abstractions this task should follow?
4. Are there any non-goals in the spec that are easy to accidentally violate?
5. What is the minimal implementation surface to satisfy the acceptance criteria?

## Output Requirements
- File impact list with modification type (new / modify / delete).
- Test file list with expected change type.
- Patterns to follow with file references.
- Non-goal checklist." \
  specs/<###-feature-name>/ src/ tests/ \
  > /tmp/gemini-engineer-preflight-<TASK-ISSUE-ID>.md 2>&1
```

---

## Technical Lead

**Gemini fit**: Strong for code review. Gemini can hold the full diff, spec,
plan, and test suite in context simultaneously — which is the core challenge
of four-tier review. Use this to produce a structured review report, then
apply verdicts and Linear updates via Claude CLI or manually.

**Pre-flight check:**

```bash
gemini --approval-mode plan \
  -p "$(cat .codex/agents/technical-lead.md)

# Task
Run the pre-flight checklist for PR review of Linear task <TASK-ISSUE-ID>.

## Context
- PR branch: <BRANCH-NAME>
- Spec: specs/<###-feature-name>/spec.md
- Plan: specs/<###-feature-name>/plan.md
- Tasks: specs/<###-feature-name>/tasks.md

## Questions to Answer
1. Does the PR map to exactly one approved task?
2. Does the PR description link spec.md, plan.md, tasks.md, and the Linear issue?
3. Is validation evidence attached or linked?
4. Are there any undocumented architectural decisions in the diff?

## Output Requirements
- Pass / Fail for each pre-flight item.
- If any item fails: stop. List what is missing. Do not proceed to deep review." \
  specs/<###-feature-name>/ \
  > /tmp/gemini-tech-lead-preflight-<TASK-ISSUE-ID>.md 2>&1
```

**Full four-tier review:**

```bash
gemini --approval-mode plan \
  -p "$(cat .codex/agents/technical-lead.md)

# Task
Perform a four-tier code review for Linear task <TASK-ISSUE-ID>.

## Context
- PR branch: <BRANCH-NAME>
- Spec: specs/<###-feature-name>/spec.md
- Plan: specs/<###-feature-name>/plan.md
- Tasks: specs/<###-feature-name>/tasks.md
- Linear issue: <TASK-ISSUE-ID>

## Files to Analyze
specs/<###-feature-name>/
src/
tests/
docs/adr/

## Review Instructions
Run all four tiers in order. For each finding use the comment taxonomy:
  blocking: / question: / suggestion: / note:

## Output Requirements
- Tier 1 result: build, lint, type check, test, traceability.
- Tier 2 result: implementation vs spec.md and plan.md fidelity.
- Tier 3 result: architectural integrity, ADR coverage, no avoidable debt.
- Tier 4 result: naming, clarity, diagnostics.
- Final verdict: approve / revise / reject with justification.
- Ordered findings list with file:line references and taxonomy prefixes.
- Flag any high-risk changes (auth, persistence, migration, distributed
  workflows, architectural boundaries) for human escalation." \
  specs/<###-feature-name>/ src/ tests/ docs/adr/ \
  > /tmp/gemini-tech-lead-review-<TASK-ISSUE-ID>.md 2>&1
```

**For applying verdict, posting review comments, and updating Linear**: use
Claude CLI or manually update the PR and issue using the report as input.

---

## Explorer

**Gemini fit**: Excellent. The Explorer role is a direct match for Gemini's
strengths — large-context research across many files and external sources,
with structured output and source citations. Prefer Gemini for Explorer
invocations over other CLIs.

**For feature-scoped research (writes to `specs/`):**

```bash
gemini --approval-mode auto_edit \
  -p "$(cat .codex/agents/explorer.md)

# Task
Resolve technical unknowns blocking planning for feature <###-feature-name>.

## Context
- Repository: archive-agentic
- Feature: <ISSUE-TITLE>
- Audience: Architect planning this feature

## Files to Analyze
docs/
specs/
.codex/
src/

## Unknowns to Resolve
1. <Specific question 1>
2. <Specific question 2>
3. <Specific question 3>

## Output Requirements
Write the research report to specs/<###-feature-name>/research.md using
exactly this structure:
  ## Problem
  ## Constraints
  ## Affected Areas
  ## Unknowns Resolved
  ## Risks Identified
  ## Suggested Directions
  ## Sources

Every factual claim must include a source citation (file path or URL).
Mark speculation explicitly. Do not produce code patches or make architectural
decisions — flag those as decisions to be made." \
  docs/ specs/ src/ .codex/ \
  > /tmp/gemini-explorer-<###-feature-name>.md 2>&1
```

**For standalone research (not tied to a feature):**

```bash
gemini --approval-mode plan \
  -p "$(cat .codex/agents/explorer.md)

# Task
Research the following technical question.

## Problem
<Problem statement>

## Unknowns to Resolve
1. <Specific question 1>
2. <Specific question 2>

## Audience
<Who will use this research>

## Output Requirements
Produce a structured research report using exactly this structure:
  ## Problem
  ## Constraints
  ## Affected Areas
  ## Unknowns Resolved
  ## Risks Identified
  ## Suggested Directions
  ## Sources

Every factual claim must include a source citation. Mark speculation
explicitly. Do not produce code patches or make architectural decisions." \
  docs/ src/ \
  > /tmp/gemini-explorer-standalone.md 2>&1
```

---

## Parallel Analysis Runs

When multiple analysis tasks are independent, run them simultaneously with
unique output files:

```bash
gemini --approval-mode plan \
  -p "Analyze affected areas and architectural risks for: <FEATURE-A>" \
  docs/ src/ specs/<feature-a>/ \
  > /tmp/gemini-architect-feature-a.md 2>&1 &

gemini --approval-mode plan \
  -p "Analyze affected areas and architectural risks for: <FEATURE-B>" \
  docs/ src/ specs/<feature-b>/ \
  > /tmp/gemini-architect-feature-b.md 2>&1 &

wait
cat /tmp/gemini-architect-feature-a.md
cat /tmp/gemini-architect-feature-b.md
```

---

## Output Validation

Gemini output is advisory analysis. Before acting on results:

1. Verify every cited file path exists: `ls <path>`
2. Confirm referenced symbols exist: `grep -r "<symbol>" src/`
3. Separate verified facts from hypotheses in the output
4. Rerun with a tighter prompt if claims are vague or ungrounded:

```bash
gemini --approval-mode plan \
  -p "Re-run with strict grounding:
- cite concrete file paths for every claim
- mark any unknowns explicitly as UNKNOWN
- do not infer the existence of files you have not seen" \
  <same paths as original run> \
  > /tmp/gemini-retry.md 2>&1
```

---

## Quick Reference

| Agent | Gemini fit | Recommended use |
|---|---|---|
| Director | Audit only | Compliance gate audit; no dispatch or Linear writes |
| Feature Draft | Not recommended | Use `claude --agent feature-draft` (interactive intake) |
| Architect | Strong (analysis) | Codebase analysis, planning brief, artifact consistency check |
| Coordinator | Limited (validation) | tasks.md readiness check before Codex/Claude runs |
| Engineer | Pre-flight analysis only | Scope and impact analysis before Codex implements |
| Technical Lead | Strong (review) | Four-tier review report; apply verdict via Claude CLI |
| Explorer | Excellent | Primary tool — large-context research and source citations |

## Human Gates

Gemini produces analysis reports only. All state transitions, Linear writes,
PR submissions, and approvals must be performed by Codex CLI, Claude CLI,
or a human directly.

| Gate | Action after Gemini report |
|---|---|
| T-3 plan PR approval | Human reviews plan PR and merges in GitHub |
| Tech Lead verdict | Apply `approve`/`revise`/`reject` via Claude CLI or manually |
| High-risk escalation | Senior human reviewer acts on Gemini's escalation flag |
| Feature Draft confirmation | Human confirms draft; use Claude CLI to write to Linear |
