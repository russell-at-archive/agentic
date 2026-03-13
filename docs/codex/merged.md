# Unified Architecture Proposal for Agentic Execution

## Status

This document is a merged proposal, not a final architecture decision record.
Significant architecture choices described here must be ratified as ADRs in
`docs/adr/` before implementation begins.

## Purpose

The system needs an execution platform for many concurrent agents operating
safely in isolated containers while integrating cleanly with the repository's
planning, tracking, implementation, and review processes.

The architecture should support:

- strong isolation between agent runs
- horizontal scale across many simultaneous executions
- durable orchestration and auditability
- explicit artifact persistence
- operational visibility and control
- future evolution toward multi-tenant and multi-region deployment

## Problem Statement

The repository defines structured processes for planning, tracking,
implementation, and review, but it does not yet define the execution substrate
that allows agents to carry out approved work safely at scale.

The missing platform must answer a few core questions:

- how agent runs are isolated from one another
- how work is admitted, scheduled, and tracked
- how artifacts, logs, and state are persisted
- how many agents can run simultaneously without contention or unsafe coupling
- how operators observe, control, and debug the system

## Design Goals

- Run each agent execution in an isolated container or pod with tightly scoped
  permissions.
- Support high parallelism without shared mutable state by default.
- Separate orchestration concerns from execution concerns.
- Persist execution state, artifacts, and audit history durably.
- Enforce least privilege, network control, and runtime hardening.
- Integrate execution with the repository's workflow contracts.
- Provide clear rollout phases from MVP to larger-scale operation.

## Non-Goals

- Locking every infrastructure choice before ADRs are written.
- Designing the internal reasoning loop of a single agent runtime.
- Treating long-lived mutable workers as the default operating model.

## Foundational Principles

### Control Plane and Data Plane Separation

The platform should separate orchestration logic from execution logic.
Submission, policy, scheduling, and state tracking belong in the control
plane. Agent code execution belongs in the data plane.

### Stateless Orchestration Backed by Durable State

Orchestration services should be horizontally scalable and reconstruct their
state from durable storage rather than in-memory coordination.

### Ephemeral Execution Environments

Every agent run should start in a fresh execution environment and be destroyed
after completion. Container filesystems are not the system of record.

### Immutable Input Bundles

Each run should begin from a versioned input bundle that contains the approved
task context, planning artifacts, and runtime configuration required for
execution.

### Append-Only Execution Records

State transitions, events, logs, and artifact registrations should be written
as append-only records to preserve a reliable audit trail.

### Explicit Artifact Declaration

Agent outputs should be persisted through declared manifests rather than
through arbitrary writes to shared storage.

### Failure-Domain Isolation

The system should assume individual runs, pods, services, and queue consumers
can fail independently without taking down unrelated work.

## High-Level Architecture

The platform should be organized into five major areas:

- control plane
- execution data plane
- queue and event backbone
- persistence layer
- workspace and artifact model

This structure preserves a clean system boundary while remaining detailed
enough to guide implementation.

## Control Plane

The control plane accepts work, validates policy, creates execution records,
schedules tasks, and tracks lifecycle state.

Core services:

- `API Service`: accepts run submissions, status requests, log retrieval, and
  cancellation.
- `Execution Orchestrator`: owns lifecycle transitions and coordinates run
  progress through a durable state machine.
- `Scheduler`: places admitted work onto the appropriate queue using resource,
  priority, and fairness constraints.
- `Policy Service`: validates runtime policy, image policy, network policy,
  quota, and readiness requirements before execution begins.
- `State Store`: persists run metadata, heartbeats, retries, manifests, and
  audit metadata.

The orchestrator should manage an explicit lifecycle such as:

`submitted -> validated -> scheduled -> launching -> running -> completing ->
done`

with alternate terminal paths for `failed`, `cancelled`, and `timed_out`.

## Execution Data Plane

The execution data plane runs the agents themselves. The strongest default
model is one pod per run on Kubernetes, with each pod treated as an ephemeral
execution unit.

Recommended runtime model:

- one pod per run
- one primary agent container per pod
- optional init container for fetching and validating the input bundle
- optional sidecar for telemetry or artifact relay only where justified
- ephemeral writable storage mounted only where needed

Kubernetes is the strongest baseline substrate because it already provides:

- workload scheduling and bin-packing
- autoscaling
- secrets distribution
- network policies
- workload identity integrations
- mature operational tooling

## Execution Isolation Model

Container isolation is one of the primary design constraints and should be
first-class in the architecture.

Each run should execute with:

- non-root user identity
- read-only root filesystem where possible
- privilege escalation disabled
- dropped Linux capabilities by default
- seccomp and other pod security controls enabled
- deny-by-default network policy

