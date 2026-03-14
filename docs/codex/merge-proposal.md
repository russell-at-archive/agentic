# Unified MVP Proposal: Local Docker Thoughtstream

## Summary

The three MVP proposals are closest in their infrastructure choices and farthest
 apart in how much workflow automation they try to include. A cohesive merged
proposal should keep the narrow local-Docker execution model that all three
agree on, while sequencing the stronger ideas from each proposal in the order
that minimizes delivery risk.

The unified approach is:

- start with Codex's execution-substrate baseline
- adopt Gemini's local isolation and container-hardening defaults
- shape the user experience around Claude's concrete operator workflow
- defer Claude's GitHub automation and concurrency until after the core loop is
  stable

This creates a single thoughtstream: first prove that a local orchestrator can
reliably run isolated agents against real repository inputs, then layer on the
smallest amount of workflow automation that increases usefulness without
reintroducing platform complexity.

## The Core Thesis

The MVP should not attempt to prove the full production architecture. It should
prove one narrower but durable claim:

> A single developer can submit a task, run an isolated agent in Docker against
> a checked-out repository state, inspect durable logs and artifacts, and decide
> what to do next.

That thesis preserves the important invariant from the full design: execution is
ephemeral, isolated, and inspectable. It drops the parts that only matter once
the execution loop is already known to work at scale.

## Unified Architecture

```text
User
  -> local CLI
  -> single local orchestrator process
     -> validates local task inputs
     -> writes run state to SQLite
     -> prepares workspace and manifest.json
     -> starts one Docker container per run
     -> captures logs and artifacts to local disk
     -> enforces timeout and cancellation

Persistence
  -> SQLite for run state
  -> data/runs/<run-id>/ for logs, manifest, outputs, and result metadata

Execution
  -> local Docker container
  -> read-only manifest mount
  -> isolated workspace mount
  -> restricted networking by default
```

This architecture is intentionally single-machine, single-operator, and
single-worker by default.

## What to Keep From Each Proposal

### From Codex

Codex provides the strongest foundation because it is the most disciplined about
scope.

Keep these elements:

- SQLite as the system of record
- explicit run lifecycle states
- local artifact and log directories
- mounted read-only `manifest.json`
- `run`, `status`, `logs`, and `cancel` as the first operator commands
- a strict focus on proving the execution substrate before higher-order
  automation

These decisions make the MVP observable, debuggable, and easy to evolve.

### From Gemini

Gemini contributes the strongest local isolation posture and the clearest sense
that the host and container should have a deliberate boundary.

Keep these elements:

- Docker as the only isolation boundary in v1
- restricted or disabled container networking by default
- least-privilege container settings where practical
- preference for mounted secret files or env files over ad hoc direct secret
  injection
- strong alignment with the repository's existing planning artifacts rather than
  inventing a parallel planning system

These decisions improve safety without adding much implementation burden.

### From Claude

Claude contributes the strongest operator-facing workflow and the clearest view
of what a useful local runner should feel like.

Keep these elements:

- concrete CLI-driven submission flow
- clear runtime directory layout
- explicit timeout handling
- a practical three-day implementation sequence
- the idea that the runner should eventually support validation and GitHub
  write-back, but not as v1 requirements

Claude's contribution is best treated as product direction for v1.1 rather than
as mandatory MVP scope.

## The Unified MVP Shape

### Operator Experience

The initial interface should be a local CLI:

```bash
archive-agentic run --task T-07 --repo /path/to/repo --commit <sha>
archive-agentic status <run-id>
archive-agentic logs <run-id>
archive-agentic cancel <run-id>
```

This preserves Claude's concrete usability while staying within Codex's scope
discipline.

### State Model

The MVP should store explicit run state in SQLite rather than relying only on
Git and the filesystem.

Minimum local tables:

- `runs`
- `artifacts`
- `events`

Why this wins:

- simpler status inspection
- cleaner cancellation semantics
- easier debugging after failures
- a more natural upgrade path to a future control plane

This is a stronger merged choice than Gemini's filesystem-only model.

### Runtime Handoff

Use a mounted read-only `manifest.json` as the primary handoff contract to the
container.

Why this wins:

- easier to inspect than pure environment variables
- closer to the full architecture's manifest concept
- easier to version later
- avoids turning the container contract into a loose bag of env vars

Environment variables may still be used for a small number of runtime secrets,
but not as the primary manifest mechanism.

### Execution Model

Each run gets one fresh Docker container.

Container defaults should be:

- one run at a time by default
- no inter-container communication
- disabled networking unless explicitly enabled
- read-only mounts where possible
- writable output directory only where needed
- CPU and memory limits via standard Docker flags

This is the strongest synthesis of Codex's narrow MVP and Gemini's safety
posture.

### Artifact Model

Every run should write to a predictable directory such as:

```text
data/runs/<run-id>/
  manifest.json
  execution.log
  result.json
  output/
```

This keeps the model simple and operator-friendly while preserving the explicit
artifact mindset from the full architecture.

## What the Unified MVP Should Explicitly Not Do

To stay coherent, the merged proposal must reject several tempting additions.

Do not include in v1:

- Kubernetes
- queues, event buses, or dead-letter handling
- multiple workers as a core requirement
- GitHub issue synchronization
- automatic PR creation
- branch orchestration as a required subsystem
- dependency scheduling across tasks
- checkpointed resumability
- hosted observability systems
- separate policy, scheduler, or spec-resolver services

These features are not wrong. They are simply downstream of the thing this MVP
needs to validate first.

## The Recommended Build Sequence

### Step 1: Prove Local Execution

Implement:

- local CLI
- SQLite schema
- workspace preparation
- `docker run` execution
- log capture
- timeout and cancellation

Success criterion:

- a task can be submitted and run locally in an isolated container, and the
  operator can inspect the result afterward

### Step 2: Harden the Local Boundary

Add:

- disabled network by default
- least-privilege Docker flags
- mounted secret files or env file handling
- clearer separation between read-only inputs and writable outputs

Success criterion:

- the local runner still works while having a more explicit and constrained
  security model

### Step 3: Add Lightweight Workflow Helpers

Only after the first two steps are stable, add:

- planning artifact validation
- optional host-side branch helpers
- optional host-side GitHub or Graphite helpers

Success criterion:

- workflow convenience improves without turning the MVP into a local copy of the
  full control plane

This sequencing preserves Claude's end-to-end ambition without allowing it to
dominate the initial scope.

## Why This Thoughtstream Is Cohesive

The merged approach is cohesive because it answers one question at a time.

First question:
Can isolated local agent execution work reliably?

Second question:
Can that execution be made safe and inspectable enough to be useful day to day?

Third question:
Which pieces of workflow automation are worth adding once the core loop is
already stable?

That progression is the cleanest merger of the three proposals because it keeps
their strongest ideas, but puts them into the only order that makes a few-day
solo implementation credible.

## Final Recommendation

Adopt a single merged MVP defined as:

- local CLI orchestrator
- SQLite-backed run state
- local filesystem logs and artifacts
- one Docker container per run
- mounted read-only `manifest.json`
- single-worker execution by default
- network disabled by default
- least-privilege container settings where practical
- no required GitHub automation in v1

In short:

Build Codex's MVP, harden it with Gemini's container defaults, and treat
Claude's workflow automation as the first expansion step after the local runner
is proven.
