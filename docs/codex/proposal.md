# Symphony MVP Proposal

## Goal

Deliver a usable Symphony MVP in 5 working days that can:

- poll Linear for eligible issues
- create and reuse per-issue workspaces
- run a Codex session against one issue at a time
- retry failed runs with simple backoff
- stop or skip work when issue state is no longer eligible
- emit enough structured logs to debug runs

This plan targets an MVP, not full conformance to the current
`symphony.md` specification. The specification describes a broader v1
platform. A 5-day MVP should focus on the smallest end-to-end slice that
proves the orchestration model works with real tickets.

## Spec Review Summary

The specification is coherent, but it is much larger than a 5-day build.
The biggest schedule drivers are:

- Docker-based isolation for every run attempt
- dynamic `WORKFLOW.md` reload and reconfiguration
- multi-turn live session continuation on the same thread
- full reconciliation and retry semantics
- optional HTTP/status surfaces
- production-grade validation and conformance coverage

If the team tries to implement all of that in 5 days, the likely outcome
is a partially working orchestrator with weak operational confidence.

The correct MVP cut is to keep the core control loop and remove the
platform-hardening features that do not change the core product proof:
"Can Symphony reliably pick a ticket, create an isolated workspace
directory, run Codex with repo-owned workflow instructions, and produce an
observable outcome?"

## Recommended MVP Scope

### In Scope

- single-process local orchestrator
- Linear-only issue ingestion
- `WORKFLOW.md` loader with YAML front matter parsing
- typed config for only the fields needed by the MVP
- fixed poll loop
- bounded global concurrency, defaulting to `1`
- per-issue workspace creation and reuse
- `after_create` and `before_run` hooks only
- Codex app-server launch from the workspace directory
- single turn per dispatch attempt
- simple reconciliation against current issue state on each poll
- exponential retry for failures
- startup cleanup for terminal issue workspaces
- structured JSON logs
- CLI entrypoint for local operation

### Explicitly Deferred

- Docker isolation
- live reload or file watching for `WORKFLOW.md`
- optional HTTP server
- terminal dashboard or other status UI
- client-side dynamic tools such as `linear_graphql`
- per-state concurrency limits
- multi-host or SSH execution
- multiple continuation turns on the same live thread
- full protocol compatibility coverage across app-server variants
- production conformance test matrix

## Architectural Position

The MVP should adopt a simple internal shape:

1. `workflow`
   Loads and validates `WORKFLOW.md`.
1. `config`
   Produces typed runtime config with defaults and env resolution.
1. `linear`
   Fetches candidate issues, issue states, and terminal issues.
1. `workspace`
   Creates, names, validates, and cleans workspace directories.
1. `runner`
   Renders the prompt and executes one Codex run in the workspace.
1. `orchestrator`
   Owns polling, claims, retries, and reconciliation.
1. `cli`
   Starts the service and wires logging and shutdown.

That is enough separation to avoid a rewrite later, but still small enough
to implement quickly.

## ADR Requirement

Per repository policy, the architectural choices below should be captured
before implementation starts:

- ADR: MVP implementation language and runtime
- ADR: MVP trust model and execution isolation posture
- ADR: MVP Codex integration mode and approval policy

Without those ADRs, the team risks making significant architectural
decisions implicitly during the build.

## 5-Day Delivery Plan

### Day 1: Decide the Slice and Stand Up the Skeleton

Deliverables:

- ADRs for language/runtime, trust posture, and Codex integration
- repository scaffold for the service
- config loader for `WORKFLOW.md`
- logging setup
- CLI entrypoint that validates config and exits cleanly

Notes:

- Keep runtime configuration narrow. Do not model every field in the spec.
- Choose a language with fast iteration and strong subprocess/HTTP support.
  TypeScript on Node.js is the fastest likely path unless the team already
  has a different strong preference.

### Day 2: Linear Client and Workspace Manager

Deliverables:

- Linear adapter for:
  - fetch candidate issues
  - fetch issue states by ID
  - fetch terminal issues
- normalized issue model
- workspace path sanitization and boundary validation
- startup cleanup of terminal issue workspaces
- `after_create` hook execution

Success condition:

- The CLI can poll Linear and create or reuse a workspace for a selected
  issue without launching Codex yet.

### Day 3: Codex Runner End to End

Deliverables:

- prompt renderer using issue data plus workflow body
- `before_run` hook execution
- Codex app-server launch in the issue workspace
- basic protocol handshake
- single-turn execution path
- structured event logging for start, completion, failure, and timeout

Success condition:

- One real Linear issue can be executed end to end in a local workspace and
  produce a visible run result.

### Day 4: Orchestrator Control Loop

Deliverables:

- poll loop with bounded concurrency
- claim tracking
- failure retry queue with exponential backoff
- reconciliation that stops or releases work when issue state changes
- graceful shutdown handling

Success condition:

- The service can run continuously, avoid duplicate dispatch, and recover
  from normal transient failures.

### Day 5: Hardening, Manual Validation, and Documentation

Deliverables:

- error-path cleanup
- startup and runtime validation polish
- concise operator runbook
- known limitations list
- smoke tests for config loading, workspace safety, and retry scheduling
- one manual real-world validation run against a test Linear project

Success condition:

- Another engineer can start the service locally, watch it process a test
  ticket, and understand the limits of the MVP.

## MVP Acceptance Criteria

The 5-day MVP is successful if all of the following are true:

- Symphony can load a repo-owned `WORKFLOW.md`.
- Symphony can poll a configured Linear project for active issues.
- Symphony can create one workspace per issue under a configured root.
- Symphony runs Codex from the workspace directory, not the repo root.
- Symphony does not dispatch the same issue twice concurrently.
- Symphony retries a failed issue automatically with capped backoff.
- Symphony stops or skips work for non-active or terminal issues.
- Symphony produces structured logs with issue and run identifiers.
- Symphony can be started and stopped cleanly from the CLI.

## Risks

### Highest Risks

- Codex app-server protocol details may take longer than expected if the
  installed version differs from the spec assumptions.
- Linear query shape and pagination details can burn time if not tested on
  day 2.
- Long-running worker cancellation is easy to get mostly right and hard to
  get fully correct.

### Mitigations

- Validate the Codex handshake on day 1 or early day 3 with a minimal smoke
  script.
- Use one real Linear project during development instead of waiting for
  final integration.
- Keep concurrency at `1` for the first working version and only raise it
  after the retry and claim paths are stable.

## What Not to Do in the MVP

- Do not implement Docker isolation in parallel with the core runner.
- Do not build the optional HTTP server.
- Do not attempt full spec conformance or the full Section 18 checklist.
- Do not add tracker write operations unless they are required for the first
  operator workflow.

## Recommended Next Step After the MVP

After the 5-day MVP proves the orchestration loop, the next milestone should
be "safe multi-runner operation." That milestone should add Docker isolation,
live workflow reload, better cancellation semantics, and stronger
conformance coverage.
