# Agentic Execution Architecture Proposal

**Status**: Draft
**Author**: Claude (claude-sonnet-4-6)
**Date**: 2026-03-13
**Supersedes**: `docs/codex/architecture-proposal.md`, `docs/gemini/architecture-proposal.md`

---

## 1. Purpose

This document proposes an architecture for executing AI agents at scale. Agents must operate in isolated containers, many may run simultaneously, and the system must integrate cleanly with the planning, tracking, implementation, and review processes already defined in this repository.

This proposal synthesizes the earlier Codex and Gemini proposals, incorporates industry best practices, and goes further in addressing observability, multi-agent coordination, integration seams, and a phased delivery path.

Significant decisions surfaced here must each be resolved as Architecture Decision Records in `docs/adr/` before implementation begins.

---

## 2. Problem Statement

The process framework defined in this repository requires agents to:

- Execute approved tasks from `tasks.md` without human assistance
- Create branches, write code, commit, open PRs, update GitHub Issues
- Operate within the review and implementation process constraints
- Produce auditable, traceable outputs
- Be safe to run many at once without interference

The current gap is a missing execution substrate: no system exists to launch agents, isolate them from each other, manage their lifecycle, persist their outputs, or give operators visibility into what is happening.

---

## 3. Design Goals

| Goal | Description |
|---|---|
| **Isolation** | Each agent run executes in its own container with scoped credentials and network access |
| **Concurrency** | The system supports many simultaneous agent runs without resource contention or state interference |
| **Observability** | Every run is fully visible: logs, metrics, traces, events, and artifacts are captured and queryable |
| **Resilience** | Runs can be retried, cancelled, and timed out. Failures are contained and do not cascade |
| **Traceability** | Every agent action is traceable to an approved task, spec, and plan |
| **Security** | Least privilege everywhere. No agent has more access than its task requires |
| **Operability** | Operators can inspect, pause, drain, and scale the system without special tooling |
| **Evolvability** | The architecture can grow from single-region MVP to multi-region multi-tenant without rewriting core contracts |

---

## 4. Foundational Principles

### 4.1 Control Plane / Data Plane Separation

Orchestration logic (what should run, when, with what config) is strictly separated from execution logic (how an agent runs inside a container). This enables independent scaling and evolution of each layer.

### 4.2 Stateless Orchestration Backed by Durable State

Orchestrators and schedulers carry no in-memory state that cannot be reconstructed from the database. Any orchestrator instance can be restarted or replaced without losing run state.

### 4.3 Ephemeral Execution Environments

Agent containers are created fresh per run and destroyed after completion. No state persists in the execution environment. All meaningful output is declared and pushed to durable storage before the container exits.

### 4.4 Immutable Input Bundles

Before a run starts, the orchestrator resolves all planning artifacts (`spec.md`, `plan.md`, `tasks.md`, task context, config) into an immutable, versioned input bundle stored in object storage. The agent receives a reference to this bundle. The bundle does not change during the run.

### 4.5 Append-Only Execution Records

Run state transitions, events, log lines, and artifact references are written as append-only records. Nothing is mutated or deleted during or after a run. This makes the audit trail durable and reconstructible.

### 4.6 Explicit Artifact Declaration

Agents do not have write access to arbitrary locations. They declare their outputs (code, PR links, issue updates, reports) using a structured manifest. The workspace manager validates and persists declared artifacts. Undeclared side effects are not permitted.

### 4.7 Designed for Failure Domains

Every component assumes others can fail. Timeouts, dead-letter queues, circuit breakers, and retry policies are defined at each boundary. A failed agent run surfaces a recoverable error, not a system-wide incident.

---

