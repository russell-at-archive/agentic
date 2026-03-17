# Codex Subagents

## Purpose

This document explains what Codex subagents are, how they actually behave, and
how to use them correctly in this repository.

The key distinction is:

- Codex subagents are short-lived delegated agent threads used to break a task
  into bounded pieces.
- The repository agents in `docs/agentic-team.md` are lifecycle roles in the
  delivery system, such as Director, Architect, Engineer, and Technical Lead.

Those are related ideas, but they are not the same mechanism.

## What a Codex subagent is

In Codex, a subagent workflow means the main agent spawns one or more child
agents to do specialized work in parallel, then collects and summarizes their
results in the parent thread.

OpenAI’s Codex docs describe subagents as a way to:

- keep noisy intermediate work off the main thread
- reduce context pollution and context rot
- parallelize independent exploration, analysis, or implementation work
- use different instructions or model settings for different delegated tasks

Two properties matter most:

1. Codex does not spawn subagents automatically. The operator must explicitly
   ask for subagents or parallel delegation.
2. Subagents cost more than a single-agent run because each child does its own
   model and tool work.

## Why they help

Subagents are most useful when the main thread should preserve high-signal
context such as requirements, constraints, architecture decisions, and final
judgment.

Good fits:

- codebase exploration across multiple independent areas
- review work split by concern, such as security, bugs, and test gaps
- parallel research on bounded technical questions
- implementation work split into disjoint write scopes
- verification tasks that can run while the parent continues with other work

Poor fits:

- urgent blocking work the parent immediately depends on
- tightly coupled edits across the same files
- tiny tasks where delegation overhead exceeds the work
- any situation where the subtask is vague enough that the child will likely
  need extensive back-and-forth

As a default, read-heavy delegation is safer than write-heavy delegation.

## Public Codex behavior

According to the current OpenAI Codex documentation:

- subagent workflows are enabled in current Codex releases
- activity is visible in the Codex app and CLI
- the CLI exposes agent threads through `/agent`
- child agents inherit the parent sandbox policy
- interactive approval prompts can surface from inactive child threads
- live runtime overrides from the parent turn are reapplied to children
- custom agents can be defined in `~/.codex/agents/` or `.codex/agents/`

Codex also ships with built-in agent types for general work, execution-focused
work, and read-heavy exploration.

## How subagents work in this harness

In this environment, subagents are exposed through explicit orchestration tools
rather than only through natural-language prompting.

The core lifecycle is:

1. `spawn_agent` creates a child agent for a concrete, bounded task.
2. `send_input` adds follow-up instructions to a running child.
3. `wait_agent` blocks until the child finishes when the parent is actually
   waiting on that result.
4. `close_agent` closes the child when it is no longer needed.
5. `resume_agent` can reopen a previously closed child if more work is needed.

The parent can also choose whether to:

- fork the full current conversation context into the child with
  `fork_context: true`
- pass a fresh, narrower prompt instead
- pick a specific model and reasoning effort for that child
- select a role-oriented agent type such as `default`, `explorer`, or `worker`

This harness adds an important operational constraint:

- `spawn_agent` is only allowed when the user explicitly asks for subagents,
  delegation, or parallel agent work

That means "be thorough" is not enough. The user must actually authorize
delegation.

## Built-in agent roles in this harness

The current built-in subagent types are:

| Agent type | Best use |
| --- | --- |
| `default` | General delegated work when no tighter role applies |
| `explorer` | Specific read-only or read-heavy codebase questions |
| `worker` | Execution work such as implementing a bounded change |

Use them intentionally:

- choose `explorer` for well-scoped questions about the codebase
- choose `worker` for a bounded implementation with a clear write set
- choose `default` when the task is real but does not fit the other two cleanly

## Delegation rules that matter

These are the most important practical rules from the current subagent contract
in this environment.

### 1. Do the critical-path work locally

Do not delegate the immediate blocking task if the next parent action depends on
that result. Delegation is best for sidecar work that can advance in parallel
while the parent continues doing something else.

### 2. Delegate bounded tasks, not vague missions

A good subtask has:

- a single clear objective
- a narrow output format
- a defined ownership boundary
- a clear stop condition

