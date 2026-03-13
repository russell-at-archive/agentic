# Agentic Execution Architecture

**Date**: 2026-03-13
**Status**: Pre-ADR. Significant decisions identified in the ADR backlog must be elevated to `docs/adr/` before implementation begins.

---

## 1. Problem Statement

The process framework defined in this repository expects agents to execute approved tasks autonomously: create branches, write code following TDD, commit, open pull requests, update GitHub Issues, and produce reviewable outputs. The current gap is a missing execution substrate. No system exists to launch agents, isolate them from one another, manage their lifecycle, persist their outputs, or give operators visibility into what is happening.

This document defines the architecture that fills that gap.

---

## 2. Scope and Non-Goals

**In scope**: the execution substrate — how agents are launched, isolated, scheduled, observed, and integrated with the existing process framework.

**Not in scope**:
- The internal reasoning loop or prompting strategy of any agent model
- Final vendor or product selection — those are ADR decisions
- Agents as long-lived stateful services — workers are ephemeral and disposable
- Encoding workflow graph semantics inside individual containers

---

## 3. Foundational Principles

These principles govern every component and every trade-off. They are non-negotiable inputs to all subsequent ADR decisions.

### 3.1 Control Plane / Data Plane Separation

Orchestration logic — what should run, when, with what configuration, under what policy — is strictly separated from execution logic — how an agent operates inside a container. Each layer scales and evolves independently.

### 3.2 Failure Domain Isolation

One bad agent run must not affect unrelated runs. Every boundary between components is designed to contain failures. A stuck or crashing pod surfaces a recoverable error for that run only; it does not degrade the scheduler, the queue, or the control plane.

### 3.3 Stateless Orchestration Backed by Durable State

Orchestrators and schedulers carry no in-memory state that cannot be reconstructed from the database. Any control plane instance can be restarted or replaced without losing run state, enabling zero-downtime deployments and resilience to control plane failures.

### 3.4 Immutable Input Bundles

Before a run starts, the system resolves all planning artifacts — `spec.md`, `plan.md`, `tasks.md`, task context, and configuration — into a versioned, immutable bundle written to object storage. The agent receives a reference to that bundle. Nothing in the bundle changes during the run. Every run is therefore reproducible and free from mid-flight configuration drift.

### 3.5 Ephemeral Execution Environments

Agent containers are created fresh per run and destroyed after completion. No state persists in the execution environment between runs. All meaningful output is declared and pushed to durable storage before the container exits.

### 3.6 Explicit Artifact Declaration

Agents do not have write access to arbitrary locations. They declare their outputs using a structured manifest written before exit. A workspace manager validates that declared artifacts exist and pushes them to durable storage. Undeclared side effects are not permitted.

### 3.7 Append-Only Execution Records

Run state transitions, events, log lines, and artifact references are written as append-only records. Nothing is mutated or deleted during or after a run. This makes the audit trail durable, reconstructible, and tamper-evident.

### 3.8 Coordination Through the Control Plane

Agents do not communicate with each other directly. They do not shell into peer containers or share writable filesystems with concurrent runs. Shared context moves through persisted artifacts, event streams, and task contracts managed by the control plane. Cross-agent locks, when needed, are held centrally. This keeps agents embarrassingly parallel for most workloads and prevents container networking from becoming an ad hoc distributed system.

### 3.9 Checkpointing for Resumable Execution

Multi-step agent workflows decompose into resumable steps with durable checkpoints between externally visible actions. A transient failure does not require replaying work already durably committed. Expensive or irreversible operations — pushing a commit, opening a PR, updating an Issue — are checkpointed so retry logic does not repeat them.

---

## 4. Architecture Overview

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
│  │ critical / standard  │  │  (lifecycle      │  │  Queue        │  │
│  │ background / retry   │  │   fan-out)       │  │               │  │
│  └──────────┬───────────┘  └────────┬─────────┘  └───────────────┘  │
└─────────────┼──────────────────────┼────────────────────────────────┘
              │                      │
