# Architecture Proposal for Agentic Execution

## Status

This document is a proposal, not a final architecture decision record. The
repository requires significant architecture choices to be ratified as ADRs in
`docs/adr/`, so this file should be treated as pre-ADR input.

## Problem Statement

The system needs to run many agents simultaneously while preserving strong
isolation, predictable scheduling, and operational control. Agents should be
able to execute independently inside containers, share common platform
capabilities, and scale horizontally without turning the control plane into a
single bottleneck.

## Goals

- Run each agent execution in an isolated container with tightly scoped
  permissions.
- Support high parallelism across many concurrent agent runs.
- Separate orchestration concerns from execution concerns.
- Make execution observable, debuggable, and auditable.
- Support retries, cancellation, timeouts, and resource quotas.
- Keep the architecture compatible with future multi-tenant operation.

## Non-Goals

- Defining a final vendor selection for every infrastructure component.
- Designing the internal reasoning loop of a single agent model.
- Optimizing for long-lived pets; agent workers should be disposable.

## Recommended Architectural Principles

- Use a control-plane and data-plane split.
- Prefer stateless orchestration services backed by durable storage and queues.
- Treat every agent run as an immutable execution record plus append-only events.
- Use ephemeral execution environments rather than shared mutable hosts.
- Make artifact persistence explicit; container filesystems should not be the
  system of record.
- Design for failure domains so one bad agent run does not affect unrelated
  runs.

## Proposed Architecture

### 1. Control Plane

The control plane accepts work, plans execution, applies policy, and tracks
state. It should remain lightweight and horizontally scalable.

Core services:

- `API Gateway`: Authenticates users and systems, exposes run submission,
  status, logs, and control endpoints.
- `Execution Orchestrator`: Creates execution plans, resolves agent templates,
  selects tools and policies, and emits work items.
- `Scheduler`: Matches queued tasks to available compute based on CPU, memory,
  GPU, priority, tenant quota, and placement constraints.
- `State Service`: Stores run metadata, lifecycle state, leases, heartbeats,
  and retry history.
- `Policy Service`: Applies guardrails such as image allowlists, tool access,
  network policy, cost ceilings, and tenancy boundaries.

### 2. Execution Data Plane

The data plane runs the actual agents in isolated containers. Kubernetes is the
best default substrate because it already solves bin-packing, autoscaling,
network policy, secrets distribution, and workload isolation at scale.

Recommended runtime model:

- Each agent run executes in its own pod.
- Each pod contains one primary agent container.
- Optional sidecars handle log shipping, artifact sync, or policy enforcement
  only when necessary.
- Pods use ephemeral writable storage and mount only the minimum required
  secrets and volumes.
- Jobs are short-lived by default; long-running workflows are decomposed into
  smaller resumable steps.

### 3. Queue and Event Backbone

Use durable queues for work dispatch and an event stream for lifecycle
telemetry.

- `Work Queue`: Buffers runnable tasks and decouples ingestion from execution.
- `Event Bus`: Publishes state changes such as queued, started, heartbeat,
  tool-call, artifact-written, failed, cancelled, and completed.
- `Dead Letter Queue`: Captures poison work items and policy failures for
  operator review.

This separation prevents the API tier from depending on synchronous worker
availability and improves backpressure handling.

### 4. Persistence Layer

Use purpose-built storage rather than forcing one database to do everything.

- `Relational Database`: Source of truth for runs, tasks, users, policies,
  quotas, and audit metadata.
- `Object Storage`: Stores logs, transcripts, intermediate artifacts, patches,
  plans, and execution bundles.
- `Search Index`: Supports fast lookup across logs, artifacts, and traces.
- `Metrics Store`: Holds time-series data for capacity and SLO monitoring.

### 5. Workspace and Artifact Model

Agent workspaces should be ephemeral and reproducible.

- Build each run from an immutable input bundle: repository snapshot,
  instructions, secrets references, and runtime policy.
- Materialize that bundle into an ephemeral workspace inside the pod.
- Persist only declared outputs: documents, code patches, test results, logs,
  traces, and review artifacts.
- Avoid shared writable filesystems across concurrent agents unless there is a
  hard coordination requirement.

This reduces contention, avoids cross-run corruption, and simplifies replay.

## Reference Execution Flow

1. A client submits a run request to the API.
1. The orchestrator validates the request and writes a run record.
1. The scheduler places work onto a queue with priority and resource metadata.
1. A worker controller launches a pod from a trusted agent image.
1. The pod boots, pulls the input bundle, and starts the agent runtime.
1. The agent emits heartbeats, logs, metrics, and lifecycle events.
1. Artifacts are pushed to object storage during or after execution.
1. The orchestrator marks the run completed, failed, timed out, or cancelled.

## Scalability Strategy

### Horizontal Scaling

- Scale API, orchestrator, and scheduler services statelessly behind load
  balancers.
- Scale workers through Kubernetes cluster autoscaling and workload-based
  horizontal pod autoscaling.
