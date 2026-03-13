# Architecture Proposal Analysis

**Date**: 2026-03-13
**Scope**: Comparative analysis of three agentic execution architecture proposals authored independently by Codex, Gemini, and Claude.

**Documents reviewed**:
- `docs/codex/architecture-proposal.md` — authored by OpenAI Codex
- `docs/gemini/architecture-proposal.md` — authored by Google Gemini
- `docs/claude/architecture-proposal.md` — authored by Anthropic Claude

---

## 1. Overview

The three proposals address the same problem — executing AI agents in isolated containers at scale — but differ substantially in depth, specificity, and emphasis. The comparison is organized across 12 dimensions. A synthesis recommendation follows.

| Dimension | Codex | Gemini | Claude |
|---|---|---|---|
| Length | ~300 lines | ~100 lines | ~780 lines |
| Technology specificity | Abstract | Moderate | Concrete |
| Process integration | None | Minimal | Extensive |
| Phased delivery | Yes (3 phases) | No | Yes (3 phases) |
| ADR identification | 5 items | None | 10 items |
| Multi-agent coordination | Yes | No | Yes |
| Execution class taxonomy | Conceptual | None | Concrete with values |
| Observability depth | Conceptual | Minimal | Concrete with schemas |
| Failure handling | Strong | Absent | Moderate |
| Security depth | Strong | Brief | Strong |

---

## 2. Where All Three Agree

The proposals share a common architectural foundation. These points are safe to treat as settled:

- **One container per agent run.** Execution is isolated; no shared mutable hosts.
- **Control plane / data plane separation.** Orchestration is distinct from execution.
- **Ephemeral execution environments.** Containers are created fresh per run and discarded after completion.
- **Durable artifact persistence.** Container filesystems are not the system of record. Outputs go to object storage.
- **Event-driven / async orchestration.** A work queue decouples run submission from worker availability.
- **Deny-all egress by default.** Network access is explicitly allowlisted per run.
- **Least privilege.** Non-root containers, read-only root filesystem, minimal credentials.
- **Kubernetes as the compute substrate** (though Gemini frames it as optional for enterprise scale; the other two treat it as the default).

---

## 3. Dimension-by-Dimension Comparison

### 3.1 Core Principles

**Codex** articulates the most complete principle set. Its standout contribution is the explicit framing of **failure domain design** as a first-class principle: one bad agent run must not affect unrelated runs. It also introduces **checkpointing for multi-step workflows** — failed steps should be resumable without replaying from the start. Neither other proposal addresses this.

**Gemini** names four design principles (strong isolation, async orchestration, ephemeral workspace, observability-first). The principles are sound but brief. Its unique framing is **copy-on-write (COW) workspace** — explicit about the filesystem mechanism rather than just saying "ephemeral."

**Claude** adds two principles not found in the others: **append-only execution records** (run state transitions are never mutated, only appended) and **explicit artifact declaration** (agents write a manifest declaring what they produced; undeclared side effects are not permitted). The append-only principle is especially important for audit integrity. The manifest model prevents agents from writing to arbitrary locations.

**Gap**: No proposal explicitly names idempotency as a principle, though Codex mentions idempotent state transitions under reliability.

---

### 3.2 Component Decomposition

**Codex** defines five top-level areas:

1. Control Plane (API Gateway, Execution Orchestrator, Scheduler, State Service, Policy Service)
2. Execution Data Plane (pods, optional sidecars)
3. Queue and Event Backbone (Work Queue, Event Bus, DLQ)
4. Persistence Layer (relational DB, object storage, **search index**, metrics store)
5. Workspace and Artifact Model

Codex is the only proposal to include a **Search Index** in the persistence layer, enabling fast lookup across logs, artifacts, and traces. This is a meaningful operational capability omitted by the others.

Codex also separates **Policy Service** as a named control plane component. The other proposals fold admission and quota policy into the scheduler or orchestrator.

**Gemini** defines four areas:

1. Agent Orchestrator (Task Ingestion, Scheduler, Lifecycle Management)
2. Isolated Runner (gVisor/Kata Containers, cgroups, network isolation)
3. Workspace Layer (overlay filesystem, artifact persistence)
4. Event Mesh (NATS or Redis Streams)

