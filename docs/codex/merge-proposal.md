# Proposal for Merging the Agentic Execution Architecture Documents

## Purpose

This document proposes how to merge the three architecture proposals into a
single, cohesive thoughtstream that preserves the strongest ideas from each:

- `docs/codex/architecture-proposal.md`
- `docs/gemini/architecture-proposal.md`
- `docs/claude/architecture-proposal.md`

The goal is not to mechanically combine them. The goal is to produce one
architecture narrative that is internally consistent, appropriately scoped for
the current planning stage, and strong enough to serve as the basis for ADRs.

## Recommended Merge Strategy

The merged document should use the `claude` proposal as the primary narrative
spine, but it should be edited to incorporate:

- the `codex` proposal's cleaner high-level architecture framing and restraint
  around premature technology lock-in
- the `gemini` proposal's stronger emphasis on sandboxing, hardened runtime
  boundaries, and copy-on-write workspace design

In practice, this means the merged document should feel like:

- `codex` for architecture structure
- `gemini` for execution isolation depth
- `claude` for operational completeness and workflow integration

## Why This Is the Right Merge Direction

The three documents are not equal in scope.

- `gemini` is too brief to stand alone as the canonical architecture document.
- `codex` is strong structurally, but leaves too many implementation seams
  open if used alone.
- `claude` is the most complete, but it risks overcommitting to operational
  specifics before ADRs are written.

Using `claude` as the base avoids losing the strongest process, lifecycle, and
operability material. Pulling in `codex` and `gemini` keeps the final document
from becoming either too generic or too prematurely fixed.

## Proposed Unified Thoughtstream

The merged document should tell one clear story in this order.

### 1. State the Problem in Platform Terms

Open with the need for a scalable execution substrate for many concurrent
agents operating safely in isolation while integrating with the repository's
planning, tracking, implementation, and review processes.

This opening should come primarily from `claude`, but should be simplified
using the clearer framing style from `codex`.

### 2. Establish the Core Architectural Principles

The merged document should explicitly define the foundational principles early:

- control plane and data plane separation
- stateless orchestration with durable state
- ephemeral execution environments
- immutable input bundles
- append-only execution and audit records
- explicit artifact declaration
- failure-domain isolation

This section should mostly come from `claude`, because it is the strongest
expression of platform design intent.

### 3. Present the High-Level Architecture Cleanly

The system model should follow the simpler and clearer decomposition from
`codex`:

- control plane
- execution data plane
- queue and event backbone
- persistence layer
- workspace and artifact model

This is the strongest architecture skeleton across the three proposals. The
`claude` diagrams and examples can still be used, but the section structure
should remain closer to `codex` because it is easier to reason about.

### 4. Deepen the Execution Isolation Model

The execution section should explicitly adopt the strongest isolation concepts
from `gemini`, refined by `claude`:

- one pod or container per agent run
- hardened OCI runtime defaults
- non-root execution
- read-only root filesystem
- deny-by-default networking
- copy-on-write ephemeral workspaces
- optional stronger runtime isolation for sensitive tasks using gVisor or Kata

The merged document should not treat stronger sandboxing as a side note. It
should be a first-class part of the architecture because container isolation is
one of the core problem constraints.

### 5. Define the Workspace and Artifact Contract

This section should combine:

- `gemini`'s overlay filesystem concept
- `codex`'s immutable input bundle and declared-output model
- `claude`'s manifest-based artifact validation

The unified concept should be:

- each run starts from a versioned input bundle
- the agent operates in an ephemeral writable workspace
- only declared outputs are persisted
- workspace state is destroyed after the run completes

This is one of the best natural synthesis points across all three documents.

### 6. Define the Control Plane as a Durable State Machine

The merged document should preserve `claude`'s stronger lifecycle semantics,
while keeping the service model readable:

- API service
- orchestrator
- scheduler and policy layer
- state store
- worker controller

The lifecycle should be explicit and durable. `claude` is strongest here
because it moves beyond "a scheduler exists" and explains how state transitions
are actually managed.

### 7. Keep Queueing and Events as First-Class Infrastructure

All three proposals imply asynchronous orchestration, but the merged document
should make it explicit that the platform depends on:

- a durable work queue
- an event stream or event bus
- dead-letter handling
- heartbeats and lease-based failure detection

This section should adopt `codex`'s clear separation and `claude`'s more
complete operational semantics. Technology names should remain recommendations
until ADRs are ratified.

### 8. Add Multi-Agent Coordination Without Overcomplicating It

The merged document should retain `claude`'s strongest multi-agent ideas, but
tighten them with `codex`'s caution against turning containers into a
peer-to-peer distributed system.

The resulting principle should be:

- agents coordinate through the control plane, event streams, and persisted
  artifacts
