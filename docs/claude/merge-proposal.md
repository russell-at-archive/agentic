# Agentic Execution Architecture — Merged Proposal

**Date**: 2026-03-13
**Status**: Pre-ADR proposal. All significant decisions identified here must be elevated to ADRs in `docs/adr/` before implementation begins.
**Source documents**: `docs/codex/architecture-proposal.md`, `docs/gemini/architecture-proposal.md`, `docs/claude/architecture-proposal.md`
**Analysis**: `docs/claude/plan-analysis.md`

---

## 1. Purpose and Scope

This document merges three independently authored architecture proposals into a single coherent architecture for agentic execution. It preserves the strongest contribution from each source, resolves points of disagreement, and surfaces the decisions that remain open for team ratification.

The system must:

- Execute AI agents in strongly isolated containers, one container per run
- Support many agents running simultaneously without resource contention or state interference
- Integrate with the planning, tracking, implementation, and review processes defined in this repository
- Be observable, auditable, and operable from day one
- Scale from a single-region MVP to multi-region multi-tenant operation without rewriting core contracts

This proposal does not define the internal reasoning loop of any agent model, make final vendor selections, or replace the ADRs that must follow.

---

## 2. Problem Statement

The process framework defined in this repository expects agents to execute approved tasks autonomously: create branches, write code following TDD, commit, open pull requests, update GitHub Issues, and produce reviewable outputs. The current gap is a missing execution substrate. No system yet exists to launch agents, isolate them from one another, manage their lifecycle, persist their outputs, or give operators visibility into what is happening.

The architecture defined here fills that gap.

---

## 3. Non-Goals

- Defining final vendor or product selections — those are ADR decisions
- Designing agent reasoning, prompting, or model choice
- Optimizing for long-lived, stateful pets — agent workers are disposable
- Encoding workflow semantics inside individual containers

---

## 4. Foundational Principles

These principles govern every component and every trade-off in this architecture. They are non-negotiable inputs to all subsequent ADR decisions.

### 4.1 Control Plane / Data Plane Separation

Orchestration logic — what should run, when, with what configuration, under what policy — is strictly separated from execution logic — how an agent operates inside a container. Each layer scales and evolves independently.

### 4.2 Failure Domain Isolation

One bad agent run must not affect unrelated runs. Every boundary between components is designed to contain failures. A stuck or crashing agent pod surfaces a recoverable error for that run only; it does not degrade the scheduler, the queue, or the control plane.

### 4.3 Stateless Orchestration Backed by Durable State

Orchestrators and schedulers carry no in-memory state that cannot be reconstructed from the database. Any control plane instance can be restarted or replaced without losing run state. This makes the system resilient to control plane failures and enables zero-downtime deployments.

### 4.4 Immutable Input Bundles

Before a run starts, the system resolves all planning artifacts — `spec.md`, `plan.md`, `tasks.md`, task context, and configuration — into a versioned, immutable input bundle written to object storage. The agent receives a reference to this bundle. Nothing in the bundle changes during the run. This makes every run reproducible and eliminates mid-flight configuration drift.

### 4.5 Ephemeral Execution Environments

Agent containers are created fresh per run and destroyed after completion. No state persists in the execution environment between runs. All meaningful output is declared and pushed to durable storage before the container exits.

### 4.6 Explicit Artifact Declaration

Agents do not have write access to arbitrary locations. They declare their outputs using a structured manifest. A workspace manager validates that declared artifacts exist and pushes them to durable storage. Undeclared side effects are not permitted. This prevents agents from silently modifying shared state and makes output validation deterministic.

### 4.7 Append-Only Execution Records

Run state transitions, events, log lines, and artifact references are written as append-only records. Nothing is mutated or deleted during or after a run. This makes the audit trail durable, reconstructible, and tamper-evident.

### 4.8 Explicit Coordination Through the Control Plane

Agents do not communicate with each other directly. They do not shell into peer containers or share writable filesystems with concurrent runs. Shared context moves through persisted artifacts, event streams, and task contracts managed by the control plane. Cross-agent locks, when required, are held centrally. This keeps agents embarrassingly parallel for most workloads and prevents container networking from becoming an ad hoc distributed system.

### 4.9 Design for Checkpointing

Multi-step agent workflows should be decomposable into resumable steps with durable checkpoints between externally visible actions. A transient failure should not require replaying work that has already been durably committed. Expensive or irreversible operations — pushing a commit, opening a PR, updating an Issue — are checkpointed so retry logic does not repeat them.

---

## 5. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Control Plane                             │
│                                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  ┌──────────┐  │
│  │ API Service │  │ Orchestrator │  │  Scheduler  │  │  Policy  │  │
│  │ (REST/gRPC) │  │ (State Mach.)│  │             │  │ Service  │  │
│  └──────┬──────┘  └──────┬───────┘  └──────┬──────┘  └────┬─────┘  │
│         │                │                 │              │         │
│  ┌──────▼────────────────▼─────────────────▼──────────────▼──────┐  │
│  │                   State Store (PostgreSQL)                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬──────────────────────────────────┘
                                   │
┌──────────────────────────────────▼──────────────────────────────────┐
│                           Message Layer                             │
│                                                                     │
│  ┌──────────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │ Work Queue           │  │  Event Bus       │  │  Dead Letter  │  │
│  │ (priority lanes)     │  │  (lifecycle/     │  │  Queue        │  │
│  │ critical / standard  │  │   telemetry fan- │  │               │  │
│  │ background / retry   │  │   out)           │  │               │  │
│  └──────────┬───────────┘  └────────┬─────────┘  └───────────────┘  │
└─────────────┼──────────────────────┼────────────────────────────────┘
              │                      │
