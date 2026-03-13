# Analysis of Agentic Execution Architecture Proposals

## Scope

This report compares the three architecture proposals in:

- `docs/claude/architecture-proposal.md`
- `docs/codex/architecture-proposal.md`
- `docs/gemini/architecture-proposal.md`

The goal is to identify where the proposals align, where they differ, and
which ideas appear strongest for an implementation-ready architecture.

## Executive Summary

All three proposals agree on the core direction:

- agents should run in isolated containers
- the platform should use asynchronous orchestration
- execution state and artifacts should be persisted durably
- the system should scale horizontally rather than rely on long-lived workers

The main difference is depth and specificity.

- The `codex` proposal provides the clearest high-level platform architecture.
- The `gemini` proposal contributes the strongest low-level isolation ideas,
  especially sandboxing and workspace design.
- The `claude` proposal is the most complete overall and is effectively a
  synthesis of the other two, with stronger operational detail and explicit
  integration into the repository's planning, tracking, implementation, and
  review workflows.

If the team wants a single baseline to advance into ADRs, the `claude`
proposal is the best starting point. Its strongest elements should be retained,
but some of its operational choices should still be treated as proposals rather
than settled decisions.

## Where the Proposals Converge

### Isolation Model

All three recommend one isolated execution environment per agent run. They all
reject shared mutable execution hosts as the default model.

- `codex` recommends one pod per run on Kubernetes.
- `gemini` recommends dedicated hardened containers with optional gVisor or
  Kata Containers.
- `claude` recommends one pod per run and adds execution classes, including a
  more secure runtime tier.

This is the clearest area of consensus and should be treated as the default
architectural direction.

### Control Plane and Data Plane Separation

All three separate orchestration from execution.

- `codex` uses an API, orchestrator, scheduler, policy service, and worker
  controller model.
- `gemini` uses an orchestrator, runner pool, workspace layer, and event mesh.
- `claude` formalizes the split most thoroughly and turns the orchestrator into
  a durable state machine.

This separation is important for both scale and operational clarity. None of
the proposals argue for embedding scheduling logic directly in the workers.

### Asynchronous Execution

All three prefer queue-driven execution rather than synchronous request/worker
coupling.

- `codex` describes a work queue plus event bus.
- `gemini` proposes NATS or Redis Streams.
- `claude` recommends priority lanes, an event bus, and a dead-letter queue.

This is another strong consensus point. It gives the platform backpressure,
retry control, and better fault isolation.

### Ephemeral Workspaces and Durable Artifacts

All three separate temporary execution state from persisted outputs.

- `codex` emphasizes immutable input bundles and declared outputs.
- `gemini` emphasizes overlay filesystems and discard-on-exit workspaces.
- `claude` combines both into a cleaner manifest-driven artifact model.

This suggests the platform should avoid shared long-lived workspaces and should
persist only intentional outputs.

## Major Differences

### Level of Specificity

The proposals operate at three different altitudes.

- `gemini` is concise and infrastructure-oriented. It says what secure runner
  environments should look like but says less about workflow integration.
- `codex` is a platform architecture document. It is stronger on system
  boundaries, scale, reliability, and security posture.
- `claude` goes further into implementation mechanics, operational workflows,
  event contracts, GitHub process integration, execution classes, and ADR
  backlog framing.

This matters because the proposals are not direct substitutes. `gemini` reads
more like a technical note. `codex` reads like an architecture proposal.
`claude` reads like a pre-implementation system design.

### Technology Commitments

The `codex` proposal deliberately avoids locking in too many technologies.
That is a strength at the proposal stage.

The `gemini` proposal makes several concrete suggestions:

- gVisor or Kata Containers for stronger runtime isolation
- NATS or Redis Streams for messaging
- overlay filesystems for copy-on-write workspaces

The `claude` proposal goes further and recommends a concrete stack:

- Kubernetes
- NATS JetStream
- PostgreSQL
- S3
- Grafana Loki, Prometheus, and Tempo
- KEDA
- Argo CD

The tradeoff is clear:

- `codex` preserves optionality.
- `gemini` introduces strong targeted ideas without overcommitting.
- `claude` is more actionable, but its stack recommendations should still be
  ratified as ADRs rather than accepted by document length alone.

### Security Depth

The `gemini` proposal is strongest on raw sandboxing posture.

- It explicitly foregrounds gVisor or Kata.
- It calls for syscall-level observability.
- It is more explicit about hardening the runner environment.

The `codex` proposal is strong on platform security controls:

- least privilege
- deny-by-default networking
- short-lived credentials
- per-run service accounts
- hardened containers

The `claude` proposal combines both and adds stronger execution policy detail:

