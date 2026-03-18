# Manual Agent Invocations — Codex CLI

How to manually invoke each agent in the delivery lifecycle using the `codex`
CLI, replicating the same dispatch logic the Director uses automatically.

Agent prompt files live in `.codex/agents/`. The team definition, dispatch
rules, and quality gates are in `.codex/agents.toml`. The default agent is the
Director.

---

## Invocation Modes

### Non-interactive (new session, `codex exec`)

Fully self-contained. Prepend the agent's prompt file to embed its role
instructions. Capture output with `-o`:

```bash
codex exec --full-auto -C . \
  -o /tmp/codex-<agent>-<id>.md \
  "$(cat .codex/agents/<agent>.md)

# Task
..."
```

### Interactive (new session, `codex`)

Starts an interactive session with the Director as the default agent (per
`default_agent = "director"` in `.codex/agents.toml`). Type prompts directly.
Name the target agent explicitly to direct dispatch:

```bash
codex --full-auto -C .
```

Then type at the prompt.

### Within an active session (`codex resume` or ongoing interactive)

Same as interactive. Codex has no memory between turns, so every prompt must
be fully self-contained — include the issue ID, current state, artifact paths,
and goal. Do not rely on prior session context.

The session already has the Director's instructions loaded. To target a
different agent, name it explicitly in your prompt or ask the Director to
dispatch to it.

Resume an interrupted session:

```bash
codex resume --full-auto -C .
```

---

## Director

**Purpose**: Poll Linear, run the compliance gate, and dispatch specialist
agents. The Director is the `default_agent` in `.codex/agents.toml`.

**Precondition**: None. The Director monitors all non-`Done`, non-`Blocked`
issues.

**Non-interactive:**

```bash
codex exec --full-auto -C . \
  -o /tmp/codex-director.md \
  "$(cat .codex/agents/director.md)

# Task
Poll Linear for open issues in the Agentic Harness project
(Project ID: 75a49856-5f94-4f00-8667-5b1f5795953e, Team: Platform & Infra).
For each issue not in Done or Blocked, run the compliance gate and dispatch
the appropriate agent per the dispatch table in your instructions."
```

Analysis-only (no dispatch, no writes):

```bash
codex exec --full-auto -C . -s read-only \
  -o /tmp/codex-director-audit.md \
  "$(cat .codex/agents/director.md)

# Task
Audit Linear for open issues in the Agentic Harness project. Report the
current state of each issue and which agent should be dispatched to it.
Do not dispatch any agents or modify any issues."
```

**In session:**

```
Poll Linear for open issues in the Agentic Harness project
(Project ID: 75a49856-5f94-4f00-8667-5b1f5795953e, Team: Platform & Infra).
For each issue not in Done or Blocked, run the compliance gate and dispatch
the appropriate agent per the dispatch table.
```

Analysis-only in session:

```
Audit Linear for open issues in the Agentic Harness project. Report the
current state of each issue and which agent should be dispatched based on the
dispatch table. Do not dispatch any agents or modify any issues.
```

---

## Feature Draft Agent

**Purpose**: Convert a raw human request into a planning-ready `Triage`
Linear issue.

**Precondition**: No `Triage` issue exists yet. Human-invoked only.

The Feature Draft Agent conducts a three-pass intake conversation
(`Context` → `Task` → `Refine`). Use interactive mode so you can respond.

**Non-interactive:**

```bash
codex --full-auto -C . \
  "$(cat .codex/agents/feature-draft.md)

# Task
A stakeholder has the following raw request:

<PASTE RAW REQUEST HERE>

Conduct the intake conversation, produce a Draft Design Prompt, present it
for confirmation, then create the Triage issue in Linear under the Agentic
Harness project."
```

**In session:**

```
Use the feature-draft agent role. A stakeholder has the following raw
request: <PASTE RAW REQUEST HERE>

Run the three-pass intake (Context, Task, Refine), produce a Draft Design
Prompt, present it to me for confirmation, then create the Triage issue in
Linear under the Agentic Harness project. Do not create the issue until I
confirm the draft.
```

**Human gate**: Confirm the draft before the `Triage` issue is created.

---

## Architect

**Purpose**: Transform a `Triage` issue into approved planning artifacts and
open a plan PR.

**Precondition**: Linear issue is in `Triage` state with no `planning` label.

**Non-interactive:**

