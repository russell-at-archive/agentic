# MVP Proposal: Local Docker Agentic Execution

## Goal

Prove the core loop on a single developer machine: given a task ID, launch an isolated Docker container running an AI agent, have it execute the task autonomously following the implementation process, produce a PR, and report the result.

---

## What Is Cut

Every component whose purpose is scale, multi-tenancy, audit compliance, or operational resilience is dropped.

| Full Architecture Component | MVP Disposition |
|---|---|
| Kubernetes + Worker Controller operator | Replaced by `docker run` |
| KEDA autoscaling | Replaced by a fixed concurrency semaphore |
| Work Queue (4 priority lanes) | Replaced by an in-memory queue or sequential execution |
| Event Bus + Dead Letter Queue | Replaced by direct function calls |
| Policy Service | Inlined as 3 sequential checks |
| Spec Resolver as a separate service | Inlined as local file reads |
| GitHub Integration Service | Direct GitHub API calls from the orchestrator |
| Tool Gateway | Dropped — agent calls tools directly |
| Distributed traces (Tempo) | Dropped |
| Metrics store (Prometheus + Thanos) | Dropped |
| Search index | Dropped |
| Log store (Loki) | Local log file per run under `runs/<id>/execution.jsonl` |
| Artifact store (S3) | Local filesystem under `runs/<id>/output/` |
| Multiple execution classes | Single class |
| gVisor secure runtime | Dropped — standard Docker isolation |
| Projected Kubernetes secret volumes | Environment variables passed at `docker run` |
| Checkpoint / resumable execution | Dropped — failed runs are full reruns |
| Multiple orchestrator instances + optimistic locking | Single process |
| Namespace topology | Single machine |
| PostgreSQL with append-only schema | SQLite |

---

## MVP Architecture

```text
┌──────────────────────────────────────┐
│  CLI  (archive-run submit <task-id>) │
└──────────────────┬───────────────────┘
                   │
┌──────────────────▼───────────────────┐
│  Orchestrator (single Python process) │
│                                       │
│  1. Validate GitHub Issue status      │
│  2. Check spec.md / plan.md /         │
│     tasks.md exist at commit SHA      │
│  3. Write run record to SQLite        │
│  4. Acquire concurrency semaphore     │
│     (MAX_CONCURRENT_RUNS = 3)         │
│  5. docker run agent image            │
│  6. Tail container logs to            │
│     runs/<id>/execution.jsonl         │
│  7. On exit: read output/manifest.json│
│  8. Update SQLite run record          │
│  9. Update GitHub Issue label via API │
└──────────────────┬───────────────────┘
                   │ docker run
┌──────────────────▼───────────────────┐
│  Agent Container (one per run)        │
│                                       │
│  ENV: RUN_ID, TASK_ID, COMMIT_SHA,    │
│       GITHUB_TOKEN, MODEL_API_KEY     │
│                                       │
│  1. git clone repo at COMMIT_SHA      │
│  2. Read manifest from ENV            │
│  3. Read spec.md / plan.md /          │
│     tasks.md from /workspace/repo/    │
│  4. Execute task (Claude CLI /        │
│     Codex CLI):                       │
│     → create branch t-<##>-<slug>     │
│     → TDD cycle per acceptance crit.  │
│     → commit, push, open PR           │
│  5. Write output/manifest.json        │
│  6. Exit 0 (success) or non-zero      │
└───────────────────────────────────────┘
```

---

## Directory Layout

```text
archive-agentic/
├── orchestrator/
│   ├── main.py           # CLI entry point
│   ├── db.py             # SQLite run records
│   ├── runner.py         # docker run + log tail
│   ├── validator.py      # inline policy + spec checks
│   └── github.py         # Issue label updates
├── agent/
│   ├── Dockerfile
│   └── entrypoint.sh     # clone → run CLI → write manifest
└── runs/                 # created at runtime
    └── <run-id>/
        ├── execution.jsonl
        └── output/
            └── manifest.json
```

---

## Run Record Schema (SQLite)

```sql
CREATE TABLE runs (
  id          TEXT PRIMARY KEY,
  task_id     TEXT NOT NULL,
  commit_sha  TEXT NOT NULL,
  status      TEXT NOT NULL,  -- queued | launching | running | done | failed
  created_at  TEXT NOT NULL,
  started_at  TEXT,
  finished_at TEXT,
  exit_code   INTEGER
);
```

---

## Concurrency

A threading semaphore caps concurrent containers:

```python
MAX_CONCURRENT_RUNS = 3
semaphore = threading.Semaphore(MAX_CONCURRENT_RUNS)
```

Submissions beyond the limit block until a slot opens. No queue infrastructure required.

---

## Manifest (Environment Variables)

The full architecture's authenticated readiness handshake is replaced by environment variables injected at container start:

```bash
docker run \
  -e RUN_ID=run_abc123 \
  -e TASK_ID=T-07 \
  -e COMMIT_SHA=abc123def \
  -e GITHUB_TOKEN=... \
  -e MODEL_API_KEY=... \
  -v "$(pwd)/runs/run_abc123:/workspace/output" \
  archive-agent:latest
```

---

## GitHub Integration

On run completion the orchestrator makes two direct API calls:

| Outcome | Action |
|---|---|
| Exit 0 | Issue label → `status:in-review` |
| Non-zero exit | Post comment with exit code + last 20 log lines, label → `status:blocked` |

---

## Timeout

Container wall-clock timeout enforced via `docker run --stop-timeout` and a watchdog thread that calls `docker stop <id>` after the configured limit (default 2 hours). No heartbeat mechanism required.

---

## Build Plan (3 Days)

**Day 1 — Core execution loop**

- `agent/Dockerfile`: base image with git, Claude CLI, language runtimes
- `agent/entrypoint.sh`: clone repo, run CLI, write `manifest.json`
- `orchestrator/runner.py`: `docker run`, stream logs to file, capture exit code
- Smoke test: manually submit a task, verify PR opens

**Day 2 — State and validation**

- `orchestrator/db.py`: SQLite schema, `create_run`, `update_run`, `list_runs`
- `orchestrator/validator.py`: check GitHub Issue `status:ready`, verify planning artifacts exist at commit SHA
- `orchestrator/main.py`: `archive-run submit`, `archive-run status`, `archive-run list`

**Day 3 — GitHub integration and polish**

- `orchestrator/github.py`: Issue label update on completion, failure comment
- Concurrency semaphore wired into `runner.py`
- Watchdog timeout thread
- Basic error output on validation failure

---

## Accepted Limitations

- No isolation between runs sharing the host beyond standard Docker
- No audit trail of individual tool calls
- No retry logic — failed runs require manual resubmission
- Credentials in environment variables
- Single machine capacity ceiling
- A hung container must be manually killed if the watchdog thread fails
- No observability beyond local log files

Each limitation maps directly to a named component in the full architecture and can be addressed incrementally when the core loop is validated.