- separate secure execution class
- mounted secret volumes rather than environment variables
- namespace isolation
- image signing and SBOMs
- policy-backed egress classes

On balance, `claude` is the most complete security proposal, but it clearly
inherits the strongest runtime-isolation ideas from `gemini`.

### Multi-Agent Coordination

This is the area with the largest maturity gap.

- `gemini` mostly focuses on single-run execution infrastructure.
- `codex` argues that agents should coordinate through the control plane and
  persisted artifacts instead of direct peer-to-peer coupling.
- `claude` adds concrete fan-out, dependency-chain, and conflict-detection
  models tied to `tasks.md` and repository workflows.

For a system expected to run many agents simultaneously, `claude` provides the
only proposal that seriously addresses coordination semantics beyond basic
parallel execution.

### Process Integration

The `claude` proposal is the only one tightly integrated with the repository's
existing planning and delivery processes.

- It validates `spec.md`, `plan.md`, `tasks.md`, and ADR presence before
  execution.
- It connects run state to GitHub issue and PR transitions.
- It models review as a first-class agent run type.

The `codex` proposal is process-compatible but intentionally generic.

The `gemini` proposal is platform-focused and largely ignores the repository's
specific planning and tracking machinery.

If the execution system is meant to operationalize the repo's documented
workflow, `claude` is much closer to that target.

## Strengths by Proposal

### `docs/codex/architecture-proposal.md`

Strengths:

- Cleanest high-level architectural decomposition.
- Strong emphasis on scalability, reliability, and horizontal operation.
- Good separation between proposal-stage guidance and later ADR decisions.
- Sensible recommendation to treat shared mutable state as exceptional.

Weaknesses:

- Less explicit about concrete integration with repo workflows.
- Less detailed on how multi-agent conflicts should be managed.
- Leaves several implementation seams unspecified.

### `docs/gemini/architecture-proposal.md`

Strengths:

- Strongest emphasis on hardened execution sandboxes.
- Useful suggestions around gVisor, Kata Containers, and overlay filesystems.
- Concise and operationally direct.

Weaknesses:

- Too brief to serve as the main architecture document by itself.
- Underdeveloped control-plane, persistence, and workflow semantics.
- Little detail on retries, coordination, quotas, or auditability beyond logs.

### `docs/claude/architecture-proposal.md`

Strengths:

- Most complete end-to-end proposal.
- Best synthesis of platform architecture, execution mechanics, and repo
  workflow integration.
- Strong observability, quota, scaling, and operational detail.
- Explicit ADR backlog makes it easier to move from proposal to decision.

Weaknesses:

- Considerably more opinionated and potentially over-specified for the current
  decision stage.
- Some recommendations may imply more implementation complexity than Phase 1
  actually needs.
- Conflict detection by branch or file path is directionally good but may be
  difficult to implement accurately without false positives or excessive queue
  serialization.

## Recommended Synthesis

The strongest combined architecture is:

- use the `codex` proposal as the core structural model
- use the `gemini` proposal for runtime hardening and workspace isolation
- use the `claude` proposal for workflow integration, observability, and phased
  operational maturity

Concretely, the best near-term synthesis appears to be:

1. Kubernetes-based ephemeral pod-per-run execution.
1. Durable queue plus event bus decoupling submission from execution.
1. Postgres for transactional metadata and object storage for artifacts.
1. Immutable input bundles and manifest-declared outputs.
1. Deny-by-default networking, short-lived credentials, and non-root hardened
   containers.
1. Optional secure execution class using gVisor for high-risk tasks.
1. Control-plane-managed multi-agent coordination rather than direct
   agent-to-agent communication.
1. Process-aware admission checks against planning and tracking artifacts.

This combination preserves the best ideas from all three while avoiding the
two biggest risks:

- under-specifying the system so implementation drifts
- overcommitting to every operational detail before ADRs are written

## Points That Still Need ADRs

The proposals narrow the option space, but they do not eliminate the need for
formal decisions. The most important ADR candidates are:

- orchestration substrate and cloud model
- queue and event backbone
- runtime isolation tiering, including whether gVisor is required at launch
- artifact, log, and trace storage boundaries
- secret injection and identity model
- multi-agent dependency and conflict-management policy
- quota and fairness policy for concurrent teams or workloads

## Final Assessment

The three proposals are complementary rather than contradictory.

- `gemini` contributes the best sandboxing instincts.
- `codex` contributes the best architectural framing.
- `claude` contributes the best implementation path and operational detail.

The strongest path forward is to treat the `claude` proposal as the leading
draft, validate its concrete stack decisions through ADRs, and preserve the
`codex` proposal's restraint where the team has not yet earned the right to
standardize on a specific tool or operational pattern.
