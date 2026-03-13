# Comparative Analysis of Agentic Execution Architecture Proposals

## 1. Introduction

This report analyzes and compares three architectural proposals for the Archive
Agentic Execution engine, authored by **Claude**, **Codex**, and **Gemini**. All
three proposals aim to define a secure, scalable, and isolated environment for
simultaneous agent operations.

## 2. Shared Architectural Foundations

All three agents converged on several industry best practices, indicating a
strong consensus on the fundamental requirements:

- **Container-Based Isolation**: Kubernetes is the preferred substrate for
  managing agent lifecycles, with a focus on OCI-compliant containers.
- **Control/Data Plane Separation**: A clear distinction between the
  orchestration (control) logic and the actual agent execution (data) logic.
- **Asynchronous Orchestration**: Use of message queues or event buses
  (NATS, Redis Streams, or internal Kubernetes queues) to decouple ingestion
  from execution.
- **Ephemeral Workspaces**: Agents operate in fresh, discarded-after-use
  environments, with explicit persistence of declared artifacts.
- **Security-First Approach**: Non-root execution, read-only root filesystems,
  and tightly scoped credentials/network access.

## 3. Comparison of Key Features

| Feature | Claude | Codex | Gemini |
| --- | --- | --- | --- |
| **Sandboxing** | Standard + gVisor for high-security | Kubernetes default (seccomp/AppArmor) | gVisor or Kata Containers |
| **Messaging** | NATS JetStream | "Durable Queue" (generic) | NATS or Redis Streams |
| **Workspace** | Overlay filesystem / S3 input bundle | Ephemeral writable storage | Overlay FS with writable overlay |
| **Scalability** | KEDA-based autoscaling | HPA + Cluster Autoscaling | Horizontal Runner Pool |
| **Observability** | Full OTel (Loki/Prometheus/Tempo) | Centralized logs/metrics/traces | Loki/Elasticsearch |
| **Coordination** | Conflict detection & dependency chains | Orchestration-level locks | Control-plane coordination |

## 4. Unique Contributions

### Claude's Proposal

- **Conflict Detection**: Specifically addresses the risk of parallel agents
  colliding on the same branch or file path.
- **Immutable Input Bundles**: Proposes resolving all artifacts into a
  versioned S3 bundle before execution starts for total reproducibility.
- **Detailed Lifecycle**: Provides a 10-step flow from submission to cleanup.
- **ADR Backlog**: Explicitly lists 10 required ADRs to move to implementation.

### Codex's Proposal

- **Failure Domains**: Emphasizes designing for failure so one bad run cannot
  cascade into others.
- **Resource Classes**: Defines explicit `small`, `medium`, `large`, and `gpu`
  classes to optimize scheduling and cost.
- **Checkpointing**: Suggests durable checkpoints for multi-step workflows to
  allow resumption without full replay.

### Gemini's Proposal

- **Overlay Filesystem Focus**: Detailed the COW (copy-on-write) workspace
  model.
- **Simplicity**: Provided a concise, technical blueprint focused on the
  runner's internal security and state management.

## 5. Synthesis and Recommendations

### 5.1 Consensus Pattern

The ideal architecture should adopt the **Claude** structure as the primary
framework, as it is the most comprehensive and explicitly supersedes the others
by incorporating their strengths.

### 5.2 Key Recommendations for Integration

1. **Adopt the Input Bundle Model (Claude)**: This ensures that even if a
   repository changes mid-run, the agent is working against a fixed, validated
   state.
2. **Use gVisor by Default (Gemini/Claude)**: Given the autonomous nature of
   these agents, the syscall-level sandboxing provided by gVisor is a
   mandatory security layer, not an optional one.
3. **Implement Conflict Detection (Claude)**: Essential for high-concurrency
   to prevent agents from breaking each other's git history.
4. **Enforce Resource Classes (Codex)**: Necessary for cost control and
   efficient bin-packing on the Kubernetes cluster.
5. **Unified Observability (Claude)**: Standardizing on the LGTM stack (Loki,
   Grafana, Tempo, Mimir/Prometheus) provides the best developer experience
   for debugging agent "hallucinations" or execution failures.

## 6. Conclusion

The three proposals are highly compatible, with Claude providing the most
mature orchestration model, Codex focusing on operational resilience and cost,
and Gemini detailing the execution-level isolation. Moving forward, the team
should prioritize the **ADR Backlog** defined in Claude's proposal to formalize
the final technology selections.