For higher-risk tasks, the system should support a stronger sandbox tier using
gVisor or Kata Containers. This secure execution class should be available for
work touching platform infrastructure, security-sensitive code, or elevated
credentials.

The platform should treat sandboxing choices as an ADR-backed policy decision,
but the architecture should clearly reserve a place for runtime-isolation
tiering.

## Workspace and Artifact Model

The workspace model should combine the strongest ideas from the source
proposals:

- immutable input bundle
- copy-on-write ephemeral workspace
- explicit output manifest
- destroy-on-exit execution storage

A representative workspace layout could be:

```text
/workspace/
  input/   # approved bundle, read-only
  repo/    # repository checkout or snapshot materialization
  logs/    # structured execution logs
  output/  # declared artifacts plus manifest
```

Recommended behavior:

1. The orchestrator resolves approved task context into an immutable input
   bundle.
1. The execution pod materializes that bundle into a read-only input area.
1. The agent works in an ephemeral writable workspace, ideally backed by an
   overlay or similar copy-on-write mechanism.
1. At completion, the workspace manager validates the output manifest and
   persists only declared artifacts.
1. The workspace is destroyed after completion or failure.

This model reduces cross-run interference, improves replayability, and avoids
turning workspace state into hidden shared infrastructure.

## Queue and Event Backbone

The platform should use asynchronous dispatch rather than direct synchronous
coupling between API requests and workers.

Core messaging components:

- `Work Queue`: buffers runnable tasks and decouples ingestion from execution.
- `Event Bus`: publishes lifecycle events, heartbeats, artifact events, and
  policy decisions.
- `Dead Letter Queue`: captures poison tasks and exhausted retries for operator
  review.

This design enables:

- backpressure handling
- worker autoscaling
- retry control
- clear failure visibility
- loose coupling between orchestration and execution

The queue layer should support priority lanes and, eventually, fairness or
partitioning by tenant or workload class.

## Lifecycle and Reliability

The execution platform should behave like a durable state machine rather than a
best-effort job launcher.

Recommended reliability features:

- idempotent state transitions
- leases or heartbeats for stuck-run detection
- timeout enforcement
- bounded retries for infrastructure failures
- dead-letter handling for poison or policy-invalid work
- checkpointing support for multi-step workflows where replay cost is high

Logical task failures should not be blindly retried. The retry policy should
distinguish infrastructure instability from agent-produced failures.

## Multi-Agent Coordination

Many runs should remain embarrassingly parallel, but the system still needs a
clear model for coordination.

The default rule should be:

- agents coordinate through the control plane, persisted artifacts, and event
  streams
- agents do not coordinate through direct peer-to-peer container networking by
  default

Recommended coordination patterns:

- `fan-out`: independent tasks run concurrently as separate runs
- `dependency chain`: downstream tasks wait for upstream tasks to complete and
  publish artifacts
- `central conflict management`: the scheduler or orchestrator prevents unsafe
  overlap where two runs would mutate the same protected workspace or workflow
  target at the same time

The exact conflict-detection mechanism should be decided through ADRs, but the
architecture should preserve centralized coordination rather than ad hoc
cross-agent coupling.

## Integration With Repository Processes

The execution platform should operationalize the repository's existing process
model rather than bypass it.

Before admission, the platform should validate required planning artifacts such
as:

- `spec.md`
- `plan.md`
- `tasks.md`
- referenced ADRs where required

The platform should enforce that:

- the requested task is ready
- declared dependencies are satisfied
- execution class and permissions match policy
- the run is traceable to approved planning inputs

Repository workflow integration should include:

- issue and PR state transitions driven by lifecycle events
- artifact publication tied to declared outputs
- review as a first-class run type
- auditability across planning, implementation, and review

This is what differentiates a repository-native execution platform from a
generic container job runner.

## Persistence Layer

The platform should use storage systems according to their strengths.

- `Relational Database`: run metadata, state transitions, policies, quotas, and
  audit references
- `Object Storage`: input bundles, logs, transcripts, outputs, manifests, and
  execution artifacts
- `Search or Log Index`: operational log querying and artifact lookup
- `Metrics Store`: time-series metrics for capacity, latency, reliability, and
  cost monitoring
- `Trace Store`: distributed tracing across the control plane and worker flows

The architecture should not depend on pod-local storage for anything that must
survive execution.

## Security Model

Security should be designed into every layer.

### Container and Runtime Hardening

- minimal base images
- signed images and pinned digests where feasible
- non-root execution
- read-only root filesystem where possible
- no privileged containers
- dropped capabilities by default
- secure runtime class for sensitive workloads