┌─────────────▼──────────────────────┼────────────────────────────────┐
│            Execution Plane         │                                │
│                                    │                                │
│  ┌────────────────────────┐        │                                │
│  │  Worker Controller     │        │                                │
│  │  (Kubernetes Operator) │        │                                │
│  └───────────┬────────────┘        │                                │
│              │ creates             │                                │
│  ┌───────────▼──────────────────┐  │                                │
│  │         Agent Pod            │──┘ emits events/heartbeats        │
│  │  ┌──────────────────────┐    │                                   │
│  │  │  init: bundle-fetch  │    │                                   │
│  │  ├──────────────────────┤    │                                   │
│  │  │  agent runtime       │    │                                   │
│  │  │  (COW /workspace)    │    │                                   │
│  │  ├──────────────────────┤    │                                   │
│  │  │  sidecar: telemetry  │    │                                   │
│  │  │  (logs/metrics/      │    │                                   │
│  │  │   events/syscalls)   │    │                                   │
│  │  └──────────────────────┘    │                                   │
│  └──────────────────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────┘
              │
┌─────────────▼─────────────────────────────────────────────────────┐
│                        Persistence Layer                           │
│                                                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │
│  │ Artifact │ │   Log    │ │ Metrics  │ │  Traces  │ │ Search │  │
│  │   Store  │ │  Store   │ │  Store   │ │  Store   │ │ Index  │  │
│  │   (S3)   │ │  (Loki)  │ │ (Prom.)  │ │ (Tempo)  │ │        │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └────────┘  │
└─────────────┬─────────────────────────────────────────────────────┘
              │
┌─────────────▼─────────────────────────────────────────────────────┐
│                     External Integrations                          │
│                                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐    │
│  │   GitHub     │  │   Graphite   │  │    Spec Resolver      │    │
│  │  Integration │  │  (PR stacks) │  │  (pre-flight artifact │    │
│  │  Service     │  │              │  │   validation)         │    │
│  └──────────────┘  └──────────────┘  └───────────────────────┘    │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐      │
│  │   Tool Gateway (audited proxy for external tool calls)   │      │
│  └──────────────────────────────────────────────────────────┘      │
└────────────────────────────────────────────────────────────────────┘
```

---

## 6. Component Definitions

### 6.1 Control Plane

#### API Service

The single entry point for all external callers. Authenticates requests, validates input format, and forwards to the Orchestrator. Stateless — scales horizontally behind a load balancer.

Exposes:

| Endpoint | Purpose |
|---|---|
| `POST /runs` | Submit a run request |
| `GET /runs/{id}` | Poll status and metadata |
| `DELETE /runs/{id}` | Cancel an in-progress run |
| `GET /runs/{id}/artifacts` | Retrieve declared outputs |
| `GET /runs/{id}/logs` | Stream or retrieve structured logs |

#### Orchestrator

The core state machine. Owns run lifecycle transitions:

```
submitted → validated → scheduled → launching → running → completing → done
                                                         → failed
                                                         → cancelled
                                                         → timed_out