```bash
codex exec --full-auto -C . \
  -o /tmp/codex-architect-<ISSUE-ID>.md \
  "$(cat .codex/agents/architect.md)

# Task
Process Linear issue <ISSUE-ID>. The issue is in Triage state.

## Context
- Repository root: $(pwd)
- Specs directory: specs/
- ADR directory: docs/adr/

## Goal
1. Confirm the issue has a defined objective.
2. Add the planning label to the issue.
3. Classify the change type.
4. Produce specs/<###-feature-name>/spec.md, plan.md, and tasks.md.
5. Invoke the explorer agent if technical unknowns block planning.
6. Run /speckit.analyze and block on failures.
7. Open a plan PR titled: plan: [Feature Name] planning artifacts
8. Move the issue to In Review with the plan label; remove the planning label.

## Constraints
- Do not begin implementation.
- Do not approve your own plan.
- Do not advance without spec.md, plan.md, tasks.md, and a passing analyze run.

## Validation
Confirm specs/<###-feature-name>/ contains spec.md, plan.md, and tasks.md
before opening the PR."
```

**In session:**

```
Dispatch the architect agent to process Linear issue <ISSUE-ID>. The issue
is in Triage state.

Goal:
1. Confirm the issue has a defined objective.
2. Add the planning label.
3. Classify the change type.
4. Produce specs/<###-feature-name>/spec.md, plan.md, and tasks.md.
5. Invoke the explorer agent if technical unknowns block planning.
6. Run /speckit.analyze and block on failures.
7. Open a plan PR titled: plan: [Feature Name] planning artifacts
8. Move the issue to In Review with the plan label; remove the planning label.

Constraints: do not begin implementation; do not approve your own plan; do
not advance without all three artifacts and a passing analyze run.
```

**Human gate (T-3)**: Review and merge the plan PR in GitHub. Merging advances
the issue to `Backlog`.

---

## Coordinator

**Purpose**: Read `tasks.md` and create one Linear child issue per task with
correct dependency links and states.

**Precondition**: Parent feature issue is in `Backlog`; plan PR is merged.

**Non-interactive:**

```bash
codex exec --full-auto -C . \
  -o /tmp/codex-coordinator-<ISSUE-ID>.md \
  "$(cat .codex/agents/coordinator.md)

# Task
Process Linear issue <ISSUE-ID>. The parent feature issue is in Backlog state
and the plan PR has been merged.

## Context
- Repository root: $(pwd)
- Tasks file: specs/<###-feature-name>/tasks.md
- Plan file: specs/<###-feature-name>/plan.md

## Goal
1. Read tasks.md. Confirm it exists and is consistent with plan.md.
2. Create one Linear issue per task with title format:
   [T-##] [Feature Name] Short task description
3. Populate each issue with: task ID, links to spec.md/plan.md/tasks.md,
   dependency references, acceptance criteria summary, required tests summary.
4. Set dependency-free tasks to Selected. Leave dependent tasks in Backlog.

## Constraints
- Do not create implementation code or branches.
- If tasks.md is missing or inconsistent with plan.md, move the parent issue
  to Blocked and document the gap. Do not create partial issue sets.

## Validation
Confirm all tasks from tasks.md have a corresponding Linear issue before
reporting completion."
```

**In session:**

```
Dispatch the coordinator agent to process Linear issue <ISSUE-ID>. The issue
is in Backlog state and the plan PR has been merged.

Tasks file: specs/<###-feature-name>/tasks.md
Plan file: specs/<###-feature-name>/plan.md

Goal:
1. Read tasks.md. Confirm it is consistent with plan.md.
2. Create one Linear issue per task: [T-##] [Feature Name] Short description
3. Populate each issue: task ID, artifact links, dependency references,
   acceptance criteria summary, required tests summary.
4. Set dependency-free tasks to Selected. Leave dependent tasks in Backlog.

If tasks.md is missing or inconsistent, move the parent to Blocked and stop.
Do not create partial issue sets.
```

---

## Engineer

**Purpose**: Implement exactly one approved task using TDD, then open a
Graphite PR.

**Precondition**: Task issue is in `Selected`; all upstream dependencies are
`Done`.

**Non-interactive:**

```bash
codex exec --full-auto -C . \
  -o /tmp/codex-engineer-<TASK-ISSUE-ID>.md \
  "$(cat .codex/agents/engineer.md)

# Task
Implement Linear task issue <TASK-ISSUE-ID>. The issue is in Selected state
and all upstream dependencies are Done.

## Context
- Repository root: $(pwd)
- Spec: specs/<###-feature-name>/spec.md
- Plan: specs/<###-feature-name>/plan.md
- Tasks: specs/<###-feature-name>/tasks.md
- Task ID: T-<##>

## Goal
1. Run the pre-flight checklist. Block and stop if any check fails.
2. Assign self to the issue. Move to In Progress.
3. Create a git worktree for isolated development.
4. Create branch: gt create <linear-id>-t-<##>-<short-slug>
5. For each acceptance criterion: write failing test, implement, refactor,
   run full test suite.
6. Run the full validation pass: make validate (all checks must pass).
7. Open the PR: gt submit --stack
8. Write PR description with traceability links and validation output.
9. Move the issue to In Review.

## Constraints
- One task per invocation. Do not implement across task boundaries.
- Do not submit a PR that has not passed the full validation pass.
- Do not expand scope silently — stop, document in Linear, move to Blocked.
- Write the failing test before writing production code.

## Validation
Run make validate. Confirm all checks pass before opening the PR."
```