┌─────────────▼──────────────────────┼────────────────────────────────┐
│            Execution Plane         │                                │
│                                    │                                │
│  ┌─────────────────────────┐       │                                │
│  │  Worker Controller      │       │                                │
│  │  (Kubernetes Operator)  │       │                                │
│  └────────────┬────────────┘       │                                │
│               │ creates            │                                │
│  ┌────────────▼─────────────────┐  │                                │
│  │         Agent Pod            │──┘ emits events / heartbeats      │
│  │  ┌───────────────────────┐   │                                   │
│  │  │ init: bundle-fetch    │   │                                   │
│  │  ├───────────────────────┤   │                                   │
│  │  │ agent runtime         │   │                                   │
│  │  │ (COW /workspace)      │   │                                   │
│  │  ├───────────────────────┤   │                                   │
│  │  │ sidecar: telemetry    │   │                                   │
│  │  │ logs / metrics /      │   │                                   │
│  │  │ events / syscalls     │   │                                   │
│  │  └───────────────────────┘   │                                   │
│  └──────────────────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────┘
              │
┌─────────────▼─────────────────────────────────────────────────────┐
│                        Persistence Layer                           │
│                                                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │
│  │ Artifact │ │   Log    │ │ Metrics  │ │  Traces  │ │ Search │  │
│  │   Store  │ │  Store   │ │  Store   │ │  Store   │ │ Index  │  │
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
│  ┌───────────────────────────────────────────────────────────┐     │
│  │  Tool Gateway  (audited proxy for external tool calls)    │     │
│  └───────────────────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────────────────┘
```

---

## 5. Component Definitions

### 5.1 Control Plane

#### API Service

The single entry point for all external callers. Authenticates requests, validates input format, and forwards to the Orchestrator. Stateless — scales horizontally behind a load balancer.

| Endpoint | Purpose |
|---|---|
| `POST /runs` | Submit a run |
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

- Invokes the Spec Resolver on submission to validate planning artifacts and package the immutable input bundle
- Writes run records and state transitions to the State Store (append-only)
- Publishes lifecycle events to the Event Bus
- Monitors agent heartbeats — triggers timeout when absent beyond the class threshold
- Makes retry decisions for transient infrastructure failures; surfaces logical failures as failed runs for human review
- Tracks checkpoint state for resumable multi-step runs

Multiple instances run concurrently using optimistic locking on the State Store.

#### Scheduler

Determines when and where work executes, independent of admission policy so that scheduling logic and guardrail logic evolve separately.

Responsibilities:

- Selects the priority lane (critical, standard, background, retry)
- Matches runs to execution classes based on declared task complexity, falling back to `medium`
- Evaluates placement constraints (affinity, anti-affinity in Phase 3)
- Places dispatch messages on the appropriate Work Queue lane

#### Policy Service

The admission and guardrail layer. Every run request passes through the Policy Service before being accepted. It is a distinct component so that rules can be updated, tested, and audited independently from orchestration logic.

Admission checks include:

- Task must have `status:ready` on its GitHub Issue
- All upstream task dependencies must be `status:done`
- Input bundle must resolve to valid, approved planning artifacts with no draft state
- Required ADRs referenced by the task must exist in `docs/adr/`
- Execution class must be within the submitting team's quota balance
- Agent image must be on the approved image allowlist
- Tool grants must match tools declared in the task configuration

#### State Store

PostgreSQL. Stores:

- Run records (ID, status, input bundle reference, timestamps, owner, team, execution class)
- Append-only state transition log — never mutated after write
- Checkpoint records keyed by run ID and step name
- Artifact manifests declared on completion
- Quota and credit balances per team
- Audit events for policy decisions, secret access, human overrides, and artifact publication

ACID guarantees are required throughout. The append-only log schema enforces immutability at the database level.

---

### 5.2 Message Layer

Work dispatch and lifecycle telemetry are deliberately separated into two systems with different semantics. The Work Queue needs consumer-group delivery and dead-letter handling for unprocessable work. The Event Bus needs fan-out to multiple independent consumers for the same event. A single unified messaging system cannot cleanly serve both.

#### Work Queue

Durable, ordered, with four priority lanes. Provides at-least-once delivery. Worker Controllers use idempotency keys to prevent double-execution.

| Lane | Purpose | Scale-Up Trigger |
|---|---|---|
| `critical` | Escalated or time-sensitive runs | Queue depth > 0 |
| `standard` | All normal feature work | Queue depth > 5 |
| `background` | Non-blocking analysis and review sweeps | Queue depth > 10 |
| `retry` | Transient failure re-dispatch with backoff | Queue depth > 0 |

Partitioned by lane. In multi-tenant deployments, further partitioned by team to prevent one team's burst from starving others.

#### Event Bus

Publishes domain events for all run lifecycle transitions, artifact declarations, heartbeats, and checkpoint completions. Consumers are decoupled from producers and receive events independently.

Primary consumers:

- GitHub Integration Service — Issue label sync and PR comments
- Observability pipeline — metrics on state transitions
- Audit logger — append immutable audit record to State Store
- Future: notification services, webhook triggers, billing pipeline

#### Dead Letter Queue

Receives messages that exhaust all retry attempts. An operator alert fires on any DLQ activity. Messages are never silently dropped.

---

### 5.3 Execution Plane

#### Worker Controller (Kubernetes Operator)

A custom Kubernetes operator that manages agent pod lifecycle in response to Work Queue dispatch messages.

Responsibilities:

- Dequeues dispatch messages from the Work Queue
- Creates `AgentRun` custom resources (enabling `kubectl get agentruns` and GitOps-compatible management)
- Launches agent pods with the correct image, resource limits, security context, credential volumes, and network policy
- Monitors pod phase and reports transitions to the Orchestrator
- Force-terminates pods that exceed the execution class timeout
- Cleans up completed pods and releases ephemeral storage volumes

#### Agent Pod

Each run executes in a dedicated isolated pod. The pod contains three containers:

```
Pod
├── init-container: bundle-fetcher
│     Downloads and validates the immutable input bundle from the artifact store
│     Unpacks to /workspace/input/ (read-only bind mount for the agent container)
│
├── container: agent
│     The agent runtime (Claude CLI, Codex CLI, Gemini CLI, or pluggable custom)
│     Non-root (UID 10000), read-only root filesystem, no privilege escalation
│     All Linux capabilities dropped; seccomp profile: RuntimeDefault
│     Writes exclusively to /workspace/ (ephemeral COW overlay)
│     Credentials injected via mounted secret volumes — not environment variables
│     Network egress restricted to execution-class allowlist
│
└── sidecar: telemetry-relay
      Tails /workspace/logs/execution.jsonl → ships to log store
      Scrapes agent metrics endpoint → forwards to metrics store
      Emits heartbeat events to Event Bus every 30 seconds
      Captures gVisor syscall audit stream when secure runtime is active
      Forwards lifecycle events (checkpoint reached, artifact declared) to Event Bus
