# MVP Proposal Comparison: Claude vs Codex vs Gemini

Three AI agents were given the same prompt: reduce the full agentic execution architecture to an MVP a single human could build in a few days, running locally in Docker. This document compares their proposals across key dimensions.

---

## Identity and Framing

| | Claude | Codex | Gemini |
|---|---|---|---|
| Name | Local Docker Agentic Execution | Local Docker Agent Runner | Speckit Local Docker Runner (SLDR) |
| Primary framing | Prove the pipeline end-to-end | Prove the core execution loop | Extend the existing speckit tooling |

The framing differences are significant. Claude and Codex both start from the full architecture and strip it back. Gemini starts from the existing `speckit` toolset and wraps a Docker runner around it. This makes Gemini's proposal the most opinionated about continuity with existing tooling, and Codex's the most disciplined about deferring anything not strictly necessary to prove the hypothesis.

---

## State Persistence

| | Claude | Codex | Gemini |
|---|---|---|---|
| Backend | SQLite | SQLite | None — Git + filesystem |
| Schema | 1 table: `runs` | 3 tables: `runs`, `artifacts`, `events` | No schema |

Codex's three-table schema adds an `events` table (run ID, timestamp, event, message) and an `artifacts` table, which together provide a lightweight audit trail and explicit artifact tracking without any additional infrastructure. Claude uses a single `runs` table, which is simpler but loses the audit trail. Gemini eliminates the database entirely, treating the Git repository and local filesystem as the only source of truth — the most minimal stance, but it also means no queryable run history.

---

## Manifest Delivery

| | Claude | Codex | Gemini |
|---|---|---|---|
| Mechanism | Environment variables at `docker run` | Written to disk, mounted read-only into container | Not explicitly addressed |
| Readiness handshake | Dropped | Dropped | N/A |

Claude and Codex agree on dropping the authenticated readiness handshake from the full architecture. They differ on how the manifest reaches the agent: Claude uses environment variables (simpler, but credentials also travel the same way); Codex writes a `manifest.json` to a per-run directory before container start and mounts it read-only (marginally closer to the full architecture's principle of keeping the manifest immutable and separate from secrets). Gemini does not explicitly address this question.

---

## GitHub Integration

| | Claude | Codex | Gemini |
|---|---|---|---|
| Stance | Core — Day 3 feature | Deferred — explicit Non-Goal; optional Day 4 | Manual — human runs `gh`/`gt` on host |
| What it does | Issue label update on completion, failure comment | Optional write-back at Day 4 | Human opens PR via host CLIs after container exits |

This is the sharpest disagreement between the three proposals. Claude treats GitHub integration as a required part of the MVP, completing the loop automatically. Codex explicitly lists "GitHub issue synchronization or PR automation as a required subsystem" as a Non-Goal and frames it as an optional Day 4 addition only if needed. Gemini delegates it entirely to the human operator, with an explicit approval gate before the PR step.

Codex's rationale is the most carefully stated: if GitHub automation turns out to be necessary during MVP implementation, that is evidence the MVP scope was wrong, not a reason to add it.

---

## Concurrency Model

| | Claude | Codex | Gemini |
|---|---|---|---|
| Model | Threading semaphore, MAX = 3 | Sequential — "maybe one run at a time" | Sequential (implied) |

Claude is the only proposal that addresses concurrency at all. It introduces a semaphore capping concurrent containers at 3. Codex and Gemini both treat sequential execution as sufficient for an MVP, which is consistent with their goal of proving the loop before worrying about throughput.

---

## Networking

| | Claude | Codex | Gemini |
|---|---|---|---|
| Policy | Not specified | Not specified | `--network none` for implementation tasks |

Gemini is the only proposal that specifies a network policy, and it takes the most restrictive stance: deny all networking for implementation runs, allow restricted access only for "research" phases. Claude and Codex leave network configuration unaddressed — a gap, since unrestricted egress is a meaningful security difference from the full architecture's deny-all baseline.

---

## Validation and Admission

| | Claude | Codex | Gemini |
|---|---|---|---|
| Approach | Inline checks: GitHub Issue `status:ready`, planning artifact existence | Basic input validation: repo path, commit SHA, task ID | Task parser reads `tasks.md`, identifies dependencies |

Claude does the most admission work, checking actual GitHub Issue state and verifying planning artifact presence before launching — a subset of the full architecture's Policy Service. Codex validates only that the inputs are structurally valid before launching, deliberately deferring business-logic checks. Gemini parses `tasks.md` to understand task dependencies, which is unique to its proposal and most relevant to multi-step sequencing.

---

## Scope of Automation by End of Day 3

| | Claude | Codex | Gemini |
|---|---|---|---|
| Day 3 outcome | GitHub integration + watchdog timeout | Demo task, error handling, happy-path test | Full feature lifecycle: Specify → Plan → Implement → PR |

Gemini is the most ambitious about end-to-end completeness by Day 3, targeting a full feature cycle including PR submission. Claude targets automated GitHub feedback but not the full cycle. Codex targets a working, well-tested core execution loop with no automation beyond the container run itself.

---

## What Each Proposal Uniquely Contributes

**Claude**
- Concurrency semaphore (only proposal to address parallel runs)
- Modular directory structure (`db.py`, `runner.py`, `validator.py`, `github.py`)
- Watchdog thread for timeout enforcement
- Explicit SQLite schema with `CREATE TABLE` DDL

**Codex**
- Explicit acceptance criteria (6 testable conditions the MVP must satisfy)
- `events` table providing a lightweight append-only audit trail
- Explicit risks and trade-offs section
- Recommendation to write an ADR before implementation begins
- Clearest statement of what remains testable vs. what is deferred

**Gemini**
- Golden Image concept — a single pre-built Docker image containing all agent CLIs, language runtimes, and speckit scripts
- `--network none` default — only proposal to address network isolation
- Human approval gate between tasks — preserves operator oversight in the loop
- Tightest integration with existing speckit tooling
- Lightest state model — no database required

---

## Philosophical Differences

**Codex** is the most conservative. Its explicit Non-Goals list is longer than the other two proposals combined. It frames the MVP as a learning device — the output is not a mini-system but answers to five specific questions about the architecture. It is the only proposal to recommend capturing decisions in an ADR before writing code.

**Gemini** is the most pragmatic about continuity. Rather than building a new orchestration layer, it wraps Docker around the tools that already exist. The tradeoff is less automation and more reliance on the human operator to complete the loop.

**Claude** makes the strongest assumptions about which parts of the full architecture should survive into the MVP. It keeps GitHub integration, concurrency, validation against live GitHub Issue state, and a modular codebase structure. This produces the most complete automated pipeline but also the most scope for a few-day build.

---

## Synthesis

A combined approach would take:

- **Codex's scope discipline and acceptance criteria** — don't build GitHub integration until the core loop is proven; define done before writing code
- **Codex's three-table SQLite schema** — the `events` table costs almost nothing to add and provides audit capability that will be needed the moment the first run fails unexpectedly
- **Gemini's `--network none` default** — the full architecture's deny-all egress baseline should be approximated from day one, not retrofitted
- **Gemini's Golden Image concept** — a single pre-built image with all CLIs reduces container startup variability and simplifies Day 1
- **Claude's manifest-on-disk approach** (from Codex) combined with **Claude's modular code structure** — separate files for DB, runner, and validation keeps the codebase navigable as it grows
- **Claude's concurrency semaphore** — worth adding on Day 2 since it is a single line of code and prevents the most obvious failure mode if two runs are submitted in quick succession