```

Responsibilities:

- Invokes the Spec Resolver to validate planning artifacts and package the immutable input bundle
- Writes run records to the State Store
- Publishes state transition events to the Event Bus
- Monitors heartbeats from running agent pods
- Triggers timeout logic when heartbeats are absent beyond the configured threshold
- Makes retry decisions for transient infrastructure failures
- Does not retry logical task failures (agent produced wrong output) — those surface as failed runs for human review

Multiple instances run concurrently using optimistic locking on the State Store.

#### Scheduler

Determines when and where work executes. Separate from the Policy Service so that scheduling logic (priority, resource matching, affinity) can evolve independently from admission logic (quotas, guardrails).

Responsibilities:

- Selects the appropriate priority lane (critical, standard, background, retry)
- Matches runs to execution classes based on declared task complexity or default
- Enforces scheduling constraints (affinity, anti-affinity in Phase 3)
- Places dispatch messages on the Work Queue

#### Policy Service

The admission and guardrail layer. Evaluates every run request before it is accepted.

Policy checks include:

- Task must have `status:ready` on its GitHub Issue
- All upstream task dependencies must be `status:done`
- Input bundle must resolve to valid, approved planning artifacts
- Execution class must be within the team's quota balance
- Image allowlist: only pre-approved agent images may be launched
- Tool access: only tools declared in the task may be granted egress

The Policy Service is a distinct component so that guardrails can be updated, tested, and audited independently from orchestration logic. It is the enforcement point for all organizational rules about what agents may do.

#### State Store

PostgreSQL. Stores:

- Run records (ID, status, input bundle reference, timestamps, owner, team, execution class)
- Append-only state transition log (event-sourced)
- Checkpoint records for multi-step runs
- Artifact manifests declared on completion
- Quota and credit balances per team
- Audit events for policy decisions, secret access, human overrides, and artifact publication

ACID guarantees are required. The append-only transition log must never be mutated. Quota balances require transactional updates.

---

### 6.2 Message Layer

Work dispatch and lifecycle telemetry are deliberately separated into two systems with different semantics.

#### Work Queue

A durable, ordered queue with priority lanes. Provides at-least-once delivery. Worker Controllers use idempotency keys to prevent double-execution.

| Lane | Trigger | Example |
|---|---|---|
| `critical` | Manual escalation | Incident response tasks |
| `standard` | Default for all feature work | Normal implementation tasks |
| `background` | Non-blocking review sweeps | Architecture review runs |
| `retry` | Transient failure backoff | Automatic re-dispatch with delay |

Partitioned by lane. In multi-tenant deployments, further partitioned by team to prevent burst from one team starving another.

The Work Queue and Event Bus must remain separate systems. The queue provides consumer-group semantics and dead-letter handling for work that cannot be processed. The Event Bus provides fan-out to multiple independent consumers for the same lifecycle event. A single unified messaging system cannot serve both models cleanly.

#### Event Bus

Publishes domain events for all run lifecycle transitions, artifact declarations, heartbeats, and checkpoint completions. Consumers are decoupled from producers.

Consumers include:

- GitHub Integration Service (Issue label sync, PR comments)
- Observability pipeline (metrics on state transitions)
- Audit logger (append immutable audit record)
- Future: notification services, webhook triggers, billing pipeline

#### Dead Letter Queue

Receives messages that fail all retry attempts. An operator alert fires on any DLQ activity. Messages are never silently dropped or discarded.

---

### 6.3 Execution Plane

#### Worker Controller (Kubernetes Operator)

A custom Kubernetes operator that manages the agent pod lifecycle in response to dispatch messages from the Work Queue.

Responsibilities:

- Dequeues dispatch messages from the Work Queue
- Creates `AgentRun` custom resources in Kubernetes (enabling `kubectl get agentruns` visibility and GitOps-compatible management)
- Launches agent pods with correct image, resource limits, security context, volumes, and network policy
- Monitors pod phase and reports transitions back to the Orchestrator
- Enforces maximum run duration by force-terminating pods that exceed the execution class timeout
- Cleans up completed pods and releases ephemeral storage volumes

#### Agent Pod

Each run executes in a dedicated, isolated pod. The pod has three containers:

```
Pod
├── init-container: bundle-fetcher
│     Downloads and validates the immutable input bundle from the artifact store
│     Unpacks to /workspace/input/ (read-only bind mount for agent container)
│
├── container: agent
│     The agent runtime (Claude CLI, Codex CLI, Gemini CLI, or pluggable custom runtime)
│     Non-root (UID 10000), read-only root filesystem, no privilege escalation
│     All capabilities dropped, seccomp profile: RuntimeDefault
│     Writes exclusively to /workspace/ (ephemeral COW overlay)
│     Credentials injected via mounted secret volumes, not environment variables
│     Network egress restricted to allowlisted endpoints per execution class
│
└── sidecar: telemetry-relay
      Tails /workspace/logs/execution.jsonl — ships to Loki
      Scrapes agent metrics endpoint — forwards to Prometheus
      Streams heartbeats to Event Bus every 30 seconds
      Captures syscall audit log stream if gVisor runtime is active
      Forwards lifecycle events to Event Bus
```

The agent process has access to:

- The unpacked input bundle at `/workspace/input/` (read-only)
- A writable `/workspace/` directory using a COW overlay filesystem — the base image provides the toolset (git, language runtimes, Graphite CLI); the writable overlay captures only the agent's changes
- Credentials scoped to the run, injected as projected secret volumes
- Network egress to allowlisted endpoints only

The agent process does not have access to:

- The host network, host filesystem, or host IPC namespace
- Other pods, namespaces, or their volumes
- Credentials outside the declared scope of the current task
- Unrestricted internet egress

#### Workspace and Artifact Model

```
/workspace/
├── input/           (read-only — unpacked input bundle)
│   ├── task.json    (task ID, acceptance criteria, dependencies)
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── config.json  (execution class, tool grants, credential refs)
├── repo/            (git clone of target repository at specified commit SHA)
├── logs/
│   └── execution.jsonl   (structured JSONL, tailed by telemetry sidecar)
├── checkpoints/     (durable step state for resumable multi-step workflows)
└── output/
    └── manifest.json     (agent declares what it produced before exit)
