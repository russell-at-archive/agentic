# Agent Team Proposal for Autonomous Software Delivery

## Purpose

Define a production-ready operating model for a multi-agent software development team that plans, schedules, implements, reviews, and reports work with Linear as the system of record, GitHub as source control, and Graphite for stacked pull requests.

## Scope

- In scope: role definitions, handoffs, workflow states, tool contracts, quality gates, and rollout plan.
- In scope: proposal-level architecture and operating rules.
- Out of scope: full implementation details for each CLI integration.

## Baseline Input

This proposal extends [docs/design.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/design.md), which provides the initial role and workflow outline.

## Gap Analysis of Current Draft

## Gap 1: Missing Role Contracts

The current draft names roles but does not define strict inputs, outputs, preconditions, and failure handling.

Impact:

- Roles can overlap or conflict.
- Retries and escalation paths are undefined.
- Tool access becomes inconsistent across roles.

## Gap 2: Missing Workflow State Machine Rules

Linear states are listed, but allowed transitions and transition owners are not defined.

Impact:

- Tickets can jump states without required artifacts.
- Automation cannot reliably enforce process gates.

## Gap 3: No Artifact Standard

No explicit template or schema exists for planning docs, task specs, review reports, or research outputs.

Impact:

- Handoffs are lossy.
- Review quality depends on individual behavior.

## Gap 4: No ADR Control Points for Significant Decisions

The draft does not specify when an ADR is mandatory before progression.

Impact:

- Architectural decisions risk being finalized without durable rationale.

## Gap 5: No Concurrency and Locking Model

The draft does not define how many agents can work on a ticket or branch set simultaneously.

Impact:

- PR collisions, branch conflicts, and duplicate work.

## Gap 6: No Operational SLOs or Metrics

Success criteria are not measurable.

Impact:

- Team cannot tune throughput, review latency, or defect escape rates.

## Gap 7: No Incident and Recovery Procedures

No policy exists for failed runs, partially-created Linear tickets, or broken stacked PR chains.

Impact:

- Operations become manual and inconsistent during failures.

## Proposed Team Architecture

## Core Roles

1. Director
   - Mission: intake, prioritization, orchestration, and policy enforcement.
   - Owns: polling cycle, queue selection, agent dispatch, run logs, escalation.
2. Architect
   - Mission: transform requests into executable plans.
   - Owns: feature spec, ADR creation or linkage, task decomposition, dependency map.
3. Coordinator
   - Mission: convert approved plans into scheduled, dependency-safe Linear tickets.
   - Owns: ticket creation, parent-child links, state transitions into executable queues.
4. Engineer
   - Mission: implement one scoped task per workstream with deterministic outputs.
   - Owns: worktree, code changes, tests, stacked PR creation, ticket progress updates.
5. Technical Lead
   - Mission: enforce quality and merge readiness.
   - Owns: review findings, risk classification, approval or change-request decisions.
6. Explorer
   - Mission: produce source-backed research to reduce uncertainty.
   - Owns: question framing, source citation quality, recommendation memo.

## Cross-Cutting Control Agents

1. Compliance Gate
   - Validates required artifacts before any state transition.
2. Metrics Reporter
   - Publishes cycle-time, lead-time, and defect metrics per ticket and per role.

## Role Contracts

## Director Contract

- Inputs: new or updated Linear tickets in `Draft`, `Planning`, `Selected`, `Blocked`.
- Preconditions: valid project/team mapping and run policy config.
- Outputs: dispatch record, assigned agent run, state transition intent.
- Failure policy: retry transient errors up to configured limit, then mark `Blocked` with cause.

## Architect Contract

- Inputs: ticket context and product intent.
- Preconditions: state is `Planning`.
- Outputs: plan doc, task specs, ADR links or new ADRs when required.
- Exit criteria: plan accepted and ticket moved to `Plan Review` then `Backlog`.

## Coordinator Contract

- Inputs: accepted plan bundle.
- Preconditions: ticket in `Selected` and plan accepted.
- Outputs: implementation tickets with dependencies and estimates.
- Exit criteria: child tickets ready in `Backlog` or `Selected` based on capacity rules.

## Engineer Contract

- Inputs: implementation ticket and dependency completion checks.
- Preconditions: ticket in `Selected` and dependencies resolved.
- Outputs: code, tests, stacked PR chain, implementation notes.
- Exit criteria: ticket moved to `In Review` with all links attached.

## Technical Lead Contract

- Inputs: PR chain and implementation notes.
- Preconditions: ticket in `In Review`.
- Outputs: review decision, blocking findings, approval notes.
- Exit criteria: ticket moved to `Done` or returned to `In Progress` with required fixes.

## Explorer Contract

