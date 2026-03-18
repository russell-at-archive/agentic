# Manual Agent Invocations — Claude CLI

How to manually invoke each agent in the delivery lifecycle using the `claude`
CLI, replicating the same dispatch logic the Director uses automatically.

Agents are defined as project subagents in `.claude/agents/`. Claude Code
selects them automatically based on their `description` field. You can target
a specific agent explicitly by naming it in your prompt.

---

## Invocation Modes

### From the shell (new session)

Use `--agent` to target a specific subagent and `-p` to pass a prompt
non-interactively:

```bash
claude --agent <name> -p "<prompt>"
```

### Within an active session

Type the prompt directly. Claude will select and dispatch the appropriate
subagent. Name the agent explicitly to force a specific one:

```
Use the <agent-name> agent to <task description>.
```

The sections below show both forms for each agent.

---

## Director

**Purpose**: Poll Linear, run the compliance gate, and dispatch specialist
agents.

**Precondition**: None. The Director monitors all non-`Done`, non-`Blocked`
issues.

**Shell:**

```bash
claude --agent director -p \
  "Poll Linear for open issues in the Agentic Harness project and dispatch
   the appropriate agent for each issue based on its current state."
```

**In session:**

```
Use the director agent to poll Linear for open issues in the Agentic Harness
project and dispatch the appropriate agent for each issue based on its current
state.
```

---

## Feature Draft Agent

**Purpose**: Convert a raw human request into a planning-ready `Triage`
Linear issue via a structured intake conversation.

**Precondition**: No `Triage` issue exists for this request. Human-invoked
only — the Director never dispatches this agent.

The agent runs a three-pass intake (`Context` → `Task` → `Refine`) and
confirms the draft with you before writing to Linear. Run interactively.

**Shell:**

```bash
claude --agent feature-draft
```

**In session:**

```
Use the feature-draft agent. I have a new request I need turned into a
Triage issue: <describe your raw request here>.
```

The agent will ask clarifying questions before presenting the draft.

**Human gate**: Confirm the draft before the `Triage` issue is created.

---

## Architect

**Purpose**: Transform a `Triage` issue into approved planning artifacts
(`spec.md`, `plan.md`, `tasks.md`) and open a plan PR.

**Precondition**: Linear issue is in `Triage` state with no `planning` label.

**Shell:**

```bash
claude --agent architect -p \
  "Process Linear issue <ISSUE-ID>. The issue is in Triage state.
   Confirm the objective, add the planning label, produce spec.md, plan.md,
   and tasks.md in specs/<###-feature-name>/, run /speckit.analyze, open
   a plan PR titled 'plan: [Feature Name] planning artifacts', then move
   the issue to In Review with the plan label."
```

**In session:**

```
Use the architect agent to process Linear issue <ISSUE-ID>. The issue is in
Triage state. Confirm the objective, add the planning label, produce spec.md,
plan.md, and tasks.md in specs/<###-feature-name>/, run /speckit.analyze,
open a plan PR titled "plan: [Feature Name] planning artifacts", then move
the issue to In Review with the plan label.
```

**What happens**:

1. Adds `planning` label
2. Produces `specs/<###-feature-name>/spec.md`, `plan.md`, `tasks.md`
3. Invokes the `explorer` subagent if technical unknowns block planning
4. Runs `/speckit.analyze`
5. Opens plan PR
6. Moves issue to `In Review` + `plan` label, removes `planning` label

**Human gate (T-3)**: Review and merge the plan PR. Merging advances the issue
to `Backlog`.

---

## Coordinator

**Purpose**: Read `tasks.md` and create one Linear child issue per task with
correct dependency links and states.

**Precondition**: Parent feature issue is in `Backlog`; plan PR is merged.

**Shell:**

```bash
claude --agent coordinator -p \
  "Process Linear issue <ISSUE-ID>. The issue is in Backlog state with the
   plan PR merged. Read specs/<###-feature-name>/tasks.md, confirm it is
   consistent with plan.md, then create one Linear child issue per task
   using the title format '[T-##] [Feature Name] Short description'.
   Set dependency-free tasks to Selected; leave dependent tasks in Backlog."
```

**In session:**

```
Use the coordinator agent to process Linear issue <ISSUE-ID>. The issue is in
Backlog state and the plan PR has been merged. Read
specs/<###-feature-name>/tasks.md, confirm it is consistent with plan.md,
then create one Linear child issue per task using the title format
"[T-##] [Feature Name] Short description". Set dependency-free tasks to
Selected; leave dependent tasks in Backlog.
```

**What happens**: Creates child issues populated with task ID, artifact links,
dependency references, acceptance criteria summary, and required tests summary.
Dependency-free tasks are set to `Selected`.

---

## Engineer

**Purpose**: Implement exactly one approved task using TDD, then open a
Graphite PR.

**Precondition**: Task issue is in `Selected`; all upstream dependencies are
`Done`.

**Shell:**

```bash
claude --agent engineer -p \
  "Implement Linear task issue <TASK-ISSUE-ID>. The issue is in Selected
   state and all upstream dependencies are Done. Run the pre-flight
   checklist, create a git worktree, implement using TDD per acceptance
   criteria, run the full validation pass (make validate), open the PR
   with 'gt submit --stack', and move the issue to In Review."
```