### Secrets and Identity

- inject short-lived credentials at runtime
- scope credentials to the minimum repository, tool, or API surface required
- prefer workload identity over long-lived static keys
- avoid exposing secrets in prompts, logs, or persisted artifacts

### Network and Egress Control

- deny-all by default
- explicitly allow only approved destinations
- distinguish restricted and internet-enabled execution classes
- route sensitive tool access through auditable gateways where feasible

### Admission and Policy Enforcement

- image allowlists
- resource quotas
- execution-class restrictions
- task-readiness validation
- artifact validation before publication

## Observability and Operations

Observability should be a core platform capability, not a later enhancement.

The system should emit:

- structured logs
- metrics
- distributed traces
- audit events

Operators should be able to answer:

1. What is running right now?
1. Why is a run blocked, slow, or failing?
1. What artifacts and side effects did a run produce?
1. Which policy, resource, or dependency caused a run to stop?

Recommended operational signals:

- queue depth by lane
- run counts by state
- pod startup latency
- run duration by execution class
- failure and timeout rates
- dead-letter activity
- worker utilization
- artifact publication success and failure

## Scalability Strategy

The system should scale horizontally at both the control-plane and worker
layers.

### Control Plane

- stateless services behind load balancers
- durable backing stores for state and events
- horizontal scaling for API, orchestrator, and scheduler services

### Worker Layer

- pod-per-run execution for natural workload isolation
- cluster autoscaling for node capacity
- event-driven autoscaling based on queue depth
- pre-warmed pools where startup latency matters

### Resource Classes

The scheduler should support multiple execution classes rather than one generic
pool. A practical progression would include:

- `small` for lightweight planning or documentation work
- `medium` for standard implementation tasks
- `large` for memory- or tool-heavy tasks
- `secure` for sensitive tasks requiring stronger runtime isolation

This improves cost control, scheduling efficiency, and policy enforcement.

## Recommended Technology Baseline

The following should be treated as a recommended MVP baseline, not a final set
of approved decisions:

- Kubernetes for orchestration and isolated execution
- PostgreSQL for transactional metadata
- object storage such as S3-compatible storage for bundles and artifacts
- a durable queue and event backbone
- OpenTelemetry-compatible logs, metrics, and tracing

Additional recommendations introduced by the source proposals remain strong
candidates:

- gVisor or Kata for a secure runtime class
- NATS JetStream or a similar durable messaging system
- KEDA or equivalent event-driven autoscaling
- Grafana-compatible observability stack for integrated operations

Each of these choices should be confirmed or revised through ADRs.

## Phased Rollout

### Phase 1

Target:

- a single-region MVP supporting isolated pod-per-run execution
- basic lifecycle management
- artifact persistence
- submission, status, cancellation, and log retrieval

Minimum capabilities:

- API service
- orchestrator
- scheduler
- queue-backed execution dispatch
- Kubernetes worker execution
- immutable input bundles
- manifest-validated artifact persistence
- baseline logs and metrics

### Phase 2

Target:

- stronger operability and scaling for higher concurrency

Additions:

- priority lanes
- resource classes
- improved policy enforcement
- richer observability
- secure runtime tier
- better multi-agent dependency handling
- fairness or quota controls

### Phase 3

Target:

- multi-tenant and possibly multi-region expansion

Additions:

- stronger tenancy boundaries
- regional worker pools
- advanced scheduling and placement
- richer trigger models
- formalized SLOs and cost controls

## ADR Backlog

Before implementation, the team should formalize decisions for at least:

- orchestration substrate and deployment model
- queue and event technology
- metadata and artifact storage choices
- runtime isolation tiering
- secret management and workload identity
- observability stack
- quota and fairness model
- multi-agent coordination and conflict-management policy

## Open Questions

The merged proposal still leaves a few questions open by design:

1. Which agent runtimes must be supported at launch?
1. How should repository materialization work: clone-at-run-time or snapshot in
   the input bundle?
1. Which execution types require human approval before dispatch?
1. What retention policy should apply to logs, traces, and artifacts?
1. How should per-run cost attribution be tracked and enforced?

## Recommendation

Adopt a control-plane and data-plane architecture centered on Kubernetes-run
ephemeral agent pods, durable orchestration state, explicit artifact
management, hardened execution isolation, and repository-aware workflow
validation.

This merged approach preserves the strongest features from the three source
documents:

- the clear architectural decomposition from `codex`
- the strongest sandboxing and workspace-isolation ideas from `gemini`
- the lifecycle, observability, and workflow-integration depth from `claude`

It is the most coherent foundation for turning the current planning documents
into ADR-backed implementation work.
