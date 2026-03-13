# Unified Archive Agentic Execution Architecture Proposal

## 1. Executive Summary

This proposal presents a unified architecture for the Archive Agentic Execution
engine, synthesizing the strongest elements from the Claude, Codex, and Gemini
architectural designs. The system provides a secure, scalable, and isolated
environment for high-concurrency autonomous agent operations using a
container-native control/data plane separation.

## 2. Core Design Principles

- **Strong Isolation (Gemini/Claude)**: Every agent run is sandboxed using
  syscall-level isolation (gVisor) to prevent host system compromise.
- **Asynchronous Orchestration (All)**: Decoupled task ingestion and
  execution via an event-driven control plane.
- **Durable Failure Domains (Codex)**: The system is designed so that failures
  in one agent run or component cannot cascade to unrelated executions.
- **Total Reproducibility (Claude)**: Uses immutable input bundles (S3) to
  ensure agents operate against a fixed, validated repository state.
- **Ephemeral Workspaces (All)**: Isolated, copy-on-write (COW) environments
  that are discarded after use, preserving only explicitly declared artifacts.
- **Observability-First (Claude/Gemini)**: Unified logs, metrics, and traces
  for every run to enable debugging of complex autonomous behaviors.

## 3. Architecture Overview

The system is partitioned into three functional layers:

### 3.1 Control Plane (The Brain)

Manages the lifecycle, policy, and state of all agent runs.

- **API Gateway**: Entry point for run submission and status tracking.
- **Orchestrator**: A stateless state machine managing transitions (Submitted →
  Scheduled → Running → Completed).
- **Spec Resolver**: Validates planning artifacts (`spec.md`, `plan.md`) and
  packages the **Immutable Input Bundle**.
- **Scheduler & Policy Engine**: Enforces quotas, selects **Resource Classes**,
  and handles **Conflict Detection** to prevent parallel branch collisions.

### 3.2 Message Layer (The Backbone)

Facilitates reliable, low-latency communication between components.

- **Work Queue (NATS JetStream)**: Durable, prioritized lanes for task
  dispatch.
- **Event Mesh**: Publishes real-time lifecycle events (heartbeats, logs, state
  changes).

### 3.3 Execution Plane (The Muscle)

Runs the actual agents in hardened, ephemeral environments.

- **Worker Controller**: A Kubernetes Operator that manages the lifecycle of
  **Agent Pods**.
- **Isolated Runner**: A gVisor-sandboxed container with a read-only root
  filesystem and restricted syscall access.
- **Workspace Manager**: Manages the **Overlay Filesystem** (COW) and
  validates declared output artifacts against a manifest.

## 4. Key Architectural Features

### 4.1 Immutable Input Bundles (Claude)

Before a run starts, the control plane resolves the target repository state and
planning artifacts into a versioned bundle stored in S3. The agent container
mounts this bundle as a read-only volume, ensuring it cannot deviate from the
approved plan or operate on a moving integration target.

### 4.2 Resource & Execution Classes (Codex/Claude)

To optimize cost and performance, runs are categorized into classes:

| Class | CPU | RAM | Storage | Use Case |
| --- | --- | --- | --- | --- |
| **Nano** | 0.1 | 256MB | 1GB | Metadata & Status Checks |
| **Standard** | 1.0 | 2GB | 10GB | Feature Implementation & Bug Fixes |
| **Heavy** | 4.0 | 8GB | 50GB | Large Analysis & Refactoring |
| **Secure** | 2.0 | 4GB | 20GB | Auth & Platform (gVisor mandatory) |

### 4.3 Overlay Workspace Model (Gemini)

Each pod uses an overlay filesystem where a base image (containing the toolset)
is combined with a writable ephemeral layer. This allows rapid provisioning
of fresh environments while ensuring zero state leakage between runs.

### 4.4 Conflict Detection (Claude)

The scheduler checks for overlapping branch names or file paths across all
active `in-progress` runs. If a conflict is detected, the dependent task is
held in the `standard` queue until the blocking run completes.

## 5. Security & Isolation Model

- **Runtime**: gVisor (`runsc`) provides a second kernel boundary between the
  agent and the host.
- **Networking**: Default deny-all egress. Explicit allowlists for Model APIs
  (Anthropic, OpenAI), GitHub, and Artifact Storage.
- **Credentials**: Short-lived GitHub tokens and API keys are injected via
  projected Kubernetes secrets, scoped to the specific run, and revoked on
  completion.
- **Identity**: IRSA (AWS) or Workload Identity (GCP) used for all cloud resource
  access.

## 6. Execution Lifecycle

1. **Intake**: Request submitted with Task ID and Commit SHA.
2. **Resolve**: Spec Resolver fetches artifacts, validates T-Gate requirements,
   and uploads the Input Bundle to S3.
3. **Schedule**: Scheduler selects a Resource Class and checks for concurrency
   conflicts.
4. **Dispatch**: Task is pushed to the NATS Work Queue.
5. **Launch**: Worker Controller starts a gVisor-sandboxed Pod.
6. **Execute**: Agent container pulls the bundle, clones the repo, and runs
   the TDD-implementation loop.
7. **Monitor**: Telemetry sidecar streams logs and heartbeats to the Event Mesh.
8. **Finalize**: Workspace Manager validates the output manifest and pushes
   artifacts to S3.
9. **Update**: GitHub Integration Service updates Issue status and PR links.
10. **Cleanup**: Pod is deleted; ephemeral storage is purged.

## 7. Observability Stack (Claude)

The architecture leverages the **LGTM** (Loki, Grafana, Tempo, Mimir) stack for
comprehensive visibility:

- **Logs (Loki)**: Structured JSONL logs indexed by `RunID` and `TaskID`.
- **Metrics (Mimir/Prometheus)**: System health and per-run resource usage.
- **Traces (Tempo)**: OpenTelemetry spans covering the entire flow from API
  call to container syscall.

## 8. Technology Stack Summary

| Layer | Recommended Technology |
| --- | --- |
| **Compute** | Kubernetes (EKS/GKE) with gVisor |
| **Orchestration** | Custom Kubernetes Operator + NATS JetStream |
| **State Store** | PostgreSQL (Aurora Serverless) |
| **Artifact Store** | S3-compatible Object Storage |
| **Observability** | OpenTelemetry + Grafana Cloud/Self-hosted |
| **Autoscaling** | KEDA (Queue-depth driven) |

## 9. Conclusion

This unified approach provides the Archive Agentic project with a production-grade
execution substrate. By combining Claude's orchestration depth, Codex's
operational resilience, and Gemini's technical sandboxing, the system achieves
the necessary balance between autonomy, safety, and scale.