Gemini collapses the Work Queue and Event Bus into a single **Event Mesh**. This is architecturally looser — work dispatch and lifecycle telemetry have different durability, delivery, and consumer requirements and are better separated.

**Claude** defines five layers:

1. Control Plane (API Service, Orchestrator with explicit state machine, Scheduler/Policy)
2. Message Layer (Work Queue with priority lanes, Event Bus, DLQ — explicitly separated)
3. Execution Plane (Worker Controller as K8s Operator, Agent Pod with init container + agent + telemetry sidecar, Workspace model)
4. Persistence Layer (S3, Loki, Prometheus, Tempo)
5. **External Integrations** (GitHub, Graphite, Spec Resolver)

Claude is the only proposal to name **External Integrations** as a dedicated architectural layer. The **Spec Resolver** — a service that validates planning artifacts before admitting a run — is a unique invention. The **GitHub Integration Service** — which maps run lifecycle events to Issue label changes and PR actions — is also unique.

Claude's state machine is the most explicit: `submitted → validated → scheduled → launching → running → completing → done / failed / cancelled / timed_out`.

---

### 3.3 Container Runtime and Isolation

This is the most significant point of divergence.

**Gemini** proposes **gVisor or Kata Containers as the default runtime for all agent executions**. This is the strongest isolation stance — syscall-level sandboxing prevents an agent from escaping the container boundary even through kernel vulnerabilities. The tradeoff is higher cold-start latency and operational complexity for all workloads.

**Claude** proposes **containerd as the default runtime, with gVisor reserved for a dedicated `secure` execution class** used only for high-risk workloads (auth, persistence, platform tasks). This is a pragmatic middle ground: most runs get standard container isolation, sensitive runs get enhanced isolation.

**Codex** makes no recommendation on container runtime. It describes the security controls (non-root, RO FS, drop capabilities, seccomp, AppArmor) but treats runtime selection as a decision to be formalized as an ADR.

**Assessment**: The Gemini stance (gVisor by default) maximizes security but introduces a real operational cost. The Claude stance (gVisor per execution class) is a reasonable production trade-off. The Codex stance (defer the decision) is appropriate given its stated goal of avoiding premature vendor selection, but the question must be resolved before implementation.

---

### 3.4 Message Infrastructure

**Codex** is technology-agnostic. It describes Work Queue, Event Bus, and DLQ as conceptual requirements. It adds one strategic note absent from the others: if the system eventually needs long-lived, highly stateful agent graphs, add a **workflow engine above Kubernetes** rather than encoding workflow semantics inside individual pods. This is a meaningful architectural guardrail.

**Gemini** proposes **NATS or Redis Streams** for the Event Mesh. It merges work dispatch and lifecycle telemetry into one system. No DLQ is mentioned.

**Claude** proposes **NATS JetStream** specifically, with explicit rationale (simpler than Kafka, no ZooKeeper, sufficient throughput for agentic workloads). Separates Work Queue from Event Bus. Defines four priority lanes (critical, standard, background, retry) with KEDA-based autoscaling parameters.

---

### 3.5 Observability

**Codex** offers the strongest conceptual framing. Its four operator questions are the best expression of observability intent in any of the three proposals:

> 1. What is running now?
> 2. Why is a run blocked or slow?
> 3. What did a specific agent do?
> 4. Which resource or policy limit caused the issue?

Codex names the right signals (logs, traces, metrics, audit events) and includes **cost per run** as a metric, which neither other proposal mentions. It does not recommend specific tools.

**Gemini** mentions log streaming (Loki or Elasticsearch) and syscall-level audit logs. The syscall audit capability — recording every command and syscall an agent makes — is a strong security and debugging feature unique to this proposal. It is a natural complement to gVisor, which can intercept syscalls for exactly this purpose.

**Claude** is the most operationally complete. It provides: a JSONL log schema with required fields, five named Prometheus metrics, five Grafana alerting rules with severity and thresholds, a canonical dashboard description, and OpenTelemetry trace context propagation via environment variable. The specificity is actionable.

**Gap**: No proposal discusses log retention policy, log-level control per run, or sampling strategies for high-volume trace data.