- Partition queues by priority, tenant, or workload class to avoid noisy
  neighbors.

### Resource Classes

Define execution classes instead of using one generic pool.

- `small`: lightweight document or planning tasks.
- `medium`: code editing and repository analysis.
- `large`: memory-heavy reasoning or tool-intensive work.
- `gpu`: model-serving or specialized inference tasks.

This improves scheduling efficiency and cost control.

### Isolation Boundaries

- Namespace by environment and optionally by tenant.
- Use per-run service accounts where feasible.
- Apply network policies so pods can only reach approved services.
- Enforce CPU, memory, storage, and execution time limits on every run.

## Reliability and Failure Handling

- Make run state transitions idempotent.
- Use leases and heartbeats to detect stuck or orphaned runs.
- Retry infrastructure failures automatically, but do not blindly retry logical
  task failures.
- Support checkpointing for multi-step workflows so failed steps can resume
  without replaying everything.
- Preserve full audit trails for cancellation, retry, and human override events.

A practical pattern is to split agent execution into a state machine with
durable checkpoints between expensive or externally visible actions.

## Security Model

### Container Hardening

- Use minimal base images and signed image provenance.
- Run as non-root with a read-only root filesystem when possible.
- Drop Linux capabilities by default.
- Use seccomp, AppArmor, and pod security standards.
- Disable privileged containers.

### Secret and Credential Handling

- Inject short-lived credentials at runtime.
- Scope credentials to the minimum repository, tool, or API access required.
- Never persist raw secrets in logs, prompts, or artifacts.
- Rotate credentials automatically and revoke on run termination when possible.

### Network and Tool Safety

- Default to deny-all egress, then open only approved destinations.
- Route tool access through audited service gateways where feasible.
- Separate internet-enabled agents from restricted agents through distinct
  execution classes and policies.

## Observability and Operations

The platform should provide first-class visibility into both system health and
agent behavior.

- Centralized structured logs for every run and service.
- Distributed tracing across API, orchestration, queueing, and worker startup.
- Metrics for queue depth, schedule latency, pod startup time, run duration,
  failure rate, retry rate, and cost per run.
- Audit events for policy decisions, secret access, human interventions, and
  artifact publication.

Operators should be able to answer four questions quickly:

1. What is running now?
1. Why is a run blocked or slow?
1. What did a specific agent do?
1. Which resource or policy limit caused the issue?

## Multi-Agent Coordination

Running many agents simultaneously does not require shared execution state by
default. Prefer explicit coordination through the control plane.

- Parent workflows should spawn child runs through orchestration APIs, not by
  shelling directly into peer containers.
- Shared context should move through persisted artifacts, event streams, or
  task contracts.
- Cross-agent locks should be rare and handled centrally.

This keeps agents embarrassingly parallel for most workloads and avoids turning
container networking into an ad hoc distributed system.

## Recommended Technology Pattern

The following pattern is the strongest default unless product constraints point
elsewhere:

- Kubernetes for container scheduling and isolation.
- A relational database such as Postgres for transactional metadata.
- Object storage such as S3 for durable artifacts and logs.
- A durable queue or workflow engine for dispatch and retries.
- OpenTelemetry-based tracing, metrics, and logs.
- An internal policy layer for admission, quotas, and runtime guardrails.

If the system eventually needs very long-lived, highly stateful agent graphs,
add a workflow engine above Kubernetes rather than encoding workflow semantics
inside individual pods.

## Tradeoffs

### Why Kubernetes

- Strong ecosystem support for multi-tenant container orchestration.
- Mature autoscaling, isolation, policy, and observability integrations.
- Easier path from tens of agents to thousands of concurrent runs.

### Costs and Complexity

- Operational complexity is higher than a simple queue plus VM workers.
- Cold-start latency must be managed through image size, node warm pools, and
  scheduler tuning.
- Debugging distributed control-plane failures requires disciplined
  observability.

## Phased Rollout

### Phase 1

- Single region.
- Kubernetes-based isolated run execution.
- One control-plane service, one relational database, one object store, and one
  queue.
- Basic retries, cancellation, and artifact persistence.

### Phase 2

- Priority queues, tenant quotas, and execution classes.
- Enhanced policy enforcement and network controls.
- Rich tracing, search, and cost attribution.

### Phase 3

- Multi-region control-plane strategy.
- Regional worker pools with data locality awareness.
- Advanced workflow orchestration for multi-agent plans.

## Proposed ADR Set

Before implementation, this proposal should be translated into ADRs covering at
least:

- Compute substrate and isolation model.
- Queue or workflow orchestration choice.
- Persistence and artifact storage boundaries.
- Security model for credentials, networking, and tool execution.
- Multi-tenant quota and fairness model.

## Recommendation

Adopt a control-plane/data-plane architecture built on Kubernetes-run ephemeral
agent pods, durable queues, relational metadata storage, and object-based
artifact persistence. This is the most scalable and operationally defensible
baseline for concurrent agent execution, provided the team formalizes the key
decisions as ADRs before implementation.