**In session:**

```
Dispatch the engineer agent to implement Linear task issue <TASK-ISSUE-ID>.
The issue is in Selected state and all upstream dependencies are Done.

Spec: specs/<###-feature-name>/spec.md
Plan: specs/<###-feature-name>/plan.md
Tasks: specs/<###-feature-name>/tasks.md
Task ID: T-<##>

Goal:
1. Run the pre-flight checklist. Block and stop if any check fails.
2. Assign self and move to In Progress.
3. Create a git worktree and branch: gt create <linear-id>-t-<##>-<short-slug>
4. For each acceptance criterion: write failing test, implement, refactor,
   run full test suite.
5. Run make validate — all checks must pass.
6. Open the PR: gt submit --stack
7. Write PR description with traceability links and validation output.
8. Move the issue to In Review.

One task only. Write the failing test before production code.
```

**One task per invocation.** Never name multiple task IDs.

---

## Technical Lead

**Purpose**: Run four-tier code review and issue a merge verdict.

**Precondition**: Task issue is in `In Review` with **no** `plan` label.
(`In Review` + `plan` label is a human plan-review gate — do not invoke the
Technical Lead for those.)

**Non-interactive:**

```bash
codex exec --full-auto -C . -s read-only \
  -o /tmp/codex-tech-lead-<TASK-ISSUE-ID>.md \
  "$(cat .codex/agents/technical-lead.md)

# Task
Review Linear issue <TASK-ISSUE-ID>. The issue is In Review and a Graphite
PR stack has been published.

## Context
- Repository root: $(pwd)
- Spec: specs/<###-feature-name>/spec.md
- Plan: specs/<###-feature-name>/plan.md
- Tasks: specs/<###-feature-name>/tasks.md
- PR: <GRAPHITE-PR-URL>

## Goal
1. Run the pre-flight checklist. Return the PR without deep review if it fails.
2. Run all four review tiers in order.
3. Issue a verdict: approve, revise, or reject.
4. Post review comments using the taxonomy:
   blocking: / question: / suggestion: / note:
5. On approve: approve the PR in Graphite; move the issue to Done.
6. On revise/reject: return the issue to In Progress with findings documented.

## Constraints
- Do not approve with missing ADR linkage for significant decisions.
- Do not approve if any Tier 1 automated validation fails.
- Escalate high-risk changes (auth, persistence, migration, distributed
  workflows, architectural boundaries) — do not approve alone.

## Validation
Confirm verdict and issue state are updated in Linear before reporting done."
```

**In session:**

```
Dispatch the tech-lead agent to review Linear issue <TASK-ISSUE-ID>. The
issue is In Review and a Graphite PR stack has been published.

Spec: specs/<###-feature-name>/spec.md
Plan: specs/<###-feature-name>/plan.md
Tasks: specs/<###-feature-name>/tasks.md
PR: <GRAPHITE-PR-URL>

Goal:
1. Run the pre-flight checklist. Return the PR without deep review if it fails.
2. Run all four review tiers in order.
3. Issue a verdict: approve, revise, or reject.
4. Post review comments: blocking: / question: / suggestion: / note:
5. Approve: approve in Graphite, move issue to Done.
6. Revise/reject: return issue to In Progress with findings documented.

Do not approve with missing ADR linkage. Escalate high-risk changes.
```

---

## Explorer

**Purpose**: Resolve technical unknowns through source-backed research.
On-demand only — not state-driven.

**Precondition**: Provide all three required inputs: problem statement,
specific unknowns, and target audience.

**Non-interactive — feature-scoped (writes to `specs/`):**

```bash
codex exec --full-auto -C . --search \
  -o /tmp/codex-explorer-<###-feature-name>.md \
  "$(cat .codex/agents/explorer.md)

# Task
Resolve technical unknowns blocking planning for feature <###-feature-name>.

## Problem
<Clear statement of the problem being investigated>

## Unknowns
1. <Specific question 1>
2. <Specific question 2>
3. <Specific question 3>

## Audience
<Who will use this research — e.g., Architect planning the feature>

## Output
Write the research report to specs/<###-feature-name>/research.md using
the required output format (Problem, Constraints, Affected Areas, Unknowns
Resolved, Risks Identified, Suggested Directions, Sources).
Every factual claim must include a source citation."
```

