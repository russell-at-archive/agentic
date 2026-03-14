# Analysis of the Three MVP Proposals

## Executive Summary

All three proposals agree on the main architectural reduction: the current
design is too large for a single-person MVP and should be collapsed to local
execution of Docker-isolated agents on one developer machine.

They differ on what the MVP is supposed to prove.

- [docs/claude/mvp-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/claude/mvp-proposal.md)
  treats the MVP as a small but end-to-end autonomous delivery system, including
  GitHub issue updates, PR creation, validation checks, and limited concurrency.
- [docs/codex/mvp-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/codex/mvp-proposal.md)
  treats the MVP as an execution-substrate test: can a local orchestrator launch
  a containerized agent, persist state, capture logs, and manage the run
  lifecycle reliably.
- [docs/gemini/mvp-proposal.md](/Users/russelltsherman/src/github.com/archiveresale/archive-agentic/docs/gemini/mvp-proposal.md)
  treats the MVP as a local developer workflow wrapper around existing Speckit
  artifacts and host-side Git/GitHub tooling.

The proposals converge strongly on infrastructure direction and diverge mainly
on workflow automation scope. The clearest recommendation is to use the Codex
proposal as the baseline, borrow Gemini's local hardening defaults, and defer
Claude's GitHub automation and concurrency features until the core execution
loop works.

## Areas of Agreement

All three documents make the same primary cuts to the original architecture.

- Execution moves from Kubernetes to local Docker containers.
- The distributed control plane is replaced by one local CLI or orchestrator
  process.
- Logs and artifacts move from cloud services to the local filesystem.
- The MVP is intentionally small enough to build in roughly three days.
- Most scale-oriented systems are removed: queues, event buses, autoscaling,
  search, distributed telemetry, and multi-tenant controls.
- The first version runs sequentially or with only minimal concurrency.
- The goal is to validate the execution workflow before investing in platform
  infrastructure.

In practical terms, all three proposals agree that the important thing to prove
first is not distributed orchestration, but whether an isolated agent can run a
task locally against real repository inputs and produce inspectable outputs.

## Key Differences

### Persistence Model

The Claude and Codex proposals both introduce SQLite, while Gemini avoids a
database entirely.

- Claude stores run records in SQLite and keeps logs and artifacts under a local
  `runs/<id>/` directory.
- Codex also uses SQLite, but defines a slightly more complete local model with
  `runs`, `artifacts`, and `events` tables, which gives it a clearer path to
  status inspection and future upgrades.
- Gemini uses the Git repository and filesystem as the source of truth. That is
  lighter, but it leaves run state less explicit and makes later inspection or
  cancellation semantics harder to formalize.

### Scope of Automation

This is the largest difference between the documents.

- Claude includes automated GitHub interactions in the MVP. The orchestrator
  validates issue status, updates labels, and expects the agent flow to create a
  branch, push commits, and open a PR.
- Codex explicitly avoids GitHub issue synchronization and PR automation as
  required MVP subsystems. Its focus stays on local execution, state, logs, and
  artifacts.
- Gemini keeps more of the workflow on the host and with the human operator.
  The container does task execution, but host-side tools handle review and PR
  submission.

Claude is therefore the most workflow-complete proposal, Codex the most scope
disciplined, and Gemini the most operator-driven.

### Run Model

The three proposals imply different operating models.

- Claude supports bounded parallelism with a semaphore and accepts a small
  amount of queue-like behavior inside the local orchestrator.
- Codex leaves concurrency intentionally minimal and treats one-at-a-time or
  near-sequential execution as the default.
- Gemini is effectively sequential and CLI-driven.

If the bar is "a single human can build this in a few days," Claude is pushing
closest to over-scope because concurrency adds lifecycle and failure complexity
without proving the core product hypothesis.

### Manifest and Runtime Handoff

The proposals also differ in how they pass execution context to the container.

- Claude replaces the full architecture's manifest handshake with environment
  variables.
- Codex recommends a mounted read-only `manifest.json`, which is simpler to
  inspect and closer to the original architecture's notion of an explicit
  implementation manifest.