## 5. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Control Plane                           │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  API Service │  │ Orchestrator │  │  Scheduler / Policy  │  │
│  │  (REST/gRPC) │  │ (State Mach.)│  │  (Admission, Quotas) │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                      │              │
│  ┌──────▼─────────────────▼──────────────────────▼───────────┐  │
│  │                    State Store (PostgreSQL)                │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────────────┬────────────────────────────────┘
                                 │ Work Queue
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Message Layer                           │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌───────────────┐   │
│  │   Work Queue    │  │   Event Bus     │  │  Dead Letter  │   │
│  │ (priority lanes)│  │ (run lifecycle) │  │    Queue      │   │
│  └────────┬────────┘  └────────┬────────┘  └───────────────┘   │
└───────────┼────────────────────┼───────────────────────────────┘
            │                    │
┌───────────┼────────────────────┼───────────────────────────────┐
│           │  Execution Plane   │                               │
│  ┌────────▼──────────┐         │                               │
│  │  Worker Controller│         │                               │
│  │  (K8s Operator)   │         │                               │
│  └────────┬──────────┘         │                               │
│           │ launches           │                               │
│  ┌────────▼──────────────────┐ │                               │
│  │       Agent Pod           │─┘ emits events                  │
│  │  ┌────────────────────┐   │                                 │
│  │  │   Agent Runtime    │   │                                 │
│  │  │   (claude/codex/   │   │                                 │
│  │  │    gemini/etc.)    │   │                                 │
│  │  └────────────────────┘   │                                 │
│  │  ┌───────────┐ ┌────────┐ │                                 │
│  │  │ Workspace │ │ Sidecar│ │                                 │
│  │  │ (overlay) │ │(telems)│ │                                 │
│  │  └───────────┘ └────────┘ │                                 │
│  └───────────────────────────┘                                 │
└────────────────────────────────────────────────────────────────┘
            │
┌───────────▼────────────────────────────────────────────────────┐
│                       Persistence Layer                        │
│                                                                │
│  ┌─────────────┐ ┌────────────┐ ┌────────────┐ ┌───────────┐  │
│  │  Artifact   │ │    Log     │ │  Metrics   │ │  Traces   │  │
│  │  Store (S3) │ │ Aggregator │ │   Store    │ │   Store   │  │
│  └─────────────┘ └────────────┘ └────────────┘ └───────────┘  │
└────────────────────────────────────────────────────────────────┘
            │
┌───────────▼────────────────────────────────────────────────────┐
│                    External Integrations                       │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐    │
│  │   GitHub     │  │   Graphite   │  │  Spec Resolver    │    │
│  │ (Issues/PRs) │  │  (PR stacks) │  │ (spec/plan/tasks) │    │
│  └──────────────┘  └──────────────┘  └───────────────────┘    │
└────────────────────────────────────────────────────────────────┘
```

---

## 6. Component Definitions

### 6.1 Control Plane

#### API Service

The single entry point for external callers. Accepts run submission requests, status queries, cancellation requests, and artifact retrieval. Validates input against the policy service before accepting a run.

Exposes:
- `POST /runs` — submit a run request with task ID and config
- `GET /runs/{id}` — poll run status and metadata
- `DELETE /runs/{id}` — cancel an in-progress run
- `GET /runs/{id}/artifacts` — retrieve declared outputs
- `GET /runs/{id}/logs` — stream or retrieve log output

Stateless. Scales horizontally behind a load balancer.

#### Orchestrator

The core state machine. Owns run lifecycle transitions:

```
submitted → validated → scheduled → launching → running → completing → done
                                                          → failed
                                                          → cancelled
                                                          → timed_out