**Non-interactive — standalone:**

```bash
codex exec --full-auto -C . --search \
  -o /tmp/codex-explorer-standalone.md \
  "$(cat .codex/agents/explorer.md)

# Task
Research the following technical question.

## Problem
<Problem statement>

## Unknowns
1. <Specific question 1>
2. <Specific question 2>

## Audience
<Target audience>

## Output
Deliver the report as a standalone artifact in /tmp/codex-explorer-standalone.md
and link it in Linear issue <ISSUE-ID>.
Every factual claim must include a source citation."
```

**In session — feature-scoped:**

```
Dispatch the explorer agent. Resolve technical unknowns blocking planning
for feature <###-feature-name>.

Problem: <clear problem statement>

Unknowns:
1. <Specific question 1>
2. <Specific question 2>
3. <Specific question 3>

Audience: <who will use this research>

Write the report to specs/<###-feature-name>/research.md using the required
format: Problem, Constraints, Affected Areas, Unknowns Resolved, Risks
Identified, Suggested Directions, Sources. Every factual claim must include
a source citation.
```

**In session — standalone:**

```
Dispatch the explorer agent. Research the following technical question.

Problem: <problem statement>

Unknowns:
1. <Specific question 1>
2. <Specific question 2>

Audience: <target audience>

Deliver a structured report using the format: Problem, Constraints, Affected
Areas, Unknowns Resolved, Risks Identified, Suggested Directions, Sources.
Link the report in Linear issue <ISSUE-ID>. Every factual claim must include
a source citation.
```

**The Explorer never writes code, opens branches, or makes architectural
decisions.**

---

## Sending Prompts via stdin

For long prompts, use stdin to avoid shell quoting issues:

```bash
cat <<'PROMPT' | codex exec --full-auto -C . -o /tmp/codex-output.md -
$(cat .codex/agents/architect.md)

# Task
Process Linear issue ARC-42. The issue is in Triage state.
[... rest of prompt ...]
PROMPT
```

---

## Parallel Dispatch

When dispatching independent tasks simultaneously, use unique output files:

```bash
codex exec --full-auto -C . \
  -o /tmp/codex-engineer-arc-10.md \
  "$(cat .codex/agents/engineer.md)

# Task
Implement Linear task issue ARC-10. ..." &

codex exec --full-auto -C . \
  -o /tmp/codex-engineer-arc-11.md \
  "$(cat .codex/agents/engineer.md)

# Task
Implement Linear task issue ARC-11. ..." &

wait
```

Only dispatch tasks with no shared dependencies in parallel.

---

## Resuming an Interrupted Session

If a Codex session is interrupted before completion:

```bash
codex exec resume --last --full-auto \
  -o /tmp/codex-resume-<TASK-ISSUE-ID>.md \
  "Continue the previous task. Check the Execution Log in Linear issue
   <TASK-ISSUE-ID> for the last completed step and resume from there.
   Write a final summary when done."
```

---

## Quick Reference

| Agent | Prompt file | Trigger state | In-session trigger |
|---|---|---|---|
| Director | `.codex/agents/director.md` | any non-Done/non-Blocked | `Poll Linear for open issues...` |
| Feature Draft | `.codex/agents/feature-draft.md` | human-invoked | `Use the feature-draft agent role...` |
| Architect | `.codex/agents/architect.md` | `Triage` | `Dispatch the architect agent to process...` |
| Coordinator | `.codex/agents/coordinator.md` | `Backlog` | `Dispatch the coordinator agent to process...` |
| Engineer | `.codex/agents/engineer.md` | `Selected` | `Dispatch the engineer agent to implement...` |
| Technical Lead | `.codex/agents/technical-lead.md` | `In Review` (no `plan` label) | `Dispatch the tech-lead agent to review...` |
| Explorer | `.codex/agents/explorer.md` | on-demand | `Dispatch the explorer agent. Problem:...` |

## Human Gates

| Gate | Transition | Required Human Action |
|---|---|---|
| T-3 | `In Review + plan` → `Backlog` | Review and merge the plan PR in GitHub |
| Feature Draft confirmation | Pre-`Triage` | Confirm draft before Linear write |
| Lock reconciliation | Stale lock recovery | Director requires explicit confirmation |
| High-risk PR approval | Tier 3 escalation | Senior reviewer approves instead of Tech Lead |