- Inputs: research question and scope constraints.
- Preconditions: explicit request from another role.
- Outputs: citation-backed report with recommendation and confidence level.
- Exit criteria: accepted by requester and linked to ticket.

## Linear State Machine Proposal

Allowed transitions:

- `Draft` -> `Planning` by Director.
- `Planning` -> `Plan Review` by Architect.
- `Plan Review` -> `Backlog` by Director or product owner.
- `Backlog` -> `Selected` by Director based on capacity.
- `Selected` -> `In Progress` by Engineer at start.
- `In Progress` -> `In Review` by Engineer on PR submission.
- `In Review` -> `Done` by Technical Lead on approval and merge.
- `In Review` -> `In Progress` by Technical Lead when changes required.
- Any active state -> `Blocked` by any role with required blocker reason.
- `Blocked` -> prior active state by Director after unblock validation.

Transition gates:

- `Planning` cannot exit without plan artifact link.
- `Plan Review` cannot exit without acceptance decision.
- `Selected` cannot start without dependency check pass.
- `In Review` cannot complete without test evidence and reviewer sign-off.

## Artifact Standards

Required artifacts per phase:

1. Planning bundle
   - Feature spec
   - ADR references or newly created ADRs
   - Task decomposition compatible with stacked PR flow
2. Scheduling bundle
   - Ticket tree with dependency links
   - Estimates and ownership
3. Implementation bundle
   - Branch/worktree metadata
   - PR stack links
   - Test and validation results
4. Review bundle
   - Finding list by severity
   - Decision log and merge readiness
5. Research bundle
   - Question, method, sources, recommendation, confidence

## Tooling and Execution Policy

- Linear is the source of truth for status and assignment.
- GitHub is the source of truth for code and CI status.
- Graphite is mandatory for branch and stacked PR management.
- Speckit is mandatory for new feature planning.
- ADRs in `docs/adr/` are mandatory for significant architecture choices.

Access boundaries:

- Architect and Technical Lead can approve architecture-affecting changes.
- Engineer cannot merge when required ADR linkage is missing.
- Director can pause all dispatch for incident containment.

## Concurrency Model

- One Engineer per ticket.
- One active PR stack per ticket.
- Multiple Explorer tasks may run in parallel if scopes are disjoint.
- Coordinator cannot schedule a ticket whose dependencies are unresolved.

Locking rules:

- Ticket lock acquired on `Selected` -> `In Progress`.
- Branch namespace lock acquired on first PR in stack.
- Locks released on `Done`, cancellation, or explicit Director recovery action.

## Quality Gates and Definition of Done

A ticket reaches `Done` only when all checks pass:

- All acceptance criteria are satisfied.
- Required tests pass in CI.
- No unresolved blocking review findings.
- Required documentation updates are merged.
- Required ADR references are present for architecture-significant changes.

## Failure Handling and Recovery

- Transient API failures: exponential backoff with bounded retries.
- Stale locks: Director can run lock-reconciliation and clear orphaned locks.
- Broken PR stack: Engineer runs stack repair workflow and revalidates dependencies.
- Invalid state transition: reject transition, attach reason, and notify owner.

## Observability and Metrics

Track at minimum:

- Lead time from `Selected` to `Done`.
- Review latency from `In Review` to decision.
- Reopen rate from `In Review` -> `In Progress`.
- Defect escape rate after `Done`.
- Agent failure rate and retry counts.

Reporting cadence:

- Daily operational dashboard.
- Weekly quality and throughput review.

## ADR Backlog Required for This Proposal

Before implementation, create ADRs for:

1. Orchestration ownership model and dispatch policy.
2. Linear state machine and transition authority.
3. Required artifacts and quality gate schema.
4. Concurrency and locking semantics.
5. Failure recovery and incident policy.

Reference existing policy ADR:

- [docs/adr/0001-adopt-architecture-decision-records.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/adr/0001-adopt-architecture-decision-records.md)

## Phased Rollout Plan

1. Phase 1: governance and artifacts
   - Finalize role contracts, state machine, and templates.
2. Phase 2: scheduling and planning automation
   - Implement Director, Architect, and Coordinator flows.
3. Phase 3: engineering and review automation
   - Implement Engineer and Technical Lead flows with Graphite integration.
4. Phase 4: resilience and optimization
   - Add lock reconciliation, incident handling, and metrics tuning.

## Open Questions

- Which role has final authority for plan acceptance in `Plan Review`?
- Should `Blocked` be represented as a separate workflow lane or an overlay status?
- What is the maximum allowed PR stack depth before forced split?
- Which CI signals are mandatory versus advisory for `Done`?

## Recommended Next Step

Review and approve this proposal as the target operating model, then create the ADR backlog listed above before building role-specific automation.