```

Responsibilities:
- Resolves planning artifacts into an immutable input bundle on submission
- Writes run records to the state store
- Publishes state transition events to the event bus
- Listens for heartbeats and completion signals from running agents
- Triggers timeout logic when heartbeats cease
- Handles retry decisions for transient failures

Stateless. Multiple instances run concurrently using optimistic locking on the state store.

#### Scheduler / Policy Service

Determines when and where work executes.

Responsibilities:
- Enforces resource quotas per team, environment, and execution class
- Selects priority lane for a run (critical, standard, background)
- Admits or rejects runs based on policy (quota exhaustion, blocked tasks, invalid artifacts)
- Places run dispatch messages on the appropriate work queue lane

Admission policy examples:
- Task must have `status:ready` on its GitHub Issue
- Upstream task dependencies must be `status:done`
- Input bundle must resolve to valid, versioned planning artifacts
- Execution class must be within team quota

#### State Store

PostgreSQL. Stores:
- Run records (ID, status, input bundle ref, timestamps, owner, team)
- State transition log (append-only event sourced table)
- Artifact manifests
- Quota and credit balances

Selected for ACID guarantees, mature operational tooling, and support for optimistic locking across concurrent orchestrator instances.

---

### 6.2 Message Layer

#### Work Queue

A durable, ordered queue with multiple priority lanes:

| Lane | Use Case | Example |
|---|---|---|
| `critical` | Time-sensitive or escalated runs | Incident response tasks |
| `standard` | Normal feature implementation tasks | Default lane |
| `background` | Long-running analysis, review sweeps | Architecture reviews |
| `retry` | Transient failure retries | Backoff before re-dispatch |

Guarantees at-least-once delivery. Worker controllers use idempotency keys to prevent double-execution.

#### Event Bus

Publishes domain events for all run lifecycle transitions, artifact declarations, and heartbeats. Consumers include:

- GitHub integration service (update Issue status, post PR comments)
- Observability pipeline (write metrics on state transitions)
- Audit logger (append immutable audit record)
- Future: notification services, webhook triggers

#### Dead Letter Queue

Receives messages that fail all retry attempts. Operator alert fires on DLQ activity. Messages are never silently dropped.

---

### 6.3 Execution Plane

#### Worker Controller (Kubernetes Operator)

A custom Kubernetes operator that watches the work queue and manages pod lifecycle.

Responsibilities:
- Consumes dispatch messages from the work queue
- Creates Kubernetes pods with the correct image, resource limits, env, volumes, and network policy
- Monitors pod phase and reports transitions back to the orchestrator
- Enforces max-run-duration by force-terminating pods that exceed their time limit
- Cleans up completed pods and their ephemeral storage

The operator uses a `AgentRun` custom resource to represent each execution. This enables GitOps-compatible management and `kubectl get agentruns` visibility.

#### Agent Pod

Each run executes in a dedicated pod. Pod structure:

```
Pod
├── init-container: bundle-fetcher
│     Downloads and validates the immutable input bundle from artifact store
├── container: agent
│     The agent runtime (Claude CLI, Codex CLI, Gemini CLI, or custom)
│     Runs non-root, read-only root FS, no privilege escalation
│     Writes to /workspace only (ephemeral overlay mount)
│     Has access to declared credentials only (injected via secret volume)
└── sidecar: telemetry-relay
      Tails /workspace/logs/, scrapes metrics endpoint
      Ships to log aggregator and metrics store
      Forwards events to event bus
```

The agent process has access to:
- The unpacked input bundle (read-only)
- A writable `/workspace` directory (ephemeral, discarded after run)
- Specific credentials scoped to the run (GitHub token, API keys) via mounted secrets
- Network egress only to allowlisted endpoints (GitHub API, artifact store, model API)

The agent process does not have access to:
- The host network or host filesystem
- Other pods or namespaces
- Credentials outside its declared scope
- Unrestricted internet egress

#### Workspace and Artifact Model

```
/workspace/
├── input/          (read-only, unpacked from input bundle)
│   ├── task.json
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── config.json
├── repo/           (git clone of target repository)
├── logs/           (structured JSONL, tailed by sidecar)
└── output/         (agent writes declared artifacts here)
    └── manifest.json   (declares what was produced)
