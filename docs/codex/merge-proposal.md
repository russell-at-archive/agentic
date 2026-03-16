# Merge Proposal for Team Operating Model

## Goal

Define how to merge the three existing proposals into one authoritative document with clear policies, role contracts, and operational procedures.

## Merge Strategy

1. Use `docs/claude/team-proposal.md` as the structural base.
1. Inject governance controls from `docs/codex/team-proposal.md`.
1. Inject execution-resumability and implementation hygiene patterns from `docs/gemini/team-proposal.md`.
1. Normalize terminology to canonical Linear states.
1. Mark unresolved design choices as ADR-required before implementation.

## Target Document Shape

Required sections for the merged proposal:

1. Purpose and scope.
1. Design principles.
1. Canonical Linear state machine with transition authority.
1. Role roster with strict contracts.
1. Director dispatch and orchestration model.
1. Required artifacts and evidence schema.
1. Concurrency, locking, and parallelism rules.
1. Quality gates and definition of done.
1. Failure handling and incident recovery.
1. Observability and metrics.
1. ADR-required decisions and backlog.
1. Implementation rollout plan.

## Specific Merge Decisions

## Keep from `claude`

- Detailed role operational semantics.
- Director dispatch table and state-driven invocation philosophy.
- Explicit integration with repository process documents.
- Explorer output contract and usage boundaries.

## Keep from `codex`

- Input/precondition/output/exit contract format.
- Transition gates for each state change.
- Locking model and one-engineer-per-ticket policy.
- Metrics portfolio and reporting cadence.
- ADR backlog structure.

## Keep from `gemini`

- Execution log protocol in Linear issue description.
- Spec-driven development framing.
- Canonical `make validate` recommendation.
- PR template traceability and validation evidence recommendations.

## Reconcile and standardize

- Use canonical states only: `Draft`, `Planning`, `Plan Review`, `Backlog`, `Selected`, `In Progress`, `Blocked`, `In Review`, `Done`.
- Clarify that `Blocked` is a returnable interruption state with mandatory blocker reason.
- Clarify that humans approve plan artifacts in `Plan Review`.
- Clarify that no significant architecture change proceeds without ADR linkage.

## Non-Negotiable Controls in the Merged Document

- No agent acts outside its entry-state rules.
- No state transition without required evidence.
- No merge to `Done` without CI pass and review verdict.
- No architectural decision closure without ADR reference.
- No parallel agent ownership on the same ticket.

## Deliverables

1. [proposal-analysis.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/proposal-analysis.md): comparison and strongest-idea extraction.
1. [merge-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/merge-proposal.md): merge design and policy choices.
1. [merged.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/merged.md): final unified team proposal.

## ADR Triggers for Implementation

The merged proposal should explicitly flag these ADR decisions as required before build-out:

1. Director runtime mode: polling, webhook, or hybrid.
1. Agent authentication and secret management model.
1. Coordinator downstream-promotion trigger design.
1. Maximum Graphite stack depth and splitting policy.
1. Incident severity levels and escalation ownership.

## Acceptance Criteria for the Merged Document

- Complete lifecycle coverage from intake through done.
- Every role has clear boundaries and handoff contracts.
- Every transition has an enforceable gate.
- Observability and recovery are operationally actionable.
- Terminology is internally consistent and matches Linear workflow names.