**In session:**

```
Use the engineer agent to implement Linear task issue <TASK-ISSUE-ID>. The
issue is in Selected state and all upstream dependencies are Done. Run the
pre-flight checklist, create a git worktree, implement using TDD per
acceptance criteria, run make validate, open the PR with gt submit --stack,
and move the issue to In Review.
```

**What happens**:

1. Self-assigns and moves issue to `In Progress`
2. Creates git worktree and branch: `<linear-id>-t-<##>-<short-slug>`
3. Writes failing tests per acceptance criterion, then implementation
4. Runs `make validate` — hard gate, must pass before PR opens
5. Runs `gt submit --stack`
6. Writes PR description with traceability links and validation output
7. Moves issue to `In Review`

**One task per invocation.** Never name multiple task IDs.

---

## Technical Lead

**Purpose**: Run four-tier code review and issue a merge verdict.

**Precondition**: Task issue is in `In Review` with **no** `plan` label.
(`In Review` + `plan` label is a human plan-review gate — do not invoke the
Technical Lead for those.)

**Shell:**

```bash
claude --agent tech-lead -p \
  "Review Linear issue <TASK-ISSUE-ID>. The issue is In Review with a
   Graphite PR stack published. Run the pre-flight checklist, then all
   four review tiers, and issue a verdict of approve, revise, or reject."
```

**In session:**

```
Use the tech-lead agent to review Linear issue <TASK-ISSUE-ID>. The issue is
In Review and a Graphite PR stack has been published. Run the pre-flight
checklist, then all four review tiers, and issue a verdict of approve,
revise, or reject.
```

**What happens**:

- Pre-flight: PR maps to one task; description links spec, plan, tasks, Linear
  issue; validation evidence present; no undocumented architectural decisions.
- Tier 1 — Automated Validation: build, lint, type checks, tests pass.
- Tier 2 — Implementation Fidelity: matches `spec.md` and `plan.md`.
- Tier 3 — Architectural Integrity: abstractions, ADRs, no avoidable debt.
- Tier 4 — Final Polish: naming, clarity, diagnostics.

**Verdicts**:

- `approve` → PR merges; issue moves to `Done`; Director confirms rollup.
- `revise` → issue returns to `In Progress`; Engineer addresses findings.
- `reject` → issue returns to `In Progress`; Engineer restarts or escalates.

**High-risk changes** (auth, persistence, migration, distributed workflows,
architectural boundaries) must be escalated to a human reviewer.

---

## Explorer

**Purpose**: Resolve technical unknowns through source-backed research.
On-demand only — not state-driven.

All three inputs are required: problem statement, specific unknowns, and
target audience.

**Shell — feature-scoped (writes to `specs/`):**

```bash
claude --agent explorer -p \
  "Problem: <clear problem statement>.
   Unknowns: 1. <question one> 2. <question two> 3. <question three>.
   Audience: <who will use this research>.
   Write the report to specs/<###-feature-name>/research.md."
```

**Shell — standalone:**

```bash
claude --agent explorer -p \
  "Problem: <problem statement>.
   Unknowns: 1. <question one> 2. <question two>.
   Audience: <target audience>.
   Deliver the report as a standalone artifact and link it in Linear
   issue <ISSUE-ID>."
```

**In session — feature-scoped:**

```
Use the explorer agent. Problem: <clear problem statement>. Unknowns: 1.
<question one> 2. <question two> 3. <question three>. Audience: <who will use
this research>. Write the report to specs/<###-feature-name>/research.md.
```

**In session — standalone:**

```
Use the explorer agent. Problem: <problem statement>. Unknowns: 1. <question
one> 2. <question two>. Audience: <target audience>. Deliver the report as a
standalone artifact and link it in Linear issue <ISSUE-ID>.
```

**Output format**:

```
## Problem
## Constraints
## Affected Areas
## Unknowns Resolved
## Risks Identified
## Suggested Directions
## Sources
```

Every factual claim must have a source citation. The Explorer never writes
code, opens branches, or makes architectural decisions.

---

## Quick Reference

| Agent | Shell flag | In-session trigger | Trigger state |
|---|---|---|---|
| Director | `--agent director` | `Use the director agent to...` | any non-Done/non-Blocked |
| Feature Draft | `--agent feature-draft` | `Use the feature-draft agent...` | human-invoked |
| Architect | `--agent architect` | `Use the architect agent to process...` | `Triage` |
| Coordinator | `--agent coordinator` | `Use the coordinator agent to process...` | `Backlog` |
| Engineer | `--agent engineer` | `Use the engineer agent to implement...` | `Selected` |
| Technical Lead | `--agent tech-lead` | `Use the tech-lead agent to review...` | `In Review` (no `plan` label) |
| Explorer | `--agent explorer` | `Use the explorer agent. Problem:...` | on-demand |

## Human Gates

| Gate | Transition | Required Human Action |
|---|---|---|
| T-3 | `In Review + plan` → `Backlog` | Review and merge the plan PR |
| Feature Draft confirmation | Pre-`Triage` | Confirm draft before Linear write |
| Lock reconciliation | Stale lock recovery | Director requires explicit confirmation |
| High-risk PR approval | Tier 3 escalation | Senior reviewer approves instead of Tech Lead |