```

On completion, the workspace manager reads `manifest.json`, validates declared artifacts exist, pushes them to the artifact store, and registers them with the orchestrator. The ephemeral volume is then released.

---

### 6.4 Persistence Layer

| Store | Technology | Purpose |
|---|---|---|
| Metadata | PostgreSQL | Run records, state transitions, quotas, manifests |
| Artifacts | S3-compatible | Input bundles, output artifacts, execution logs |
| Logs | Loki or CloudWatch Logs | Structured log aggregation, queryable by run ID |
| Metrics | Prometheus + Thanos | System and per-run metrics, long-term retention |
| Traces | Tempo or Jaeger | Distributed traces across control plane and execution |

All stores are write-once or append-only for execution data. Operational data (quotas, config) is mutable.

---

### 6.5 External Integrations

#### GitHub Integration Service

Listens to the event bus for run state transitions and maps them to GitHub actions:

| Run Event | GitHub Action |
|---|---|
| `run.launched` | Issue label set to `status:in-progress` |
| `run.completed` | PR opened or updated, Issue label set to `status:in-review` |
| `run.failed` | Issue comment posted with failure summary |
| `run.cancelled` | Issue comment posted, label reverted |

Uses a GitHub App with minimal required permissions scoped per repository.

#### Spec Resolver

On run submission, the Spec Resolver reads the planning artifacts from the repository at the commit referenced in the run request. It validates:

- `spec.md` exists and is not in draft state
- `plan.md` exists and references the spec
- `tasks.md` contains the requested task with explicit acceptance criteria
- Any required ADRs referenced by the task exist in `docs/adr/`

If validation fails, the run is rejected before it consumes any execution resources.

---

## 7. Agent Lifecycle — Full Flow

```
1. Caller (human or trigger) submits POST /runs with {task_id, repo, commit_sha, config}

2. API Service authenticates caller, forwards to Orchestrator

3. Orchestrator invokes Spec Resolver:
   - Fetches spec.md, plan.md, tasks.md at commit_sha
   - Validates task is ready and dependencies are done
   - Packages immutable input bundle → uploads to S3 → returns bundle_ref

4. Orchestrator writes run record to PostgreSQL (status: scheduled)
   Publishes run.scheduled event to Event Bus

5. Scheduler evaluates quota and priority:
   - Checks team quota — admits or rejects
   - Selects priority lane
   - Publishes dispatch message to Work Queue

6. Worker Controller dequeues dispatch message:
   - Creates AgentRun CRD in Kubernetes
   - Creates Pod with:
       - init container pulling input bundle from S3
       - agent container with scoped credentials and resource limits
       - telemetry sidecar
   - Reports pod creation to Orchestrator (status: launching)

7. Agent container starts:
   - Reads input bundle from /workspace/input/
   - Clones repository at specified commit
   - Executes task per implementation process:
       - Creates branch t-<##>-<slug>
       - Writes failing tests
       - Implements minimum passing code
       - Commits with proper message format
       - Pushes branch
       - Opens PR via Graphite
   - Writes output manifest to /workspace/output/manifest.json
   - Emits heartbeats every 30s via telemetry sidecar

8. Orchestrator monitors heartbeats:
   - If heartbeat silent > configured timeout → marks run timed_out, kills pod
   - If pod exits 0 → triggers completion flow
   - If pod exits non-zero → triggers failure/retry flow

9. On completion:
   - Workspace manager reads manifest, validates, pushes artifacts to S3
   - Orchestrator marks run done, records artifact refs
   - GitHub Integration Service updates Issue to in-review, confirms PR open
   - Event Bus receives run.completed event

