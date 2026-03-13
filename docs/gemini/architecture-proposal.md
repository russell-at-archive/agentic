# Archive Agentic Execution Architecture Proposal

## 1. Introduction

The execution engine for the Archive Agentic Harness must provide a secure,
scalable, and isolated environment for multiple autonomous agents to operate
simultaneously. This proposal defines a container-native execution layer using
industry best practices for sandboxing and high-concurrency orchestration.

## 2. Design Principles

- **Strong Isolation**: Every agent execution must occur in a dedicated,
  hardened container to prevent cross-agent interference and host system
  compromise.
- **Asynchronous Orchestration**: Agents should be managed via an event-driven
  control plane to support high concurrency and durability.
- **Ephemeral Workspace**: Each agent should have an isolated,
  copy-on-write (COW) workspace that is discarded after execution, unless
  artifacts are explicitly persisted.
- **Observability-First**: Full transparency into agent logs, syscalls, and
  resource usage is mandatory for debugging and auditability.

## 3. Core Components

### 3.1 Agent Orchestrator (Control Plane)

The Orchestrator is the central hub for managing agent lifecycles.

- **Task Ingestion**: Accepts execution requests via a REST or gRPC API.
- **Scheduler**: Allocates tasks to available Runner nodes based on resource
  availability and agent priority.
- **Lifecycle Management**: Monitors agent state (Provisioning → Running →
  Finalizing → Completed/Failed).

### 3.2 Isolated Runner (Execution Plane)

The Runner environment uses OCI-compliant containers with an additional layer
of security.

- **Sandboxed Runtime**: Uses **gVisor** (`runsc`) or **Kata Containers** to
  provide a strong security boundary between the agent and the host kernel.
- **Resource Constraints**: Strict CPU, Memory, and Disk I/O limits enforced
  by cgroups.
- **Network Isolation**: Agents operate in private network namespaces with
  configurable egress filtering (default: deny-all unless specified).

### 3.3 Workspace Layer (Data Plane)

Agents require a filesystem to operate.

- **Overlay Filesystem**: Provides a base image with the required toolsets
  (e.g., git, python, node) and a writable overlay for the agent's work.
- **Artifact Persistence**: Specific directories are mounted as volumes to
  capture `spec.md`, `plan.md`, and other outputs for persistence in the main
  repository.

### 3.4 Event Mesh (Communication)

Uses **NATS** or **Redis Streams** for low-latency, asynchronous messaging
between the Orchestrator and Runners.

- **Heartbeats**: Runners signal their health and capacity to the
  Orchestrator.
- **Execution Log Streams**: Agent `stdout/stderr` is streamed in real-time to
  a centralized log aggregator (e.g., Loki or Elasticsearch).

## 4. Scalability Strategy

To support many simultaneous agents, the architecture leverages horizontal
scaling:

- **Runner Pool**: Additional runner nodes can be dynamically provisioned in
  response to queue depth.
- **Kubernetes Integration**: For enterprise-scale deployments, the
  Orchestrator acts as a Kubernetes Custom Controller (Operator), managing
  agent executions as ephemeral Pods with gVisor runtimes.

## 5. Security & Best Practices

- **Least Privilege**: Agents run as non-root users within the container.
- **Read-Only Root FS**: The container's root filesystem is read-only; agents
  can only write to designated workspace directories.
- **Audit Logs**: Every command executed and syscall made is recorded for
  security review.

## 6. Agent Lifecycle Flow

1. **Submit**: A user or higher-level agent submits a task to the
   Orchestrator.
2. **Provision**: The Orchestrator selects a Runner and requests a new
   sandboxed container.
3. **Initialize**: The Runner pulls the agent's environment image and mounts
   the task's workspace.
4. **Execute**: The agent runs its assigned logic, streaming logs and events
   to the mesh.
5. **Finalize**: The Orchestrator collects artifacts and shuts down the
   container.
6. **Cleanup**: The ephemeral workspace is purged to ensure zero state
   leakage.