Bad example:

```text
Go figure out the whole auth system and improve it.
```

Better example:

```text
Inspect the OAuth callback flow in src/auth/. Identify any state-validation
gaps, list the exact files involved, and do not modify code.
```

### 3. Avoid overlapping write scopes

If multiple worker agents edit the same files, conflict risk rises fast. For
write tasks, assign disjoint ownership whenever possible.

### 4. Do not idle while children run

After spawning a child, the parent should continue with meaningful
non-overlapping work. Repeatedly waiting just to poll is usually the wrong
pattern.

### 5. Wait only when blocked

`wait_agent` is for moments when the parent truly needs the child result before
it can continue. Otherwise, keep moving on independent work.

### 6. Close completed threads

Subagents are disposable execution units, not long-lived personas. When their
job is done, close them.

## Model and reasoning strategy

OpenAI’s current Codex guidance is:

- start with `gpt-5.4` for most main-agent and harder subagent work
- use `gpt-5.3-codex-spark` for faster, lighter read-heavy tasks
- increase reasoning effort for complex review, security, or edge-case analysis
- keep reasoning lower for straightforward scans and lightweight tasks

In this harness, the same principle applies even when model names differ: match
model cost and reasoning depth to the difficulty and stakes of the child task.

Practical defaults:

- use a smaller or faster model for exploration, triage, and summarization
- use a stronger model for review, debugging, architecture, or ambiguous work
- use higher reasoning for reviewer-style or security-style analysis
- use medium or low reasoning when speed matters and the task is clear

## Relationship to the repository agent model

This repository defines long-lived delivery roles such as Director, Architect,
Coordinator, Engineer, Technical Lead, and Explorer.

Codex subagents should be treated as execution helpers for those roles, not as
a replacement for the repository state machine.

Examples:

- a Codex Architect session may spawn an `explorer` subagent to research an
  unknown before writing `research.md`
- a Codex Engineer session may spawn a read-only reviewer subagent to inspect
  adjacent code while the main thread implements a task
- a Codex Technical Lead session may spawn one subagent per review dimension
  and then consolidate the findings

What should not happen:

- using subagents to bypass entry-state discipline
- treating a spawned child as a standing system actor with independent authority
- letting subagents silently make architectural decisions without the required
  ADR flow

## Recommended patterns for this repository

### Pattern 1: Parallel review by concern

Use one child per review dimension, then consolidate:

- security
- correctness and bugs
- test coverage and flakiness
- maintainability

This is one of the cleanest subagent use cases because the outputs are read-only
and easy to merge.

### Pattern 2: Targeted exploration before planning

During planning, spawn one or more `explorer` agents to answer bounded technical
questions and return distilled findings for `research.md`.

### Pattern 3: Sidecar verification during implementation

While the parent is implementing a task, a child can inspect neighboring code,
trace a call path, or verify whether a suspected edge case is real.

### Pattern 4: Parallel implementation only with disjoint ownership

If multiple workers are used for code changes, each must own a separate slice of
the write surface. Shared-file edits should stay with the parent or a single
worker.

## Anti-patterns

Avoid these:

- spawning subagents without explicit user authorization to delegate
- delegating because a task is "big" without first defining bounded subtasks
- waiting immediately after every spawn instead of doing independent work
- sending multiple agents into the same unresolved coding area
- using child agents to hide uncertainty the parent should resolve itself
- treating every task as parallelizable

## Operational checklist

Before spawning a subagent, confirm:

- the user explicitly authorized delegation or parallel agent work
- the task is concrete, bounded, and materially useful
- the task is not the parent’s immediate blocking next step
- the output format is clear
- the write scope is disjoint if code edits are involved
- the chosen model and reasoning level match the task

After spawning:

- keep working on non-overlapping parent work
- wait only when the child result is needed
- review the child result critically
- close the thread when done

## Sources

- OpenAI Codex concept guide on subagents:
  <https://developers.openai.com/codex/concepts/subagents>
- OpenAI Codex configuration and workflow guide on subagents:
  <https://developers.openai.com/codex/subagents>
- Repository operating model:
  `docs/agentic-team.md`