10. Ephemeral workspace volume released. Pod deleted.
```

---

## 8. Isolation Model

### Container Isolation

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

For high-security runs (those touching auth, persistence, or platform infrastructure), the execution class may specify `gVisor` (runsc) as the container runtime, providing syscall-level sandboxing beyond standard container isolation.

### Network Isolation

Each agent pod operates under a deny-all-ingress, deny-all-egress default network policy. Explicit egress allowances are granted per execution class:

| Endpoint Class | Allowed Egress |
|---|---|
| Standard | GitHub API, model API (Anthropic/OpenAI/Google), artifact store |
| Extended | Above + package registries (npm, pip, crates.io) |
| Restricted | Model API only (no GitHub, no external registries) |

Egress is enforced at the network policy level. There is no in-process configuration that can override it.

### Credential Isolation

Credentials are never embedded in container images or environment variables visible in pod specs. They are injected as short-lived Kubernetes secrets, scoped per run, projected into the container as mounted volumes. Secrets are rotated or revoked at run completion.

Cloud-hosted deployments use IRSA (AWS) or Workload Identity (GCP) to issue short-lived cloud credentials to pods without storing long-lived keys.

### Namespace Isolation

Agent pods run in dedicated Kubernetes namespaces isolated from control plane components:

```
archive-control-plane    — API, Orchestrator, Scheduler
archive-workers-prod     — Production agent pods
archive-workers-staging  — Staging agent pods
archive-integrations     — GitHub integration service, Spec Resolver
```

Resource quotas are enforced at the namespace level.

---

## 9. Execution Classes

Execution classes define resource limits and timeout policies:

| Class | CPU | Memory | Ephemeral Storage | Timeout | Container Runtime | Use Case |
|---|---|---|---|---|---|---|
| `nano` | 0.1 | 256 MB | 1 GB | 5 min | containerd | Status checks, metadata operations |
| `small` | 0.5 | 1 GB | 5 GB | 30 min | containerd | Simple feature tasks, bug fixes |
| `medium` | 2.0 | 4 GB | 20 GB | 2 hr | containerd | Standard implementation tasks |
| `large` | 4.0 | 8 GB | 50 GB | 4 hr | containerd | Complex multi-file tasks |
| `secure` | 2.0 | 4 GB | 20 GB | 2 hr | gVisor | Auth, persistence, platform tasks |

The Scheduler selects the execution class based on the task's declared complexity in `tasks.md` or applies the `medium` default.

---

## 10. Scalability Strategy

### Horizontal Scaling

All control plane components (API Service, Orchestrator, Scheduler) are stateless and scale horizontally behind a load balancer. Kubernetes Deployments with HPA manage replica count based on CPU and request rate.

### Worker Autoscaling

Worker capacity scales based on work queue depth using KEDA (Kubernetes Event-Driven Autoscaling). Each priority lane has independent scaling parameters:

```
critical lane:  min=1, max=20, scale-up on queue depth > 0
standard lane:  min=2, max=100, scale-up on queue depth > 5
background lane: min=0, max=20, scale-up on queue depth > 10
```

Node pools are pre-warmed to reduce pod-to-running latency. Cluster autoscaling adds nodes when worker replicas are pending due to insufficient node capacity.

### Queue Partitioning

Work queues are partitioned by priority lane. For multi-tenant scenarios, queues are further partitioned by team to prevent one team's burst from starving another's work.

### Database Scaling

PostgreSQL scales vertically for the MVP. For Phase 3, the metadata schema is designed to support read replicas for query offload and connection pooling via PgBouncer. Write path uses partitioned tables on `run_id` to support horizontal sharding if required.

---

## 11. Observability

Every run is fully instrumented from submission to completion.

### Structured Logs

All components emit structured JSONL logs. Agent containers write structured logs to `/workspace/logs/execution.jsonl`. The telemetry sidecar ships these to the log aggregation system indexed by `run_id`, `task_id`, `team`, `status`.

Required log fields per line:
```json
{
  "ts": "2026-03-13T10:00:00Z",
  "level": "info",
  "run_id": "run_abc123",
  "task_id": "T-07",
  "phase": "implement",
  "event": "test_cycle_complete",
  "cycle": 3,
  "test_status": "green"
}
```

### Metrics

Key metrics collected per run and aggregated by team/class/status:

- `agentic_runs_total` — counter by status (completed, failed, cancelled, timed_out)
- `agentic_run_duration_seconds` — histogram by execution class
- `agentic_queue_depth` — gauge by priority lane
- `agentic_worker_utilization` — gauge by node pool
- `agentic_artifact_size_bytes` — histogram by artifact type

### Distributed Traces

OpenTelemetry traces span from API submission through orchestration, scheduling, pod launch, and artifact persistence. Trace context is propagated into the agent container via environment variable, enabling correlation between control plane spans and agent-internal steps.

### Dashboards

A canonical Grafana dashboard per environment exposes:
- Live queue depth by lane
- Run status breakdown (running / completed / failed in last 24h)
- P50/P95/P99 run duration by execution class
- Worker utilization and pending pod count
- DLQ depth (alert threshold: > 0)

### Alerts

| Alert | Condition | Severity |
|---|---|---|
| DLQ non-empty | DLQ depth > 0 for 5 min | Warning |
| High failure rate | > 10% of runs failed in 15 min | Critical |
| Queue saturation | Standard queue depth > 50 for 10 min | Warning |
| Orchestrator degraded | Orchestrator healthy replicas < 1 | Critical |
| Timeout spike | > 5 timeouts in 10 min | Warning |

---

## 12. Multi-Agent Coordination

Many tasks are independent and can run fully in parallel. Some tasks have declared dependencies in `tasks.md`. The orchestrator supports two coordination patterns:

### 12.1 Fan-Out (Parallel)

When a feature's tasks are independent, all can be submitted simultaneously. The scheduler dispatches them in parallel up to quota. Each runs in its own isolated pod. The orchestrator tracks completion of all runs and marks the feature done when all tasks reach `done`.

### 12.2 Dependency Chains (Sequential)

When task B depends on task A, the scheduler will not dispatch B until A reaches `done` and its artifacts are committed. The Spec Resolver re-validates the input bundle for B against the updated state of the repository post-A.

This prevents conflicts from simultaneous modification of the same files and ensures dependent tasks receive the correct base state.

### 12.3 Conflict Detection

Before dispatching any run, the scheduler checks whether another in-progress run has checked out a conflicting branch or file path. Overlapping runs are queued, not parallelized, to prevent merge conflicts by construction.

---

## 13. Security Model Summary

| Layer | Control |
|---|---|
| Container | Non-root, read-only FS, no capabilities, seccomp |
| Runtime | gVisor for high-security execution classes |
| Network | Deny-all default, explicit allowlist egress |
| Credentials | Short-lived, scoped per run, mounted not envvar |
| Cloud identity | IRSA / Workload Identity (no long-lived keys) |
| Image supply chain | Signed images, digest pinning, SBOM generation |
| Admission | Policy engine enforces quota and artifact validity before launch |
| Audit | Append-only event log for all run transitions and agent actions |
| Secret rotation | Credentials revoked at run completion |

---

## 14. Integration with Existing Processes

### Planning Process

The Spec Resolver enforces that planning artifacts are complete and approved before a run is admitted. The orchestrator packages `spec.md`, `plan.md`, and the specific task from `tasks.md` into the immutable input bundle. The agent cannot modify or substitute these at runtime.

### Tracking Process

The GitHub Integration Service maintains Issue state in sync with run state. Issue labels (`status:in-progress`, `status:in-review`) are applied and removed by the integration service in response to event bus events, not directly by agents. Agents update issues only through declared outputs in the manifest.

### Implementation Process

Agent containers are pre-configured with the Graphite CLI and follow the commit format and branch naming conventions defined in the implementation process. The agent runtime enforces TDD cycle discipline through its internal protocol. Deviation from the protocol results in a non-zero exit and a failed run.

### Review Process

A review agent can be submitted as a separate run against an open PR. Its input bundle includes the PR diff, the linked spec/plan/tasks, and any referenced ADRs. It produces a structured review output (`review.json`) with verdict (reject/revise/approve) and ordered findings. The GitHub Integration Service posts this as a PR review via the GitHub API.

---

## 15. Technology Stack Recommendation

| Concern | Recommended Technology | Rationale |
|---|---|---|
| Container orchestration | Kubernetes (EKS or GKE) | Mature, broad ecosystem, KEDA and operator support |
| Container runtime (standard) | containerd | Default for EKS/GKE, stable, well-supported |
| Container runtime (secure) | gVisor (runsc) | Syscall-level sandboxing without full VM overhead |
| Work queue / event bus | NATS JetStream | Lightweight, high-throughput, built-in persistence, simple ops |
| Metadata store | PostgreSQL (Aurora Serverless v2) | ACID, proven, scales from dev to production |
| Artifact store | S3 (or GCS) | Durable, cheap, S3-compatible API is universal |
| Log aggregation | Grafana Loki | Pairs with Prometheus/Tempo, cost-effective, structured query |
| Metrics | Prometheus + Thanos | Standard, KEDA integrates natively, long-term via Thanos |
| Tracing | Grafana Tempo | Integrates with Loki/Prometheus in unified Grafana stack |
| Secret management | AWS Secrets Manager + IRSA | Cloud-native, no additional infrastructure to run |
| GitOps / deploy | Argo CD | Kubernetes-native, audit trail, rollback |
| Autoscaling | KEDA | Queue-depth-driven scaling, integrates with NATS and SQS |
| Ingress | AWS ALB Ingress Controller | Managed, TLS termination, WAF integration |

The unified Grafana observability stack (Loki + Prometheus + Tempo) is recommended because it reduces the number of distinct systems to operate while providing full logs/metrics/traces integration in a single UI.

NATS JetStream is recommended over Kafka for the MVP because it is operationally simpler, requires no ZooKeeper or separate broker management, and its throughput is more than sufficient for agentic workloads at initial scale. Kafka can be revisited at Phase 3 if throughput or retention requirements exceed NATS capacity.

---

## 16. Phased Delivery

### Phase 1: MVP — Single Region, Core Execution

**Target**: Support 10–20 simultaneous agent runs. Basic lifecycle management. Observability via logs.

Deliverables:
- API Service with `POST /runs`, `GET /runs/{id}`, `DELETE /runs/{id}`
- Orchestrator with full lifecycle state machine
- Worker Controller (Kubernetes Operator) managing pod lifecycle
- Input bundle packaging via Spec Resolver (validates spec/plan/tasks)
- Ephemeral pod per run with scoped credentials
- Artifact persistence to S3 on completion
- GitHub Integration Service (Issue label sync, PR creation notification)
- Basic Grafana dashboard (queue depth, run status, duration)
- Single priority lane (standard)
- Retry on transient failure (max 2 retries with backoff)
- Timeout enforcement per execution class

ADRs required before Phase 1 begins:
- Compute substrate (Kubernetes and cloud provider choice)
- Queue technology (NATS JetStream)
- Metadata store (PostgreSQL)
- Artifact store (S3)
- Secret management approach

### Phase 2: Operational Maturity

**Target**: Support 100+ simultaneous runs. Full observability. Multi-team quota enforcement.

Deliverables:
- Priority lanes (critical, standard, background, retry)
- Execution classes (nano, small, medium, large, secure)
- KEDA-based worker autoscaling driven by queue depth
- Per-team quota and credit system
- Full OpenTelemetry integration (structured traces across control plane and pods)
- Loki log aggregation, queryable by run ID
- Prometheus metrics with Thanos for long-term retention
- Grafana alerting on DLQ depth, failure rate, queue saturation
- Multi-agent coordination: dependency chain enforcement
- gVisor runtime for `secure` execution class
- Conflict detection to prevent parallel branch collisions
- Enriched review agent run type

ADRs required:
- Multi-tenant quota model
- Execution class taxonomy and selection policy
- Multi-agent coordination pattern (dependency chain enforcement)
- Conflict detection scope and granularity

### Phase 3: Multi-Region and Multi-Tenant

**Target**: Geographically distributed execution. Organizational-level tenancy with strong isolation boundaries.

Deliverables:
- Regional worker pools with control plane federation
- Cross-region artifact replication
- Tenant-level namespace isolation with dedicated worker pools
- Advanced scheduling: affinity, anti-affinity, geographic preference
- Event-driven run triggers (GitHub webhook, scheduled cron, PR merged)
- Audit export to SIEM
- SLA tracking per tenant and execution class
- Operator runbooks and on-call playbooks

ADRs required:
- Multi-region topology and failover policy
- Tenant isolation model (namespace vs cluster)
- Event trigger architecture

---

## 17. Decisions Required (ADRs)

The following decisions must be resolved as ADRs in `docs/adr/` before Phase 1 implementation begins:

| # | Decision | Options |
|---|---|---|
| ADR-001 | Container orchestration platform and cloud provider | EKS (AWS), GKE (GCP), self-hosted |
| ADR-002 | Message queue and event bus technology | NATS JetStream, Kafka, AWS SQS + SNS |
| ADR-003 | Metadata store technology | PostgreSQL (Aurora), CockroachDB |
| ADR-004 | Artifact and log storage | S3, GCS, Cloudflare R2 |
| ADR-005 | Secret management and credential injection | AWS Secrets Manager + IRSA, HashiCorp Vault |
| ADR-006 | Observability stack | Grafana (Loki + Prometheus + Tempo), Datadog, CloudWatch |
| ADR-007 | Container runtime for secure execution class | gVisor, Kata Containers, standard containerd |
| ADR-008 | Execution class taxonomy and default selection policy | Defined in this proposal — needs ratification |
| ADR-009 | Multi-agent dependency enforcement mechanism | Orchestrator-enforced vs queue-level |
| ADR-010 | GitOps and deployment tooling | Argo CD, Flux, Helm + CI |

---

## 18. Open Questions

The following questions are not resolved in this proposal. They should be answered before or during Phase 1 planning:

1. **Agent runtime selection**: Which agent runtimes will be supported at launch — Claude CLI only, or also Codex, Gemini, custom? Does the execution plane support pluggable runtimes or is it runtime-specific?

2. **Repository access model**: Does each agent pod clone the repository directly via Git, or is a pre-cloned repository snapshot included in the input bundle? The former is simpler; the latter is more reproducible.

3. **Run triggering**: In Phase 1, are runs triggered manually via API only, or is there also a GitHub webhook trigger when an Issue is moved to `status:ready`?

4. **Human approval gate**: Should any run type require explicit human approval before the orchestrator dispatches it? If so, what is the approval mechanism?

5. **Cost accounting**: Is per-run cost tracking required at launch, or is it deferred to Phase 2 quota enforcement?

6. **Model API cost isolation**: How are model API costs attributed per run? Is there a per-run budget cap?

7. **Retention policy**: How long are run records, logs, and artifacts retained? What is the deletion policy for completed runs?

8. **Local development**: How do engineers run the system locally for development and testing? Is there a local mode that replaces Kubernetes with a simpler runtime?

---

## 19. Relationship to Prior Proposals

This proposal supersedes and synthesizes the earlier architecture proposals:

- `docs/codex/architecture-proposal.md` — introduced the five-component model, scalability strategy, and phased rollout. Core structure is preserved here.
- `docs/gemini/architecture-proposal.md` — introduced gVisor, NATS/Redis Streams, and overlay filesystem workspace model. These recommendations are incorporated.

Key additions and refinements in this proposal:

- Explicit integration with all four defined processes (planning, tracking, implementation, review)
- Artifact declaration model and manifest-based output validation
- Conflict detection for parallel agent runs
- Multi-agent coordination patterns (fan-out and dependency chains)
- Full execution lifecycle flowchart (Section 7)
- Technology stack with explicit rationale per choice
- Numbered ADR backlog with options per decision
- Open questions section to surface remaining ambiguity

---

*This document should be reviewed by the team and the significant decisions elevated to ADRs in `docs/adr/` before implementation planning begins.*