```

The agent process has access to:

- `/workspace/input/` — read-only unpacked input bundle
- `/workspace/` — writable COW overlay; base image provides toolset (git, language runtimes, Graphite CLI); overlay captures only the agent's changes
- Projected secret volumes scoped to the run — GitHub token, model API key, artifact store credentials
- Network egress to allowlisted endpoints only

The agent process does not have access to:

- Host network, host filesystem, or host IPC namespace
- Other pods, namespaces, or their volumes
- Any credentials outside the declared task scope
- Unrestricted internet egress

#### Workspace Layout

```
/workspace/
├── input/              (read-only — unpacked input bundle)
│   ├── task.json       (task ID, acceptance criteria, dependencies)
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── config.json     (execution class, tool grants, credential refs)
├── repo/               (git clone of target repository at specified commit SHA)
├── logs/
│   └── execution.jsonl (structured JSONL, tailed by telemetry sidecar)
├── checkpoints/        (durable step state for resumable execution)
└── output/
    └── manifest.json   (agent declares all produced artifacts before exit)
```

On completion, the workspace manager reads `manifest.json`, validates all declared artifacts exist, pushes them to the artifact store, records artifact references in the State Store, and releases the ephemeral volume.

---

### 5.4 Persistence Layer

| Store | Purpose | Technology (Candidate) |
|---|---|---|
| Metadata | Run records, transitions, quotas, manifests, checkpoints | PostgreSQL |
| Artifacts | Input bundles, declared outputs, execution bundles | S3-compatible object storage |
| Logs | Structured log aggregation, queryable by run ID | Loki |
| Metrics | System and per-run metrics with long-term retention | Prometheus + Thanos |
| Traces | Distributed traces across control plane and pods | Tempo |
| Search Index | Fast cross-run query by run ID, task, team, or content | TBD (ADR-013) |

The Search Index is included at the persistence layer from the outset. Retrofitting search capability after the fact is expensive; the index schema should be defined during Phase 1 even if population is deferred to Phase 2.

All stores are write-once or append-only for execution data. Operational data (quotas, configuration) is mutable under controlled access.

---

### 5.5 External Integrations

#### Spec Resolver

Invoked on every run submission before any execution resource is consumed. If validation fails, the run is rejected with a structured error — no pod is created, no queue message is published, no quota is consumed.

Validates:

- `spec.md` exists at the specified commit SHA and is not in draft state
- `plan.md` exists and references the spec
- `tasks.md` contains the requested task with explicit acceptance criteria and required tests listed
- All ADRs referenced by the task exist in `docs/adr/`
- Task status on GitHub Issue is `status:ready`
- All upstream task dependencies are `status:done`

On success, packages the validated artifacts into a versioned input bundle, uploads it to the artifact store, and returns the bundle reference to the Orchestrator.

#### GitHub Integration Service

Listens to the Event Bus and maps run lifecycle events to GitHub actions. Agents do not call the GitHub API directly — all GitHub state changes flow through this service, ensuring that the tracking source of truth remains consistent and that agents cannot update Issue or PR state outside their declared outputs.

| Run Event | GitHub Action |
|---|---|
| `run.launched` | Issue label → `status:in-progress` |
| `run.completed` | PR confirmed open, Issue label → `status:in-review` |
| `run.failed` | Issue comment with structured failure summary |
| `run.cancelled` | Issue comment, label reverted to `status:ready` |
| `run.timed_out` | Issue comment, label set to `status:blocked` |

Uses a GitHub App with minimum required scopes, scoped per repository.

#### Tool Gateway

An audited proxy through which all agent external tool calls are routed. Rather than direct egress to tool APIs, agents call the Tool Gateway, which:

- Validates the tool is declared in the task's config grant list
- Logs the call (tool name, arguments, run ID, timestamp) to the audit record
- Rate-limits calls per run and per team
- Forwards to the upstream API and returns the response

The Tool Gateway is the single enforcement and audit point for all external tool use. It enables after-the-fact review of exactly what each agent called and with what arguments, regardless of which execution class the run used.

---

## 6. Agent Lifecycle — Full Flow

```
1.  Caller submits POST /runs with {task_id, repo, commit_sha, execution_class, config}

