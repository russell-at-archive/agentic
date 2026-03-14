# MVP Proposal: Local Docker Agent Runner

## Summary

The current architecture is a full platform design. It assumes a control plane,
distributed messaging, Kubernetes scheduling, persistent observability systems,
and several external integrations. That is too large for a single person to
build in a few days.

The proposed MVP reduces the system to one machine, one operator, and one
execution model:

- a local command or tiny local API to submit a run
- one local orchestrator process
- agent execution in isolated local Docker containers
- local filesystem persistence for logs and artifacts
- a simple local state store for run metadata

This keeps the core idea intact: take an approved task, run an isolated agent
against a checked-out repository, capture what it did, and inspect the result.

## Goal

Prove that the execution workflow is viable before building platform
infrastructure.

The MVP should answer these questions:

- Can an agent run reliably against repository planning artifacts?
- What minimal manifest is actually needed?
- What logs and outputs are useful for operators?
- What parts of the lifecycle need automation versus manual control?
- Where do failures actually happen in practice?

## Non-Goals

The MVP should explicitly avoid these concerns for now:

- Kubernetes or any remote scheduler
- multiple concurrent workers beyond maybe one run at a time
- priority queues, retries, or dead-letter handling
- multi-tenant quotas or team isolation
- GitHub issue synchronization or PR automation as a required subsystem
- event buses, telemetry sidecars, distributed tracing, or search indexing
- hardened sandboxing beyond standard Docker container isolation
- workflow engines, dependency graphs, or inter-agent coordination
- cloud artifact storage, secret management systems, or policy microservices

## Proposed MVP Architecture

```text
User
  -> local CLI
  -> local runner service
     -> writes run metadata to SQLite
     -> prepares manifest.json
     -> starts Docker container
     -> mounts repo checkout and output directory
     -> streams logs to local files
     -> records final status and artifact paths

Local persistence
  -> SQLite database
  -> ./data/runs/<run-id>/ for logs and artifacts
```

## Core Components

### 1. Local CLI

Provide a single operator-facing entry point such as:

```bash
archive-agentic run --task T-07 --repo /path/to/repo --commit <sha>
archive-agentic status <run-id>
archive-agentic logs <run-id>
archive-agentic cancel <run-id>
```

The CLI is sufficient for the first version. A local HTTP API is optional and
should only be added if it makes implementation faster.

### 2. Local Orchestrator

Replace the API Service, Orchestrator, Scheduler, and Policy Service with one
small in-process coordinator.

Responsibilities:

- validate the requested repo path, commit SHA, and task ID
- create a run record
- prepare a minimal manifest
- create working directories
- invoke `docker run`
- watch for process exit or timeout
- mark the run as succeeded, failed, cancelled, or timed out

This is a single-process state machine, not a distributed control plane.

### 3. Docker-Based Agent Execution

Each run executes in one local Docker container.

Suggested container properties:

- ephemeral container per run
- bind-mounted workspace or copied checkout
- bind-mounted output directory
- fixed image chosen manually in config
- CPU and memory limits set with ordinary Docker flags
- no container-to-container communication

This preserves the important isolation boundary without needing Kubernetes.

### 4. Local State Store

Use SQLite instead of PostgreSQL.

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

This is enough for status inspection and a basic audit trail.

### 5. Local Artifact and Log Storage

Store everything on disk under a predictable directory such as:

```text
./data/runs/<run-id>/
  manifest.json
  execution.log
  output/
  result.json
```

This replaces object storage, log aggregation, and search infrastructure.

### 6. Minimal Manifest

The manifest should contain only what the agent cannot infer from the
repository:

- `run_id`
- `task_id`
- `repo_path`
- `commit_sha`
- `output_dir`
- `runtime_config`
- optional allowed tools list

For the MVP, write the manifest to disk before container startup and mount it
read-only into the container. There is no need for a readiness handshake.

## Simplified Lifecycle

Reduce the lifecycle to:

```text
submitted -> running -> succeeded
                     -> failed
                     -> cancelled
                     -> timed_out
```

This is enough to prove the execution loop. States like `validated`,
`scheduled`, `launching`, and `completing` are implementation detail, not user
value, at this stage.

## Execution Flow

1. Operator submits a run from the CLI.
2. The local orchestrator validates the input and creates a run record.
3. The orchestrator checks out the target repo at the requested commit into a
   temporary workspace.
4. The orchestrator writes `manifest.json` and creates an output directory.
5. The orchestrator starts the Docker container with the workspace and output
   directory mounted.
6. The agent runs inside the container and writes logs and declared outputs.
7. The orchestrator captures exit status, updates SQLite, and keeps artifacts on
   disk for inspection.

## What to Keep From the Original Design

The reduction should preserve only the parts that test the real product
hypothesis:

- ephemeral execution per run
- container isolation
- a manifest passed to the agent
- durable logs and outputs
- explicit run states
- cancellation and timeout support

These are the parts most likely to survive into a later architecture.

## What to Remove Entirely From the MVP

The following elements should not be implemented in the first pass:

- Kubernetes operator and custom resources
- separate control plane services
- message queue and event bus split
- GitHub integration service
- spec resolver as a standalone service
- tool gateway
- telemetry sidecar
- multiple execution classes
- quota enforcement
- review agents as a separate subsystem
- checkpointed resumability
- dependency-chain coordination
- conflict detection across runs
- cloud storage and hosted observability stack

If any of these become necessary during MVP implementation, that should be
treated as evidence that the MVP scope was too large or the wrong workflow was
chosen.

## Suggested Build Plan for a Few Days

### Day 1

- create the CLI
- define the SQLite schema
- implement run creation and status inspection
- implement local workspace preparation

### Day 2

- implement `docker run` execution
- mount manifest, workspace, and output directory
- capture stdout and stderr to `execution.log`
- enforce timeout and cancellation

### Day 3

- implement artifact recording
- add `logs` and `cancel` commands
- add one example agent image and one happy-path demo task
- harden basic error handling

### Optional Day 4

- add a tiny local HTTP API if needed
- add one optional GitHub write-back step at run completion
- add one simple retry flag for infrastructure failures

## Acceptance Criteria

The MVP is done when a single developer can:

- submit a task run locally
- watch it execute in an isolated Docker container
- inspect status while it runs
- cancel or timeout the run
- inspect logs and output artifacts after completion
- rerun the same task against a different commit SHA

## Risks and Trade-Offs

This MVP intentionally accepts several limitations:

- only local execution, so no remote workers or horizontal scaling
- weak security compared with a hardened sandbox
- limited observability compared with structured centralized telemetry
- manual operations instead of event-driven automation
- minimal policy enforcement

Those are acceptable because the goal is to validate the workflow, not to prove
production readiness.

## Recommended Next Step

Before implementation, rewrite the current Phase 1 plan around this local Docker
MVP. If that direction is accepted, capture it in an ADR and treat the current
distributed design as a later-stage target rather than the immediate starting
point.