---

### 3.6 Security

All three are aligned on the core controls. The differences are in depth and specificity.

**Codex** is the most organized. Its security section covers three distinct concerns — container hardening, secret handling, and network/tool safety — with clear guidance in each. The unique addition is **routing tool access through audited service gateways**: agent API calls to external tools should pass through a proxy that logs and optionally rate-limits them. This is a meaningful defense-in-depth layer absent from the others.

**Gemini** is brief. It adds **syscall-level audit logging** (every command and syscall recorded), which is a strong security property but only achievable with gVisor. If gVisor is not the default runtime, this capability disappears for most runs.

**Claude** is the most complete in terms of Kubernetes specifics. It provides: explicit `securityContext` YAML, three network egress tiers (Standard / Extended / Restricted), credential injection via mounted volumes not environment variables, IRSA/Workload Identity for cloud credentials, namespace topology (four named namespaces), signed images with digest pinning and SBOM generation, and per-run secret revocation.

---

### 3.7 Scalability

**Codex** defines the right conceptual shape: stateless horizontal scaling for control plane, K8s autoscaling for workers, queue partitioning by priority/tenant/workload. It introduces a **GPU execution class** (for model serving or inference) not present in the other proposals. This is forward-looking and worth retaining.

**Gemini** says very little beyond "dynamically provision additional runner nodes in response to queue depth."

**Claude** is the most concrete. It names KEDA, provides specific scaling parameters per lane, mentions node pool pre-warming for cold-start reduction, and describes a database scaling path (read replicas, PgBouncer, partitioned tables). The five execution classes have explicit CPU, memory, storage, timeout, and runtime values.

---

### 3.8 Multi-Agent Coordination

**Codex** defines the key principle: coordinate through the control plane, not container networking. Agents should not shell into peer containers. Shared context should move through persisted artifacts, event streams, or task contracts. Cross-agent locks should be rare and handled centrally. This framing prevents agentic systems from becoming ad hoc distributed systems.

**Gemini** does not address multi-agent coordination.

**Claude** is the most concrete. It defines three patterns: **fan-out** (parallel independent tasks dispatched simultaneously), **dependency chains** (sequential enforcement — B will not dispatch until A is done and committed), and **conflict detection** (prevent parallel runs from checking out conflicting branches). The conflict detection mechanism is unique and directly relevant to the implementation process defined in this repository.

---

### 3.9 Process Integration

**Codex** does not address integration with the planning, tracking, implementation, or review processes. It treats this as out of scope for an architecture proposal.

**Gemini** briefly mentions that `spec.md` and `plan.md` are artifacts that get persisted. No further integration.

**Claude** dedicates a full section to this. It maps each of the four processes to specific system behavior:
- Planning: Spec Resolver validates artifacts pre-flight and packages them into the immutable input bundle
- Tracking: GitHub Integration Service syncs Issue labels in response to run lifecycle events
- Implementation: Agent containers are pre-configured with Graphite CLI, commit format, and TDD protocol
- Review: A review agent run type produces a structured `review.json` verdict posted as a GitHub PR review

This integration mapping is a significant contribution. The Spec Resolver pattern — rejecting a run before it consumes execution resources if planning artifacts are incomplete — enforces the process gates defined in the planning process document.

---

### 3.10 Phased Delivery

**Codex** and **Claude** both propose the same three-phase structure (single region → operational maturity → multi-region). Codex is conceptual; Claude provides specific deliverables and ADRs required per phase.

**Gemini** provides no phased delivery plan.

---

### 3.11 Technology Specificity

**Codex** is intentionally abstract. It names Kubernetes, Postgres, S3, and OpenTelemetry as the pattern, explicitly deferring vendor selection to ADRs.

**Gemini** names gVisor/Kata Containers and NATS/Redis Streams as specific technologies. Loki or Elasticsearch for logs.

**Claude** provides the most complete technology table with rationale for each choice. It is the only proposal to recommend specific tools for autoscaling (KEDA), deployment (Argo CD), ingress (AWS ALB), and long-term metrics retention (Thanos).

---

### 3.12 Gaps by Proposal