2.  API Service authenticates caller → forwards to Policy Service
    Policy Service evaluates all admission rules → admits or rejects with structured reason

3.  On admission, Orchestrator invokes Spec Resolver:
    - Fetches spec.md, plan.md, tasks.md at commit_sha
    - Validates task readiness and upstream dependency completion
    - Packages immutable input bundle → uploads to artifact store → returns bundle_ref

4.  Orchestrator writes run record to PostgreSQL (status: scheduled)
    Publishes run.scheduled to Event Bus

5.  Scheduler selects priority lane and confirms execution class
    Places dispatch message on Work Queue

6.  Worker Controller dequeues dispatch message:
    - Creates AgentRun CRD in Kubernetes
    - Launches pod:
        - Resource limits and timeout per execution class
        - Security context (non-root, read-only FS, all capabilities dropped, seccomp)
        - Container runtime per class (containerd or gVisor)
        - NetworkPolicy (deny-all + class egress allowlist)
        - Projected secret volumes (short-lived credentials, scoped to run)
    - Reports pod creation to Orchestrator (status: launching)

7.  init container downloads and validates input bundle → unpacks to /workspace/input/

8.  Agent container starts:
    - Reads task.json from /workspace/input/
    - Clones repository at commit_sha to /workspace/repo/
    - Executes task following implementation process protocol:
        → Create branch t-<##>-<slug>
        → Write failing test for first acceptance criterion   [write checkpoint]
        → Write minimum production code to pass
        → Refactor without changing behavior
        → Commit: <type>(<scope>): <description> (T-##)       [write checkpoint]
        → Repeat TDD cycle for each acceptance criterion
        → Push branch                                          [write checkpoint]
        → Open PR via Graphite                                 [write checkpoint]
    - Writes manifest.json to /workspace/output/
    - Telemetry sidecar emits heartbeat every 30s throughout

9.  Orchestrator monitors heartbeats and pod phase:
    - Heartbeat absent beyond class timeout → marks run timed_out, kills pod
    - Pod exits 0 → triggers completion flow
    - Pod exits non-zero → evaluates retry policy (transient infra failure: retry up to 2x
      with exponential backoff; logical failure: surface as failed, no retry)

10. On pod exit 0:
    - Workspace manager reads manifest.json, validates declared artifacts, pushes to artifact store
    - Orchestrator marks run done, records artifact refs in PostgreSQL
    - GitHub Integration Service updates Issue to status:in-review, confirms PR open
    - Event Bus receives run.completed

11. Ephemeral COW overlay purged. Secret volumes revoked. AgentRun CRD deleted. Pod terminated.
```

---

## 7. Isolation Model

### Container Security Context

Applied to all agent containers regardless of execution class:

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

| Execution Class | Runtime | Rationale |
|---|---|---|
| nano, small, medium, large, gpu | containerd | Standard isolation, lower cold-start latency |
| secure | gVisor (runsc) | Syscall-level kernel sandboxing; enables syscall audit stream |

The `secure` class applies to tasks touching authentication, session management, persistent data stores, secrets, or platform infrastructure — workloads where a compromised agent poses the highest risk. gVisor interposes a guest kernel between the agent and the host kernel, preventing container escape through kernel vulnerabilities. The telemetry sidecar captures the gVisor syscall audit stream and ships it to the log store alongside application logs, providing a complete record of every system call the agent issued.

Teams or the Policy Service may escalate any run to `secure`. The default for all other tasks is `containerd`.

### Network Policy

Each pod operates under deny-all ingress and deny-all egress as the baseline. Egress allowances are granted per execution class:

| Class | Allowed Egress |
|---|---|
| `restricted` | Model API only |
| `standard` | Model API, GitHub API, artifact store, Tool Gateway |
| `extended` | Above + package registries (npm, pip, crates.io) |

Egress is enforced at the Kubernetes NetworkPolicy level — no in-process configuration can override it. External tool calls route through the Tool Gateway regardless of execution class.

### Credential Isolation

Credentials are injected as projected Kubernetes secret volumes, not as environment variables. Secrets are scoped to the minimum repository, tool, and API access required by the task. Cloud deployments use IRSA (AWS) or Workload Identity (GCP) to issue short-lived cloud credentials without any long-lived keys in configuration. Credentials expire or are revoked at run completion.

### Namespace Topology

```
archive-control-plane    — API Service, Orchestrator, Scheduler, Policy Service
archive-workers-prod     — Production agent pods
archive-workers-staging  — Staging and development agent pods
archive-integrations     — GitHub Integration Service, Spec Resolver, Tool Gateway
```

Resource quotas are enforced at the namespace level. A burst of agent runs cannot resource-starve control plane components.

---

## 8. Execution Classes

| Class | CPU | Memory | Storage | Timeout | Runtime | Use Case |
|---|---|---|---|---|---|---|
| `nano` | 0.1 | 256 MB | 1 GB | 5 min | containerd | Metadata operations, status checks |
| `small` | 0.5 | 1 GB | 5 GB | 30 min | containerd | Simple bug fixes, isolated changes |
| `medium` | 2.0 | 4 GB | 20 GB | 2 hr | containerd | Standard implementation tasks (default) |
| `large` | 4.0 | 8 GB | 50 GB | 4 hr | containerd | Complex multi-file tasks, architecture work |
| `gpu` | 2.0 + GPU | 16 GB | 50 GB | 4 hr | containerd | Model inference, local embedding, data-heavy tasks |
| `secure` | 2.0 | 4 GB | 20 GB | 2 hr | gVisor | Auth, secrets, persistence, platform tasks |

The Scheduler selects the execution class from the complexity declared in `tasks.md`, falling back to `medium`. Operators may override via API.

---

## 9. Scalability Strategy

### Control Plane Scaling

All control plane services — API, Orchestrator, Scheduler, Policy Service — are stateless. They run as Kubernetes Deployments with Horizontal Pod Autoscalers driven by CPU and request rate. Any instance can be terminated and replaced without state loss.

### Worker Autoscaling

Worker capacity is driven by queue depth using KEDA (Kubernetes Event-Driven Autoscaling). Each priority lane scales independently:

| Lane | Min | Max | Scale-Up Trigger |
|---|---|---|---|
| critical | 1 | 20 | queue depth > 0 |
| standard | 2 | 100 | queue depth > 5 |
| background | 0 | 20 | queue depth > 10 |
| retry | 0 | 10 | queue depth > 0 |

Node pools are pre-warmed with placeholder pods to reduce cold-start latency. Cluster autoscaling provisions additional nodes when pending worker pods cannot be scheduled.

### Queue Partitioning

Queues are partitioned by priority lane. In multi-tenant deployments, further partitioned by team to ensure one team's burst cannot starve another's capacity.

### Database Scaling

PostgreSQL scales vertically for Phase 1. Phase 2 adds read replicas for query offload and PgBouncer for connection pooling. Phase 3 partitions the run records table by `run_id` hash to support horizontal sharding if write throughput demands it.

### Workflow Engine Consideration

The dependency-chain coordination defined in Section 10 handles most multi-task sequencing through orchestrator-enforced dispatch ordering. If the system evolves to support deeply stateful agent graph execution — where runs spawn child runs, fan out across many parallel sub-agents, and aggregate results across multiple levels — the correct response is to introduce a dedicated workflow engine (such as Temporal or Argo Workflows) above Kubernetes, not to encode workflow semantics inside individual pods. This decision is deferred to Phase 2 based on observed usage patterns and resolved via ADR-012.

---

## 10. Multi-Agent Coordination

### Fan-Out (Parallel)

When a feature's tasks are independent, all may be submitted simultaneously. The Scheduler dispatches them in parallel up to quota limits. Each executes in its own isolated pod. The Orchestrator tracks completion and marks the feature complete when all tasks reach `done`.

### Dependency Chains (Sequential)

When task B declares a dependency on task A in `tasks.md`, the Scheduler will not dispatch B until A reaches `done` and its branch is merged. The Spec Resolver re-validates the input bundle for B against the updated repository state, ensuring B's agent receives the correct base commit. This prevents conflicts from simultaneous modification of the same files without requiring agents to coordinate directly.

### Conflict Detection

Before dispatching any run, the Scheduler checks whether another in-progress run has checked out a branch touching overlapping file paths. Conflicting runs are held in the queue rather than dispatched in parallel, preventing merge conflicts by construction. The appropriate conflict detection scope (file-level, directory-level, or branch-level) is resolved via ADR-010.

---

## 11. Observability

Operators must be able to answer four questions quickly and without special tooling:

1. **What is running now?** — Live view of queued, launching, and active agent pods
2. **Why is a run blocked or slow?** — Trace from submission through scheduling, queue depth, and pod events
3. **What did a specific agent do?** — Full structured log for any run, queryable by run ID
4. **Which resource or policy limit caused the issue?** — Policy Service decisions and quota state surfaced in the audit log

### Structured Logs

All components emit structured JSONL. Agent containers write to `/workspace/logs/execution.jsonl`. The telemetry sidecar ships to the log store indexed by `run_id`, `task_id`, `team`, `status`, and `phase`.

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

When the `secure` execution class is active, the telemetry sidecar also captures the gVisor syscall audit stream, providing a complete record of every system call the agent issued during the run.

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

`agentic_run_cost_credits` enables cost attribution per team and class from the start. Cost accounting is a first-class observability concern.

### Distributed Traces

OpenTelemetry traces span from API submission through the Policy Service, Orchestrator, Scheduler, Work Queue dispatch, Worker Controller, pod launch, and artifact persistence. Trace context is propagated into the agent container via environment variable, enabling correlation between control plane spans and agent-internal steps in a single trace view.

### Dashboards

A canonical Grafana dashboard per environment exposes:

- Live queue depth by lane
- Run status breakdown (running / completed / failed / timed out, last 24 hours)
- P50 / P95 / P99 run duration by execution class
- Worker utilization and pending pod count
- DLQ depth (alert fires on any non-zero value)
- Quota utilization by team
- Cost credits consumed by team and execution class

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

---

## 12. Integration with Existing Processes

### Planning Process

The Spec Resolver enforces the planning gate at the execution boundary. A run cannot be admitted unless `spec.md`, `plan.md`, and `tasks.md` are present, approved, consistent, and free of draft state. Required ADRs must exist. Planning artifacts are read-only inputs — agents cannot modify or substitute them during execution.

### Tracking Process

The GitHub Integration Service maintains Issue state in sync with run state by consuming Event Bus events. Issue labels are applied and removed by the integration service — agents do not call the GitHub API for status updates. Agents update Issues only through declared outputs in `manifest.json`. This keeps the tracking source of truth accurate without agents having direct write access to Issue state.

### Implementation Process

Agent containers are pre-configured with the Graphite CLI, branch naming convention (`t-<##>-<slug>`), and commit message format (`<type>(<scope>): <description> (T-##)`) defined in the implementation process. The agent protocol — write failing test, write minimum production code, refactor, commit, repeat per acceptance criterion — is enforced by the agent runtime's internal loop. Checkpoints are written after each externally visible action so that a transient failure can resume without replaying completed steps.

### Review Process

A review agent is submitted as a distinct run type. Its input bundle includes the PR diff, linked spec/plan/tasks, and any referenced ADRs. It follows the four-tier review protocol, produces a structured `review.json` output with verdict (reject / revise / approve) and ordered findings keyed to file and line number, and writes it to `/workspace/output/`. The GitHub Integration Service posts the structured review as a GitHub PR review via the API.

---

## 13. Security Model

| Layer | Control |
|---|---|
| Container | Non-root, read-only FS, all capabilities dropped, seccomp RuntimeDefault |
| Runtime | containerd by default; gVisor for `secure` execution class |
| Syscall audit | gVisor audit stream captured by telemetry sidecar for `secure` class runs |
| Network | Deny-all default; execution-class egress allowlist enforced at NetworkPolicy |
| Tool access | Routed through Tool Gateway; logged, rate-limited, grant-validated |
| Credentials | Short-lived, scoped per run, mounted as projected secrets — not env vars |
| Cloud identity | IRSA (AWS) or Workload Identity (GCP) — no long-lived keys anywhere |
| Image supply chain | Signed images, digest pinning, SBOM generation |
| Admission | Policy Service enforces quota, artifact validity, and tool grants before any resource is allocated |
| Audit trail | Append-only event log in State Store for all transitions, policy decisions, and artifact publication |
| Secret lifecycle | Credentials expire or are revoked at run completion |

---

## 14. Technology Stack Candidates

Candidate recommendations, not decisions. Each requires ADR ratification before adoption.

| Concern | Candidate | Rationale |
|---|---|---|
| Container orchestration | Kubernetes (EKS or GKE) | Mature ecosystem, KEDA and operator support |
| Container runtime (default) | containerd | Default for EKS/GKE, stable, well-supported |
| Container runtime (secure class) | gVisor (runsc) | Syscall-level sandboxing, audit stream, no full VM overhead |
| Work queue and event bus | NATS JetStream | Lightweight, built-in persistence, simpler ops than Kafka, sufficient throughput at initial scale |
| Metadata store | PostgreSQL (Aurora Serverless v2) | ACID, optimistic locking, scales from development to production |
| Artifact store | S3-compatible object storage | Durable, cost-effective, universal API |
| Log aggregation | Grafana Loki | Integrates with Prometheus and Tempo; structured label query |
| Metrics | Prometheus + Thanos | KEDA integration; long-term retention via Thanos |
| Tracing | Grafana Tempo | Unified observability stack with Loki and Prometheus |
| Search index | TBD | Requires ADR-013 |
| Autoscaling | KEDA | Queue-depth-driven, native NATS integration |
| Secret management | AWS Secrets Manager + IRSA | Cloud-native, no separate infrastructure to operate |
| GitOps / deploy | Argo CD | Kubernetes-native, full audit trail, rollback capability |
| Ingress | Cloud-native load balancer | Managed TLS, WAF integration |
| Workflow engine (if needed) | Temporal or Argo Workflows | Phase 2 decision via ADR-012 |

NATS JetStream is preferred over Kafka for Phases 1 and 2 because it requires no ZooKeeper or separate broker management and its throughput is sufficient for agentic workloads at this scale. Kafka remains an option if Phase 3 retention or throughput demands exceed NATS capacity.

---

## 15. Phased Delivery

### Phase 1: MVP — Single Region, Core Execution

**Target**: 10–20 simultaneous agent runs. End-to-end lifecycle. Basic observability.

Deliverables:

- API Service (submit, poll, cancel, artifact retrieval)
- Orchestrator with full lifecycle state machine and checkpoint write support
- Policy Service with admission rules and quota enforcement
- Spec Resolver validating all planning artifacts before run admission
- Worker Controller (Kubernetes Operator) with `AgentRun` CRD
- Agent pods with init container, agent runtime, and telemetry sidecar
- COW overlay workspace with artifact manifest validation
- Artifact persistence to object storage on completion
- GitHub Integration Service (Issue label sync, PR confirmation)
- Tool Gateway (audited proxy for external tool calls)
- Single priority lane (standard) — additional lanes in Phase 2
- Transient failure retry (max 2 retries, exponential backoff)
- Timeout enforcement per execution class
- Structured log shipping to Loki
- Basic Grafana dashboard
- PostgreSQL State Store with append-only transition log
- Search index schema defined (population in Phase 2)

ADRs required before Phase 1 begins: ADR-001 through ADR-007 (see Section 16).

### Phase 2: Operational Maturity

**Target**: 100+ simultaneous runs. Full observability. Multi-team quotas. Secure class.

Deliverables:

- All four priority lanes with KEDA autoscaling per lane
- Full execution class taxonomy including `gpu` and `secure`
- gVisor runtime for `secure` class with syscall audit log capture
- Per-team quota and credit system with cost attribution metrics
- Full OpenTelemetry tracing with context propagation into pods
- Prometheus + Thanos for long-term metrics retention
- Named alert rules with severity thresholds
- Search index populated from run logs and artifacts
- Multi-agent coordination: dependency chain enforcement and conflict detection
- Review agent run type with structured verdict output
- Checkpoint-based resumption for retried runs
- Workflow engine evaluation and ADR-012 decision

ADRs required: ADR-008 through ADR-013.

### Phase 3: Multi-Region and Multi-Tenant

**Target**: Geographically distributed execution. Organizational-level tenancy.

Deliverables:

- Regional worker pools with control plane federation
- Cross-region artifact replication
- Tenant-level namespace isolation with dedicated worker pools
- Advanced scheduling (affinity, anti-affinity, geographic preference)
- Event-driven run triggers (GitHub App webhook on Issue label change, scheduled cron, PR merged)
- Audit export to SIEM
- SLA tracking per tenant and execution class
- Operator runbooks and on-call playbooks

ADRs required: ADR-014 through ADR-016.

---

## 16. ADR Backlog

All decisions below must be resolved as ADRs in `docs/adr/` before their associated phase begins. No component implementation may proceed without its governing ADR.

| # | Decision | Options | Phase |
|---|---|---|---|
| ADR-001 | Compute substrate and cloud provider | EKS, GKE, self-hosted | 1 |
| ADR-002 | Container runtime strategy | containerd + gVisor for secure class; gVisor for all runs | 1 |
| ADR-003 | Message queue and event bus | NATS JetStream, Kafka, AWS SQS + SNS | 1 |
| ADR-004 | Metadata store | PostgreSQL (Aurora Serverless v2), CockroachDB | 1 |
| ADR-005 | Artifact and log storage | S3, GCS, Cloudflare R2 | 1 |
| ADR-006 | Secret management | AWS Secrets Manager + IRSA, HashiCorp Vault | 1 |
| ADR-007 | Observability stack | Grafana (Loki + Prometheus + Tempo), Datadog, CloudWatch | 1 |
| ADR-008 | Multi-tenant quota model | Credit-based, hard limits, soft limits with burst | 2 |
| ADR-009 | Execution class taxonomy and resource values | As proposed in Section 8 | 2 |
| ADR-010 | Multi-agent conflict detection scope | File-level, directory-level, branch-level | 2 |
| ADR-011 | Multi-agent dependency enforcement | Orchestrator dispatch ordering, queue-level gates | 2 |
| ADR-012 | Workflow engine | Orchestrator sequencing sufficient; Temporal; Argo Workflows | 2 |
| ADR-013 | Search index technology | Elasticsearch, OpenSearch, PostgreSQL full-text | 2 |
| ADR-014 | Multi-region topology | Active-active, active-passive, regional-primary | 3 |
| ADR-015 | Tenant isolation model | Namespace quotas, dedicated node pools, separate clusters | 3 |
| ADR-016 | Event-driven trigger architecture | GitHub App webhooks, polling, dedicated trigger service | 3 |

---

## 17. Open Questions

These must be answered before or during Phase 1 planning:

1. **Agent runtime selection**: Which runtimes are supported at launch — Claude CLI only, or also Codex, Gemini, custom? Does the execution plane enforce a single runtime or support a pluggable interface?

2. **Repository access model**: Does each pod clone the repository directly via Git, or does the input bundle include a pre-cloned snapshot? Git clone is simpler; a pre-cloned snapshot is more reproducible and reduces pod startup time.

3. **Run triggering in Phase 1**: Manual API submission only, or also a GitHub App webhook when an Issue moves to `status:ready`?

4. **Human approval gate**: Should any run type require explicit human approval before the Scheduler dispatches it? If yes, where is the gate enforced and what is the approval mechanism?

5. **Retention policy**: How long are run records, logs, and artifacts retained? Does the policy differ by execution class or team? What triggers deletion?

6. **Model API cost isolation**: How are model API inference costs attributed per run? Is there a per-run budget cap, and does the Policy Service enforce it at admission time?

7. **Local development mode**: How do engineers run the system locally without a full Kubernetes cluster? Is there a Docker Compose or equivalent local mode?

8. **Agent runtime trust boundary**: Is the primary concern that an agent is exploited by malicious external input, or that the agent itself behaves adversarially? The answer shapes whether gVisor-by-default is warranted beyond the `secure` class.

---

*All significant decisions identified in Section 16 must be elevated to Architecture Decision Records in `docs/adr/` before implementation planning begins for any phase. This document is pre-ADR input, not a decision record.*