```

On completion, the workspace manager reads `manifest.json`, validates declared artifacts exist, pushes them to the artifact store, records artifact references in the State Store, and releases the ephemeral volume.

---

### 6.4 Persistence Layer

| Store | Purpose | Technology (Candidate) |
|---|---|---|
| Metadata | Run records, state transitions, quotas, manifests, checkpoints | PostgreSQL |
| Artifacts | Input bundles, output artifacts, execution bundles | S3-compatible object storage |
| Logs | Structured log aggregation, queryable by run ID | Loki |
| Metrics | System and per-run metrics with long-term retention | Prometheus + Thanos |
| Traces | Distributed traces across control plane and execution pods | Tempo |
| Search Index | Fast cross-artifact and cross-log query across runs | To be determined via ADR |

All stores are write-once or append-only for execution data. Operational data (quotas, config) is mutable under controlled access.

The Search Index — enabling fast lookup across logs, artifacts, and traces by run ID, task ID, team, or text content — is included at the persistence layer from the outset. Retrofitting search capability after the fact is expensive; the index schema should be defined during Phase 1 even if population is deferred.

---

### 6.5 External Integrations

#### Spec Resolver

Invoked by the Orchestrator on every run submission before any execution resource is consumed.

Validates:

- `spec.md` exists at the specified commit SHA and is not in draft state
- `plan.md` exists and references the spec
- `tasks.md` contains the requested task with explicit acceptance criteria and required tests
- All ADRs referenced by the task exist in `docs/adr/`
- Task status on GitHub Issue is `status:ready`
- All upstream task dependencies are `status:done`

If validation fails, the run is rejected with a structured error. No pod is created, no queue message is published, no quota is consumed.

On success, the Spec Resolver packages the validated artifacts into a versioned input bundle, uploads it to the artifact store, and returns the bundle reference to the Orchestrator.

#### GitHub Integration Service

Listens to the Event Bus and maps run lifecycle events to GitHub actions. Agents do not call the GitHub API directly — all GitHub state changes flow through this service.

| Run Event | GitHub Action |
|---|---|
| `run.launched` | Issue label set to `status:in-progress` |
| `run.completed` | PR confirmed open, Issue label set to `status:in-review` |
| `run.failed` | Issue comment posted with structured failure summary |
| `run.cancelled` | Issue comment posted, label reverted to `status:ready` |
| `run.timed_out` | Issue comment posted, label set to `status:blocked` |

Uses a GitHub App with minimum required scopes, scoped per repository.

#### Tool Gateway

An audited proxy through which agent external tool calls are routed. Rather than allowing direct egress to all tool APIs, agents call the Tool Gateway, which:

- Validates the tool is declared in the task's config
- Logs the call (tool name, arguments, caller run ID, timestamp)
- Rate-limits calls per run and per team
- Forwards to the upstream API
- Returns the response to the agent

The Tool Gateway provides a single enforcement and audit point for all external tool use. It enables after-the-fact review of what every agent called, with what arguments, during any run.

---

## 7. Agent Lifecycle — Full Flow

```
1.  Caller submits POST /runs with {task_id, repo, commit_sha, execution_class, config}

2.  API Service authenticates caller → forwards to Policy Service
    Policy Service evaluates admission rules → admits or rejects with structured reason

3.  Orchestrator invokes Spec Resolver:
    - Fetches spec.md, plan.md, tasks.md at commit_sha
    - Validates task readiness and upstream dependencies
    - Packages immutable input bundle → uploads to S3 → returns bundle_ref

4.  Orchestrator writes run record to PostgreSQL (status: scheduled)
    Publishes run.scheduled event to Event Bus

5.  Scheduler selects priority lane and execution class
    Places dispatch message on Work Queue

6.  Worker Controller dequeues dispatch message:
    - Creates AgentRun CRD in Kubernetes
    - Creates Pod (init container + agent + sidecar) with:
        - Resource limits and timeout per execution class
        - Security context (non-root, read-only FS, dropped capabilities, seccomp)
        - Container runtime per execution class (containerd or gVisor)
        - Network policy (deny-all default + execution class egress allowlist)
        - Projected secret volumes (short-lived, scoped credentials)
    - Reports pod creation to Orchestrator (status: launching)

7.  init container downloads and validates input bundle → unpacks to /workspace/input/