- parent workflows fan out child runs explicitly
- dependency chains are enforced centrally
- direct agent-to-agent networking should not be the default coordination model

This keeps the architecture scalable without creating hidden coupling.

### 9. Integrate With Existing Repository Processes

This is one of `claude`'s clearest advantages and should be preserved almost
entirely.

The merged document should state that the execution platform exists to
operationalize the repository's defined processes, not to bypass them. It
should include:

- validation of `spec.md`, `plan.md`, and `tasks.md`
- enforcement of readiness and dependency rules before execution
- artifact and status integration with GitHub issues and pull requests
- review as a first-class execution mode

This is what turns the architecture from a generic agent runner into a system
purpose-built for this repository.

### 10. Keep Security and Observability as Core, Not Optional

The merged document should preserve `codex`'s and `claude`'s security posture
and `gemini`'s runtime hardening emphasis.

Security should include:

- least privilege credentials
- secret injection at runtime
- network egress policy
- signed images and hardened container defaults
- stronger runtime isolation for sensitive workloads

Observability should include:

- structured logs
- metrics
- distributed traces
- audit events
- operator-visible queue depth, failures, and timeout patterns

This should remain a core architecture section, not an appendix.

### 11. Present Technology Choices as Recommendations Plus ADR Inputs

The merged document should avoid one common failure mode: accidentally making
stack recommendations feel final before the ADR process begins.

It should do both of the following:

- recommend a likely default stack for MVP planning
- explicitly mark those choices as subject to ADR ratification

The likely baseline can remain close to `claude`:

- Kubernetes
- PostgreSQL
- object storage
- durable queue and event backbone
- OpenTelemetry-compatible observability

But the merged narrative should keep `codex`'s discipline and avoid sounding
like these are already approved decisions.

### 12. End With a Phased Rollout and ADR Backlog

The merged document should keep `claude`'s rollout structure and ADR backlog,
because that is the best bridge from architecture thinking to implementation
planning.

It should include:

- a pragmatic Phase 1 MVP
- a Phase 2 operational maturity step
- a Phase 3 multi-tenant or multi-region step
- a clearly enumerated set of ADRs required before implementation

This gives the team a path forward instead of just a static design.

## What to Keep, Merge, and Remove

### Keep Mostly As-Is

- `claude`'s foundational principles
- `claude`'s lifecycle and process-integration sections
- `claude`'s phased delivery and ADR backlog
- `codex`'s high-level architectural decomposition
- `gemini`'s sandboxing recommendations

### Merge and Rewrite

- workspace design should merge all three proposals into one artifact contract
- security should merge `gemini`'s sandboxing with `codex` and `claude`
  platform controls
- scalability should combine `codex`'s general scaling model with `claude`'s
  execution classes and queue partitioning
- messaging should preserve optionality at the document level even if one
  technology is recommended

### Remove or Tone Down

- any wording that implies `claude` fully supersedes the other proposals
- any recommendation that sounds ratified when it should still be an ADR input
- any operational detail that adds complexity without helping Phase 1 clarity
- duplicate descriptions of the same control-plane concepts at different levels

## Recommended Structure for the Final Merged Document

The final canonical architecture document should have roughly this structure:

1. Purpose and status
1. Problem statement
1. Design goals
1. Foundational principles
1. High-level architecture
1. Control plane
1. Execution data plane
1. Workspace and artifact model
1. Queue, events, and lifecycle management
1. Isolation and security model
1. Multi-agent coordination model
1. Observability and operations
1. Integration with planning, tracking, implementation, and review
1. Recommended technology baseline
1. Phased rollout
1. ADR backlog
1. Open questions

This is effectively `claude`'s completeness organized through `codex`'s
cleaner architecture lens and reinforced with `gemini`'s security depth.

## Editorial Guidance for the Merge

When the actual merge is performed, the editor should follow these rules:

- prefer one clear explanation over repeated restatements
- keep architecture sections vendor-neutral until the recommendation section
- distinguish principles from implementation details
- distinguish recommendations from decisions
- preserve process-specific behavior only where it materially affects
  architecture
- keep the document at architecture level and avoid turning it into a full
  operational runbook

The merged document should read as a single coherent design, not as three
documents stitched together.

## Final Recommendation

Create one canonical architecture proposal using `claude` as the base draft,
restructure it using the cleaner system decomposition from `codex`, and
strengthen its execution isolation model with the runtime hardening and
workspace ideas from `gemini`.

That merged document will be the strongest foundation for the ADR set because
it preserves:

- the clearest architecture shape
- the strongest isolation posture
- the most complete execution and workflow model

This approach produces a unified document that is both strategically coherent
and practical enough to guide the next stage of architecture formalization.
