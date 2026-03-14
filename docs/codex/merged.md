# MVP Proposal: Unified Local Docker Agent Runner

## Overview

The original architecture describes a full execution platform with a control
plane, distributed messaging, Kubernetes scheduling, persistent observability,
and multiple external integrations. That is too large for a single-person MVP.

This merged proposal reduces the system to a local Docker runner that can be
built by one developer in a few days while preserving the strongest ideas from
the three source proposals:

- Codex's scope discipline, explicit state model, and manifest-driven runtime
- Gemini's local isolation defaults and host/container boundary
- Claude's practical operator workflow and concrete execution loop

The result is a single coherent MVP: a local CLI submits a task, a local
orchestrator prepares a run, a Docker container executes the agent in isolation,
and the system records logs, outputs, and run state for inspection.

## Goal

Prove the core execution loop on one developer machine:

1. submit a task against a repository and commit SHA
2. run the task inside an isolated Docker container
3. persist logs, outputs, and run state locally
4. inspect, cancel, or rerun the task from the host

The MVP should answer these questions:

- Can the agent run reliably against repository planning artifacts?
- What minimal execution manifest is actually needed?
- What outputs and logs are useful for local operators?
- What host/container isolation defaults are practical without overbuilding?
- Which workflow automations are worth adding only after the execution loop
  works?

## Non-Goals

The MVP does not attempt to prove the full platform design.

Out of scope for v1:

- Kubernetes, CRDs, or a worker controller
- distributed queues, event buses, or dead-letter handling
- multiple control-plane services
- cloud artifact, log, or metrics backends
- multi-tenant quotas or execution classes
- dependency scheduling across runs
- checkpoint-based resumability
- required GitHub issue synchronization
- required automatic PR creation
- hardened sandboxing beyond standard Docker isolation and local hardening flags

These can be added later if the local runner proves valuable.

## MVP Architecture

```text
User
  -> local CLI
  -> local orchestrator process
     -> validates inputs
     -> writes run state to SQLite
     -> prepares workspace and manifest.json
     -> launches Docker container
     -> captures logs and artifacts
     -> enforces timeout and cancellation

Local persistence
  -> SQLite database
  -> data/runs/<run-id>/ for logs, manifest, outputs, and result metadata

Execution
  -> one ephemeral Docker container per run
  -> read-only manifest mount
  -> isolated workspace
  -> restricted networking by default
```

This is single-machine, single-operator, and single-worker by default.

## Core Components

### 1. Local CLI

The first interface should be a small local CLI:

```bash
archive-agentic run --task T-07 --repo /path/to/repo --commit <sha>
archive-agentic status <run-id>
archive-agentic logs <run-id>
archive-agentic cancel <run-id>
```

This keeps the operator workflow concrete and useful from day one.

### 2. Local Orchestrator

One process replaces the API service, orchestrator, scheduler, and policy
service from the full design.

Responsibilities:

- validate repo path, task ID, and commit SHA
- optionally verify planning artifacts exist
- create a run record
- prepare a workspace checkout
- write `manifest.json`
- start `docker run`
- capture stdout and stderr to local files
- enforce timeout and cancellation
- record artifacts and final status

This is a local state machine, not a distributed control plane.

### 3. Docker-Based Agent Execution

Each run gets one fresh Docker container.

Container defaults:

- ephemeral container per run
- bind-mounted workspace
- bind-mounted output directory
- read-only manifest mount
- CPU and memory limits via standard Docker flags
- no container-to-container communication
- network disabled by default unless a task explicitly needs it
- least-privilege flags where practical, such as dropped capabilities and a
  non-root user if the image supports it

This preserves the key isolation boundary without introducing Kubernetes.

### 4. Local State Store

Use SQLite as the system of record.

Minimal tables:

- `runs`
  - `id`
  - `task_id`
  - `repo_path`
  - `commit_sha`
  - `status`
  - `started_at`
  - `finished_at`
  - `exit_code`
  - `container_id`
- `artifacts`
  - `run_id`
  - `kind`
  - `path`
- `events`
  - `run_id`
  - `ts`
  - `event`
  - `message`

SQLite is a better merge choice than filesystem-only state because it gives
clearer inspection, cancellation semantics, and upgrade paths.

### 5. Local Artifact and Log Storage

Store every run in a predictable directory:

```text
data/runs/<run-id>/
  manifest.json
  execution.log
  result.json
  output/
```

This combines Codex's explicit artifact model with Claude's practical runtime
layout.

### 6. Agent Image

Use one local "golden image" for the MVP.

The image should include:

- the selected agent CLI or CLIs
- Git and standard development tools
- any project runtimes commonly needed for implementation tasks

The runner should mount repository state and outputs rather than baking task
data into the image.

## Manifest and Runtime Contract

The manifest should be written on the host and mounted read-only into the
container as `manifest.json`.

Recommended manifest fields:

- `run_id`
- `task_id`
- `repo_path`
- `commit_sha`
- `workspace_path`
- `output_dir`
- `runtime_config`
- optional allowed tools list

This is stronger than a pure environment-variable contract because it is easier
to inspect, version, and evolve.

Environment variables may still be used for a small number of secrets or runtime
flags, ideally through an env file or mounted secret file rather than many
direct inline variables.

## Execution Flow

1. The operator submits a run from the CLI.
2. The orchestrator validates the local inputs and creates a run record.
3. The orchestrator checks out the repository at the requested commit into a
   temporary workspace.
4. The orchestrator writes `manifest.json` and creates an output directory.
5. The orchestrator launches a Docker container with the workspace, manifest,
   and output directory mounted.
6. The agent reads the planning artifacts from the workspace and executes the
   task.
7. The agent writes logs and outputs to the mounted output directory.
8. The orchestrator captures the exit status, records artifacts, and updates the
   final run status in SQLite.

## Simplified Lifecycle

The MVP lifecycle should be:

```text
submitted -> running -> succeeded
                     -> failed
                     -> cancelled
                     -> timed_out
```

This is enough to make runs inspectable and controllable without carrying the
full architecture's distributed state machine into v1.

## Workflow Positioning

The runner should align with the repository's existing planning artifacts, but
it should not require end-to-end GitHub automation in v1.

Recommended posture:

- planning artifacts are read from the checked-out repository state
- optional validation of `spec.md`, `plan.md`, and `tasks.md` can be added
  early if it is simple
- branch creation, PR submission, and issue updates stay host-side or manual in
  v1
- host-side helpers for GitHub or Graphite can be added later as convenience
  features, not as required subsystems

This preserves Claude's workflow ambition without letting it overdefine the MVP.

## What Is Reduced From the Full Architecture

The following elements are intentionally replaced or removed:

- Kubernetes and worker controllers are replaced by `docker run`
- distributed control-plane services are replaced by one local process
- object storage and log backends are replaced by local directories
- PostgreSQL is replaced by SQLite
- queues and event buses are replaced by direct function calls and local state
- platform observability is replaced by local logs and explicit run records
- policy microservices are reduced to simple local validation checks

The key product claim remains intact: isolated, inspectable, repeatable agent
execution against real repository inputs.

## Suggested Build Plan

### Day 1: Core Runner

- define the CLI
- create the SQLite schema
- implement run creation and status inspection
- prepare local workspace checkout

### Day 2: Docker Execution

- implement `docker run` execution
- mount workspace, manifest, and output directory
- capture stdout and stderr to `execution.log`
- enforce timeout and cancellation

### Day 3: Hardening and Usability

- add restricted-network defaults
- add least-privilege container flags where practical
- record artifacts and result metadata
- provide one example agent image and one happy-path demo run

### After MVP

Add only after the local runner is reliable:

- planning artifact validation beyond basic file existence
- host-side branch helpers
- optional PR and issue automation
- bounded concurrency if local throughput actually matters

## Acceptance Criteria

The MVP is complete when a single developer can:

- submit a task run locally
- execute it inside an isolated Docker container
- inspect status while it runs
- cancel or timeout the run
- inspect logs and output artifacts after completion
- rerun the same task against a different commit SHA

## Final Recommendation

This merged document recommends a single clear direction:

- build the local Docker runner first
- use SQLite for explicit run tracking
- keep the manifest as a mounted file
- adopt Gemini-style isolation defaults
- preserve Claude's concrete CLI workflow
- defer GitHub automation, concurrency, and platform features until after the
  execution substrate is proven

In short, the best combined MVP is a local, inspectable, Docker-isolated agent
runner that is small enough to build quickly and structured enough to evolve
toward the larger architecture later.