8.  Agent container starts:
    - Reads task from /workspace/input/task.json
    - Clones repository at commit_sha to /workspace/repo/
    - Executes task following implementation process protocol:
        → Create branch t-<##>-<slug>
        → Write failing test for first acceptance criterion
        → Write minimum production code to pass test
        → Refactor without changing behavior
        → Commit: <type>(<scope>): <description> (T-##)
        → Repeat TDD cycle per criterion
        → Push branch
        → Open PR via Graphite
        → Write checkpoint after each externally visible action
    - Writes manifest.json to /workspace/output/
    - Emits heartbeats every 30s via telemetry sidecar

9.  Orchestrator monitors heartbeats and pod phase:
    - Heartbeat silent > class timeout → marks timed_out, kills pod
    - Pod exits 0 → triggers completion flow
    - Pod exits non-zero → triggers failure / retry evaluation

10. On pod exit 0:
    - Workspace manager reads manifest.json, validates artifacts, pushes to S3
    - Orchestrator marks run done, records artifact references in PostgreSQL
    - GitHub Integration Service posts PR confirmation, updates Issue label to in-review
    - Event Bus receives run.completed

11. Ephemeral COW overlay purged. AgentRun CRD deleted. Pod terminated.
```

---

## 8. Isolation Model

### Container Security Context

All agent containers run with:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
seccompProfile:
  type: RuntimeDefault
```

### Container Runtime

| Execution Class | Runtime | Reason |
|---|---|---|
| nano, small, medium, large | containerd | Standard isolation, lower latency |
| secure | gVisor (runsc) | Syscall-level kernel sandboxing |

The `secure` execution class is applied to tasks touching authentication, session management, persistent data stores, secrets, or platform infrastructure — workloads where a compromised agent poses the highest risk.

gVisor provides a guest kernel that intercepts all syscalls before they reach the host kernel, enabling both strong isolation and syscall-level audit logging. The telemetry sidecar captures the gVisor audit log stream and ships it to the log store alongside application logs.

Teams or security policies may escalate any run to the `secure` class. The default for all other tasks is `containerd`.

### Network Policy

Each pod operates under deny-all ingress and deny-all egress as the baseline. Egress allowances are granted per execution class:

| Class | Allowed Egress |
|---|---|
| `restricted` | Model API only |
| `standard` | Model API, GitHub API, artifact store, Tool Gateway |
| `extended` | Above + package registries (npm, pip, crates.io) |

Egress is enforced at the Kubernetes NetworkPolicy level. No in-process configuration can override it.

External tool calls route through the Tool Gateway, not directly to external APIs. This gives the gateway visibility and control over all external calls regardless of execution class.

### Credential Isolation

Credentials are injected as projected Kubernetes secret volumes, not as environment variables visible in pod specs or admission webhooks. Secrets are scoped to the minimum repository, tool, and API access required by the task.

Cloud-hosted deployments use IRSA (AWS) or Workload Identity (GCP) to issue short-lived cloud credentials to pods without long-lived keys in any configuration.

Secrets are revoked or expire at run completion.

### Namespace Isolation

```
archive-control-plane    — API Service, Orchestrator, Scheduler, Policy Service
archive-workers-prod     — Production agent pods
archive-workers-staging  — Staging agent pods
archive-integrations     — GitHub Integration Service, Spec Resolver, Tool Gateway
```

Resource quotas are enforced at the namespace level. Control plane components cannot be resource-starved by a burst of agent runs.

---

## 9. Execution Classes

| Class | CPU | Memory | Storage | Timeout | Runtime | Use Case |
|---|---|---|---|---|---|---|
| `nano` | 0.1 | 256 MB | 1 GB | 5 min | containerd | Metadata operations, status checks |
| `small` | 0.5 | 1 GB | 5 GB | 30 min | containerd | Simple bug fixes, isolated changes |
| `medium` | 2.0 | 4 GB | 20 GB | 2 hr | containerd | Standard implementation tasks |
| `large` | 4.0 | 8 GB | 50 GB | 4 hr | containerd | Complex multi-file tasks, architecture work |
| `gpu` | 2.0 + GPU | 16 GB | 50 GB | 4 hr | containerd | Model inference, local embedding, data-heavy tasks |
| `secure` | 2.0 | 4 GB | 20 GB | 2 hr | gVisor | Auth, secrets, persistence, platform tasks |

The Scheduler selects the execution class from the task's declared complexity in `tasks.md`, falling back to `medium` if not specified. Operators may override the class via the API.

---

## 10. Scalability Strategy

### Control Plane

All control plane services (API, Orchestrator, Scheduler, Policy Service) are stateless. They run as Kubernetes Deployments with Horizontal Pod Autoscalers driven by CPU and request rate. Any instance can be terminated and replaced without state loss.

### Worker Autoscaling

Worker capacity is driven by queue depth using KEDA (Kubernetes Event-Driven Autoscaling). Each priority lane scales independently:

| Lane | Min Replicas | Max Replicas | Scale-Up Trigger |
|---|---|---|---|
| critical | 1 | 20 | queue depth > 0 |
| standard | 2 | 100 | queue depth > 5 |
| background | 0 | 20 | queue depth > 10 |
| retry | 0 | 10 | queue depth > 0 |

Node pools are pre-warmed with placeholder pods to reduce cold-start latency. Cluster autoscaling provisions new nodes when pending worker replicas cannot be scheduled.

### Queue Partitioning

Queues are partitioned by priority lane. In multi-tenant deployments, further partitioned by team to prevent one team's burst from starving another's capacity.

### Database Scaling

PostgreSQL scales vertically for Phase 1. Phase 2 adds read replicas for query offload and PgBouncer for connection pooling. Phase 3 partitions the run records table by `run_id` to support horizontal sharding if write throughput demands it.

### Workflow Engine (Long-Lived Stateful Graphs)

The dependency sequencing in this architecture handles most multi-task coordination through orchestrator-enforced dispatch ordering. If the system needs to support long-lived, deeply stateful agent graph execution — where agent runs spawn child runs, fan out to many parallel sub-agents, and aggregate results across many levels — encoding that workflow inside pods is the wrong approach. In that scenario, a dedicated workflow engine (such as Temporal or Argo Workflows) should sit above Kubernetes, managing graph execution while the existing pod infrastructure handles individual leaf-level runs. This decision is deferred to Phase 2 based on observed usage patterns.

---

## 11. Observability

Operators should be able to answer four questions quickly and without special tooling:

1. **What is running now?** — Live view of queued, launching, and running agent pods
2. **Why is a run blocked or slow?** — Trace from submission through scheduling, queue depth, and pod events
3. **What did a specific agent do?** — Full structured log for any run, queryable by run ID
4. **Which resource or policy limit caused the issue?** — Policy Service decisions and quota state in the audit log

### Structured Logs

All components emit structured JSONL. Agents write to `/workspace/logs/execution.jsonl`. The telemetry sidecar ships these to Loki indexed by `run_id`, `task_id`, `team`, `status`, and `phase`.

Required fields per log line:

```json
{
  "ts": "2026-03-13T10:00:00Z",
  "level": "info",
  "run_id": "run_abc123",
  "task_id": "T-07",
  "team": "platform",
  "phase": "implement",
  "event": "tdd_cycle_complete",
  "cycle": 3,
  "test_status": "green"
}
```

When the `secure` execution class is active, the telemetry sidecar also captures the gVisor syscall audit stream alongside application logs. This provides a complete record of every system call the agent made.

### Metrics

| Metric | Type | Labels |
|---|---|---|
| `agentic_runs_total` | Counter | status, team, execution_class |
| `agentic_run_duration_seconds` | Histogram | execution_class, status |
| `agentic_queue_depth` | Gauge | lane |
| `agentic_worker_utilization` | Gauge | node_pool |
| `agentic_artifact_size_bytes` | Histogram | artifact_type |
| `agentic_run_cost_credits` | Counter | team, execution_class |
| `agentic_retry_total` | Counter | team, failure_reason |

The `agentic_run_cost_credits` metric enables cost attribution per team and execution class. Cost accounting is a first-class observability concern, not an afterthought.

### Distributed Traces

OpenTelemetry traces span from API submission through Policy Service, Orchestrator, Scheduler, Work Queue dispatch, Worker Controller, pod launch, and artifact persistence. Trace context is propagated into the agent container via environment variable, enabling correlation between control plane spans and agent-internal steps.

### Alerts

| Alert | Condition | Severity |
|---|---|---|
| DLQ non-empty | DLQ depth > 0 for 5 min | Warning |
| High failure rate | > 10% of runs failed in 15 min | Critical |
| Queue saturation | Standard lane depth > 50 for 10 min | Warning |
| Orchestrator degraded | Healthy orchestrator replicas < 1 | Critical |
| Timeout spike | > 5 timeouts in 10 min | Warning |
| Quota exhaustion | Team quota at 100% for 5 min | Warning |
| Policy rejection rate | > 20% of submissions rejected in 15 min | Warning |

### Dashboards

A canonical Grafana dashboard per environment exposes:

- Live queue depth by lane
- Run status breakdown (running / completed / failed / timed out, last 24h)
- P50/P95/P99 run duration by execution class
- Worker utilization and pending pod count
- DLQ depth (alert fires on any non-zero value)
- Quota utilization by team
- Cost credits consumed by team and execution class

---

## 12. Multi-Agent Coordination

### Fan-Out (Parallel)

When a feature's tasks are independent, all may be submitted simultaneously. The Scheduler dispatches them in parallel up to quota limits. Each executes in its own isolated pod. The Orchestrator tracks completion and marks the feature complete when all tasks reach `done`.

### Dependency Chains (Sequential)

When task B declares a dependency on task A in `tasks.md`, the Scheduler will not dispatch B until A reaches `done` and its artifacts are committed to the repository. The Spec Resolver re-validates the input bundle for B against the updated repository state post-A merge, ensuring B receives the correct base commit.

This prevents conflicts from simultaneous modification of the same files and ensures dependent agents receive correct base state without requiring agents to coordinate directly.

### Conflict Detection

Before dispatching any run, the Scheduler checks whether another in-progress run has checked out a branch touching overlapping file paths. Conflicting runs are held in the queue rather than dispatched in parallel, preventing merge conflicts by construction. The conflict scope (file-level, directory-level, or branch-level) is a decision to be made via ADR.

---

## 13. Integration with Existing Processes

### Planning Process

The Spec Resolver enforces the planning gate. A run cannot be admitted unless `spec.md`, `plan.md`, and `tasks.md` are present, approved, and consistent. The Spec Resolver validates that any ADRs required by the task exist before packaging the input bundle. Agents receive planning artifacts as read-only inputs; they cannot modify or substitute them during execution.

### Tracking Process

The GitHub Integration Service maintains Issue state in sync with run state. Issue labels are applied and removed in response to Event Bus events — agents do not call the GitHub API directly for status updates. This keeps the tracking source of truth (GitHub Issues) accurate without giving agents direct write access to issue state outside their declared outputs.

### Implementation Process

Agent containers are pre-configured with the Graphite CLI and the branch naming convention (`t-<##>-<slug>`), commit format (`<type>(<scope>): <description> (T-##)`), and TDD cycle protocol defined in the implementation process. The agent protocol — write failing test, write minimum code, refactor, commit, repeat — is enforced by the agent runtime's internal loop. A run that exits without evidence of a passing test suite in its execution log is marked failed.

### Review Process

A review agent is submitted as a distinct run type. Its input bundle includes the PR diff, the linked spec/plan/tasks, and any referenced ADRs. It follows the four-tier review protocol, produces a structured `review.json` output with verdict (reject/revise/approve) and ordered findings keyed to file and line, and writes it to `/workspace/output/`. The GitHub Integration Service posts the structured review as a GitHub PR review via the API.

---

## 14. Security Model Summary

| Layer | Control |
|---|---|
| Container | Non-root, read-only FS, all capabilities dropped, seccomp RuntimeDefault |
| Runtime | containerd by default; gVisor for `secure` execution class |
| Syscall audit | gVisor audit stream captured by telemetry sidecar for `secure` class runs |
| Network | Deny-all default, execution-class egress allowlist enforced at NetworkPolicy |
| Tool access | Routed through audited Tool Gateway, not direct egress |
| Credentials | Short-lived, scoped per run, mounted as projected secrets not env vars |
| Cloud identity | IRSA (AWS) or Workload Identity (GCP) — no long-lived keys |
| Image supply chain | Signed images, digest pinning, SBOM generation |
| Admission | Policy Service enforces quota, artifact validity, and tool grants before launch |
| Audit | Append-only event log (State Store) for all run transitions, policy decisions, and artifact publication |
| Secret lifecycle | Credentials revoked or expired at run completion |

---

## 15. Technology Stack Candidates

These are candidate recommendations, not decisions. Each requires ADR ratification.

| Concern | Candidate | Rationale |
|---|---|---|
| Container orchestration | Kubernetes (EKS or GKE) | Mature, broad ecosystem, KEDA and operator support |
| Container runtime (default) | containerd | Default for EKS/GKE, stable, well-supported |
| Container runtime (secure) | gVisor (runsc) | Syscall-level sandboxing, audit log stream, no full VM overhead |
| Message queue + event bus | NATS JetStream | Lightweight, built-in persistence, simpler than Kafka, sufficient for initial scale |
| Metadata store | PostgreSQL (Aurora Serverless v2) | ACID, optimistic locking, proven, scales from dev to production |
| Artifact store | S3-compatible | Durable, cost-effective, universal API |
| Log aggregation | Grafana Loki | Integrates with Prometheus/Tempo, structured query by label |
| Metrics | Prometheus + Thanos | KEDA integration, standard, long-term retention via Thanos |
| Tracing | Grafana Tempo | Unified stack with Loki and Prometheus |
| Search index | TBD (Elasticsearch, OpenSearch, or Postgres full-text) | Requires ADR |
| Autoscaling | KEDA | Queue-depth-driven, integrates with NATS |
| Secret management | AWS Secrets Manager + IRSA | Cloud-native, no separate infrastructure |
| GitOps / deploy | Argo CD | Kubernetes-native, audit trail, rollback |
| Ingress | Cloud-native load balancer | Managed TLS, WAF integration |
| Workflow engine (if needed) | Temporal or Argo Workflows | Deferred to Phase 2 ADR |

NATS JetStream is preferred over Kafka for Phase 1 because it requires no ZooKeeper or separate broker management and its throughput is more than sufficient for agentic workloads at initial scale. Kafka remains an option if Phase 3 retention or throughput requirements exceed NATS capacity.

---

## 16. Phased Delivery

### Phase 1: MVP — Single Region, Core Execution

**Target**: 10–20 simultaneous agent runs. End-to-end lifecycle. Basic observability.

Deliverables:

- API Service (submit, poll, cancel)
- Orchestrator with full state machine
- Policy Service with admission rules and quota enforcement
- Spec Resolver validating planning artifacts pre-flight
- Worker Controller (Kubernetes Operator) with AgentRun CRD
- Ephemeral agent pods (init container + agent + telemetry sidecar) with standard security context
- COW overlay workspace with artifact manifest validation
- Artifact persistence to S3 on completion
- GitHub Integration Service (Issue label sync, PR confirmation)
- Tool Gateway (audited proxy for external tool calls)
- Single priority lane (standard) — additional lanes in Phase 2
- Retry on transient infrastructure failure (max 2 retries with exponential backoff)
- Timeout enforcement per execution class
- Structured log shipping to Loki
- Basic Grafana dashboard (queue depth, run status, duration, DLQ depth)
- PostgreSQL State Store with append-only transition log
- Checkpoint model (schema defined; basic write-on-milestone in agent runtime)

ADRs required before Phase 1 begins:

1. Compute substrate and cloud provider
2. Container runtime strategy (gVisor scope)
3. Message infrastructure (NATS JetStream vs alternatives)
4. Metadata store
5. Artifact store
6. Secret management approach
7. Observability stack

### Phase 2: Operational Maturity

**Target**: 100+ simultaneous runs. Full observability. Multi-team quota enforcement. Secure execution class.

Deliverables:

- All four priority lanes (critical, standard, background, retry)
- Full execution class taxonomy including `gpu` and `secure`
- KEDA autoscaling per lane with defined min/max/trigger values
- gVisor runtime for `secure` execution class with syscall audit log capture
- Per-team quota and credit system with cost attribution metric
- Full OpenTelemetry integration (structured traces, context propagation into pods)
- Prometheus + Thanos for long-term metrics retention
- Named alert rules with severity and thresholds
- Search index populated from run logs and artifacts
- Multi-agent coordination: dependency chain enforcement and conflict detection
- Review agent run type with structured verdict output
- Checkpoint-based resumption for failed runs
- Workflow engine evaluation: determine if Temporal/Argo Workflows is needed

ADRs required:

8. Multi-tenant quota and fairness model
9. Execution class taxonomy and resource values
10. Multi-agent conflict detection scope
11. Multi-agent dependency enforcement mechanism
12. Workflow engine decision (orchestrator-enforced sequencing vs dedicated engine)

### Phase 3: Multi-Region and Multi-Tenant

**Target**: Geographically distributed execution. Organizational-level tenancy with strong isolation boundaries.

Deliverables:

- Regional worker pools with control plane federation
- Cross-region artifact replication
- Tenant-level namespace isolation with dedicated worker pools
- Advanced scheduling (affinity, anti-affinity, geographic preference)
- Event-driven run triggers (GitHub webhook on Issue label change, scheduled cron, PR merged)
- Audit export to SIEM
- SLA tracking per tenant and execution class
- Operator runbooks and on-call playbooks

ADRs required:

13. Multi-region topology and failover policy
14. Tenant isolation model (namespace vs cluster boundary)
15. Event-driven trigger architecture

---

## 17. ADR Backlog

All of the following must be resolved as ADRs in `docs/adr/` before their associated phase begins. No implementation may proceed on a component without its governing ADR.

| # | Decision | Options | Phase |
|---|---|---|---|
| ADR-001 | Compute substrate and cloud provider | EKS, GKE, self-hosted | 1 |
| ADR-002 | Container runtime strategy | containerd default + gVisor for secure class; gVisor for all | 1 |
| ADR-003 | Message queue and event bus | NATS JetStream, Kafka, SQS+SNS | 1 |
| ADR-004 | Metadata store | PostgreSQL (Aurora), CockroachDB | 1 |
| ADR-005 | Artifact and log storage | S3, GCS, Cloudflare R2 | 1 |
| ADR-006 | Secret management | AWS Secrets Manager + IRSA, HashiCorp Vault | 1 |
| ADR-007 | Observability stack | Grafana (Loki+Prometheus+Tempo), Datadog, CloudWatch | 1 |
| ADR-008 | Multi-tenant quota model | Credit-based, hard limits, soft limits with burst | 2 |
| ADR-009 | Execution class taxonomy and values | As proposed in Section 9 | 2 |
| ADR-010 | Multi-agent conflict detection scope | File-level, directory-level, branch-level | 2 |
| ADR-011 | Multi-agent dependency enforcement | Orchestrator-enforced dispatch ordering vs queue-level gates | 2 |
| ADR-012 | Workflow engine | Orchestrator sequencing sufficient vs Temporal vs Argo Workflows | 2 |
| ADR-013 | Search index | Elasticsearch, OpenSearch, Postgres full-text | 2 |
| ADR-014 | Multi-region topology | Active-active, active-passive, regional-primary | 3 |
| ADR-015 | Tenant isolation model | Namespace-level quotas, dedicated node pools, or separate clusters | 3 |
| ADR-016 | Event-driven trigger architecture | GitHub App webhooks, polling, dedicated trigger service | 3 |

---

## 18. Open Questions

These questions are not resolved in this proposal and must be answered before or during Phase 1 planning:

1. **Agent runtime selection**: Which agent runtimes are supported at launch — Claude CLI only, or also Codex, Gemini, custom? Does the execution plane enforce a single runtime or support pluggable runtimes via an interface?

2. **Repository access model**: Does each pod clone the repository directly via Git, or is a pre-cloned snapshot included in the input bundle? Git clone is simpler; pre-cloned is more reproducible and faster at pod start.

3. **Run triggering in Phase 1**: Manual API submission only, or also a GitHub webhook trigger when an Issue moves to `status:ready`?

4. **Human approval gate**: Should any run type require explicit human approval before dispatch? If yes, where is that gate enforced — in the Policy Service, the API, or a separate approval workflow?

5. **Retention policy**: How long are run records, logs, and artifacts retained? What is the deletion policy for completed runs, and does it differ by execution class or team?

6. **Model API cost isolation**: How are model API inference costs attributed per run? Is there a per-run budget cap, and does the Policy Service enforce it at admission time?

7. **Local development mode**: How do engineers run the system locally? Is there a local mode that replaces Kubernetes with Docker Compose or a similar substrate without full cluster setup?

8. **Agent runtime trust boundary**: Is the concern that an agent is exploited by external input, or that the agent itself behaves adversarially? The answer determines whether gVisor-by-default is warranted.

---

## 19. What Each Prior Proposal Contributed

This merged document draws from all three independently authored proposals. The contributions are documented here for traceability.

**From `docs/codex/architecture-proposal.md`**:
- Failure domain isolation as a named foundational principle (Section 4.2)
- Checkpointing / resumable step pattern (Section 4.9, Section 7)
- GPU execution class in the execution class taxonomy (Section 9)
- Four operator questions as the observability charter (Section 11)
- Cost per run as a named metric (Section 11)
- Workflow engine recommendation for stateful agent graphs (Section 10)
- Policy Service as a distinct named component (Section 6.1)
- Search index in the persistence layer (Section 6.4)
- Tool Gateway as an audited proxy for external tool calls (Section 6.5)
- Conceptual framework for Work Queue / Event Bus / DLQ separation (Section 6.2)

**From `docs/gemini/architecture-proposal.md`**:
- Copy-on-write (COW) overlay filesystem as the explicit workspace mechanism (Sections 6.3, 7)
- gVisor and Kata Containers named as the security-boundary runtime option (Section 8)
- Syscall-level audit log capture via telemetry sidecar (Section 11)
- NATS as the event mesh candidate (Section 15)
- Clean six-step lifecycle flow (synthesized into the fuller flow in Section 7)

**From `docs/claude/architecture-proposal.md`**:
- Append-only execution records as a named foundational principle (Section 4.7)
- Explicit artifact declaration and manifest validation model (Sections 4.6, 6.3)
- Spec Resolver as an architectural component (Section 6.5)
- GitHub Integration Service with event-to-label mapping table (Section 6.5)
- Conflict detection for parallel agent branch collisions (Section 12)
- Review agent as a distinct run type (Section 13)
- Network egress tiers (Section 8)
- IRSA / Workload Identity for cloud credentials (Section 8)
- KEDA with per-lane scaling parameters (Section 10)
- Named Prometheus metrics with labels (Section 11)
- Alert rules with conditions and severity (Section 11)
- JSONL log schema with required fields (Section 11)
- Namespace isolation topology (Section 8)
- Explicit security context YAML (Section 8)
- Numbered ADR backlog with options and phases (Section 17)
- Open questions section (Section 18)
- Integration mapping to all four existing processes (Section 13)

---

*This document is pre-ADR input. All significant decisions identified in Section 17 must be elevated to Architecture Decision Records in `docs/adr/` before implementation planning begins for any phase.*