- Gemini is less explicit here; it focuses more on container launch
  configuration and mounted repo state than on a formal manifest contract.

Codex has the strongest interface definition at this boundary.

### What the MVP Is Trying to Prove

Each proposal optimizes for a different validation target.

- Claude aims to prove an end-to-end autonomous software delivery loop on one
  machine.
- Codex aims to prove that the execution substrate itself is viable.
- Gemini aims to prove that the existing repository planning workflow can be
  wrapped in a reusable local Docker runner.

That distinction matters because it changes what counts as essential.
GitHub automation is essential in Claude's framing, optional in Gemini's, and
out of scope in Codex's.

### Security and Isolation Posture

All three rely on ordinary local Docker isolation, but Gemini is the most
intentional about hardening.

- Claude uses standard Docker isolation and passes secrets through environment
  variables.
- Codex uses standard Docker isolation and explicitly names stronger sandboxing
  as a non-goal for the MVP.
- Gemini adds the strongest local isolation defaults: read-only base mounts,
  restricted networking, dropped capabilities, and host/container separation as
  a first-order design concern.

Gemini contributes the best local-sandbox instincts, even though its broader
proposal is less explicit about persistence and lifecycle tracking.

## Strengths and Weaknesses

### Claude Proposal

The Claude proposal is strongest if the real question is whether the system can
execute an entire autonomous implementation loop, including validation,
container execution, issue updates, and PR creation. It is also the most
concrete about operator commands, runtime layout, and a three-day build plan.

Its weakness is scope. Direct GitHub integration, validation logic, concurrency
control, and PR-oriented completion criteria all add moving parts that are not
strictly necessary to validate the execution substrate.

### Codex Proposal

The Codex proposal is strongest on feasibility and scope control. It preserves
only the parts most likely to survive into a later architecture: local
orchestration, explicit manifest handoff, durable run state, cancellation,
timeouts, logs, and artifacts.

Its weakness is that it proves less about the full autonomous development loop.
If the intended milestone is "agent can open a PR from a task," Codex stops one
step short by design.

### Gemini Proposal

The Gemini proposal is strongest when the repository's existing Speckit or
spec-driven workflow is the anchor and the goal is to wrap that workflow in a
safe local runner with minimal new infrastructure. It also has the best local
container hardening language of the three.

Its weakness is that it is less general as an architecture proposal. It assumes
specific repository conventions, keeps more steps manual, and does not define
run-state persistence as clearly as the SQLite-based proposals.

## Recommended Synthesis

The best combined MVP is:

- the Codex proposal's architecture as the baseline
- the Gemini proposal's local hardening defaults
- none of the Claude proposal's GitHub automation or concurrency requirements in
  v1

That means the MVP should consist of:

- a local CLI with `run`, `status`, `logs`, and `cancel`
- a single local orchestrator process
- one Docker container per run
- SQLite as the system of record
- local filesystem artifact and log storage under a predictable run directory
- a mounted read-only `manifest.json`
- single-worker execution by default

It should also adopt a few Gemini-style safety defaults where practical:

- disable container networking by default unless a task explicitly needs it
- prefer mounted secret files or env files over scattering secrets across many
  direct environment variables
- use least-privilege Docker flags where they do not complicate the MVP

The MVP should not include, in its first version:

- required GitHub issue synchronization
- automatic PR creation
- dependency scheduling
- queue semantics
- multi-run concurrency
- filesystem-as-state instead of explicit run tracking

## Conclusion

The three proposals are not in conflict on the main architectural direction.
They all reduce the original platform design to local Docker execution. Their
real disagreement is about ambition.

Claude proposes a local autonomous workflow product.
Codex proposes a local execution substrate.
Gemini proposes a local wrapper around existing planning workflows.

For a single-human, few-day MVP, the execution-substrate framing is the safest
and most defensible starting point. The most practical path is therefore:

1. Start with the Codex shape.
2. Add Gemini's security-minded container defaults.
3. Reintroduce Claude's workflow automation only after the local runner is
   reliable.