**Codex gaps**:
- No concrete technology recommendations (by design, but leaves implementers without guidance)
- No execution class resource values
- No process integration
- No artifact manifest model
- No conflict detection
- No example lifecycle flow step-by-step
- No alert definitions

**Gemini gaps**:
- Substantially thinner than the others — not implementation-ready on its own
- No phased delivery
- No ADR identification
- No multi-agent coordination
- No execution class taxonomy
- No failure handling beyond basic mentions
- Merging Work Queue and Event Bus into Event Mesh is an architectural concern
- gVisor-by-default carries operational overhead that is not discussed

**Claude gaps**:
- No GPU execution class (present in Codex)
- No checkpointing / resumable step pattern (present in Codex)
- No service gateway for tool access (present in Codex)
- No workflow engine recommendation for long-lived agent graphs (present in Codex)
- No syscall-level audit logging (implied by Gemini's gVisor stance)
- No cost-per-run metric (mentioned by Codex)
- Claims to supersede the other proposals before any team review has occurred

---

## 4. Unique Contributions Worth Preserving

The following items appear in only one proposal and should not be lost in synthesis:

| Contribution | Source | Why It Matters |
|---|---|---|
| Failure domain as explicit principle | Codex | Prevents blast radius from run failures |
| Checkpointing for resumable steps | Codex | Avoids replaying expensive work on transient failure |
| GPU execution class | Codex | Required if any model inference runs locally |
| Four operator questions | Codex | Best framing of observability intent |
| Cost per run as a named metric | Codex | Required for quota/billing accountability |
| Workflow engine above K8s for stateful graphs | Codex | Important guardrail against encoding workflow in pods |
| Policy Service as a distinct component | Codex | Enables pluggable admission control |
| Search index in persistence layer | Codex | Fast cross-artifact query capability |
| Audited tool service gateways | Codex | Defense-in-depth for external tool calls |
| Copy-on-write workspace (explicit mechanism) | Gemini | Clarifies how overlay filesystem works |
| Syscall-level audit logging | Gemini | Strong security property when using gVisor |
| gVisor/Kata as security option | Gemini | Kernel-level sandboxing beyond standard containers |
| Append-only execution records | Claude | Audit trail integrity |
| Explicit artifact declaration / manifest | Claude | Prevents arbitrary side effects, validates outputs |
| Spec Resolver as an architectural component | Claude | Enforces planning gates before execution resource use |
| GitHub Integration Service | Claude | Keeps Issue state synchronized with run state |
| Conflict detection for parallel branches | Claude | Prevents merge conflicts by construction |
| Review agent as a run type | Claude | Closes the loop on the review process |
| Network egress tiers | Claude | Graduated access control per task sensitivity |
| IRSA / Workload Identity | Claude | Eliminates long-lived cloud credentials in pods |
| KEDA with specific scaling parameters | Claude | Concrete autoscaling guidance |
| Named alert rules with severity | Claude | Actionable on-call guidance |
| JSONL log schema with required fields | Claude | Consistent log structure for query |

---

## 5. Points of Disagreement Requiring Resolution

These are genuine conflicts or open questions that a final architecture must resolve:

### 5.1 gVisor: Default vs Execution Class

- **Gemini**: gVisor for all runs by default
- **Claude**: gVisor only for the `secure` execution class
- **Codex**: Defers to an ADR

**Analysis**: Using gVisor for all runs provides the strongest security baseline but adds latency (typically 50–200ms cold-start overhead above standard containerd) and requires additional node configuration. The Claude approach (class-based) is more operationally pragmatic and allows the team to start with standard containerd and add gVisor for sensitive workloads. However, if the agent runtime itself is not trusted, gVisor by default is a stronger posture. The decision depends on the threat model: is the concern an agent being exploited, or the agent itself behaving adversarially?

### 5.2 Event Mesh: Unified vs Separated

- **Gemini**: Single Event Mesh for all messaging
- **Codex/Claude**: Separate Work Queue and Event Bus

**Analysis**: The Gemini simplification risks conflating two systems with different semantics. The Work Queue needs at-least-once delivery, consumer group semantics, and dead-letter handling for unprocessable work items. The Event Bus needs fan-out to multiple consumers (GitHub integration, audit logger, observability pipeline) for the same event. A single queue cannot easily serve both models. The Codex/Claude separation is the more defensible architecture.

### 5.3 Technology Specificity vs ADR Deference

- **Codex**: Deliberately avoids naming specific technologies, requires ADRs
- **Claude**: Names specific technologies with rationale, still requires ADRs

**Analysis**: Both approaches are consistent — Claude makes recommendations while acknowledging they require ADR ratification. The Claude approach is more useful for planning. The risk is that concrete recommendations become anchors that are hard to revisit. The synthesis should make clear that technology names in proposals are candidate recommendations, not decisions.

### 5.4 Long-Lived Stateful Agent Graphs

**Codex** uniquely warns that if the system needs very long-lived, highly stateful agent graph execution, a **workflow engine** (such as Temporal or Argo Workflows) should sit above Kubernetes, rather than encoding workflow semantics inside individual pods. Neither other proposal addresses this. The agentic harness processes do decompose work into discrete tasks, which maps well to individual pod runs, but multi-task features with dependencies are effectively workflows. This is worth resolving early.

---

## 6. Synthesis Recommendation

A final architecture proposal should incorporate the following from each source:

**From Codex**:
- Failure domain design as a named foundational principle
- Checkpointing / resumable step pattern for multi-step agent workflows
- GPU execution class in the execution class taxonomy
- Four operator questions as the observability charter
- Cost per run as a required metric
- Workflow engine recommendation for stateful agent graphs
- Policy Service as a distinct, named component
- Search index in the persistence layer
- Audited service gateway for external tool calls

**From Gemini**:
- Explicit copy-on-write filesystem mechanism language for the workspace model
- Syscall-level audit logging as a security requirement (achievable with gVisor)
- gVisor as a named default option for high-security workloads (adopted in the `secure` class)

**From Claude**:
- Append-only execution records principle
- Explicit artifact declaration and manifest validation model
- Spec Resolver as an architectural component
- GitHub Integration Service and the event-to-Issue-label mapping
- Conflict detection for parallel agent branch collisions
- Review agent as a distinct run type
- Network egress tiers (Standard / Extended / Restricted)
- IRSA / Workload Identity for cloud credentials
- KEDA with per-lane scaling parameters
- Named Prometheus metrics and alert rules
- JSONL log schema with required fields
- 10-item ADR backlog
- 8 open questions

**Resolve explicitly**:
- gVisor default vs class-based: recommend class-based (containerd default, gVisor for `secure` class), but escalate the threat model question to the team
- Event Mesh vs separated queue/bus: adopt the separated model (Work Queue + Event Bus + DLQ)
- Workflow engine: make a Phase 2 decision on whether Temporal or Argo Workflows is needed for multi-task dependency chains, or whether orchestrator-enforced dependency sequencing is sufficient

---

## 7. Process Compliance Note

Per `AGENTS.md`, all significant architectural decisions must be documented as ADRs in `docs/adr/` before implementation. None of the three proposals are ADRs. Each should be treated as pre-ADR input.

The combined ADR backlog to resolve before Phase 1 implementation begins:

1. Compute substrate and cloud provider (K8s, EKS vs GKE vs self-hosted)
2. Container runtime strategy (containerd default, gVisor for secure class vs gVisor default)
3. Message infrastructure (NATS JetStream vs Kafka vs SQS+SNS, Work Queue vs unified Event Mesh)
4. Metadata store (PostgreSQL / Aurora vs CockroachDB)
5. Artifact and log storage (S3 vs GCS vs R2)
6. Secret management (AWS Secrets Manager + IRSA vs Vault)
7. Observability stack (Grafana stack vs Datadog vs CloudWatch)
8. Workflow engine for stateful multi-task graphs (Temporal / Argo Workflows vs orchestrator-enforced sequencing)
9. Execution class taxonomy and resource values
10. Multi-tenant quota and fairness model
11. Audit strategy (append-only DB records vs external SIEM, syscall logs vs application logs)
12. GitOps and deployment tooling (Argo CD vs Flux vs Helm+CI)

---

*This analysis should be reviewed by all contributors before a final architecture proposal is drafted and ADRs are created.*
