# MVP Proposal: Local Docker Agent Runner

## Goal

Prove the core execution loop on a single developer machine before building
platform infrastructure. Given an approved task, launch an isolated Docker
container running an AI agent, have it execute the task autonomously against
the repository, capture what it did, and make the result inspectable.

The MVP should answer these questions before any distributed infrastructure
is considered:

- Can an agent run reliably against repository planning artifacts?
- What minimal manifest is actually needed?
- What logs and outputs are useful for operators?
- What parts of the lifecycle need automation versus manual control?
- Where do failures actually happen in practice?

---

## Non-Goals

The following are explicitly out of scope for the first pass. If any become
necessary during implementation, that is evidence the MVP scope is wrong,
not a reason to expand it.

- Kubernetes, remote schedulers, or cloud infrastructure of any kind
- Priority queues, retries, or dead-letter handling
- Multi-tenant quotas or team isolation
- Event buses, telemetry sidecars, distributed tracing, or search indexing
- Hardened sandboxing beyond standard Docker container isolation
- Workflow engines, dependency graphs, or inter-agent coordination
- Cloud artifact storage, secret management systems, or policy microservices
- Separate control plane services or microservice decomposition
- GitHub issue synchronization or PR automation as a required subsystem
- Checkpointed resumability

---

## Architecture

```text
Operator
  -> local CLI (archive-run submit / status / logs / cancel)
  -> local orchestrator process
     -> validates repo path, commit SHA, task ID
     -> writes run record to SQLite
     -> writes manifest.json to run directory
     -> acquires concurrency semaphore (max 3)
     -> starts Docker container:
          --network none
          --cap-drop ALL
          --user 1000:1000
          --read-only root filesystem
          manifest.json mounted read-only
          output/ mounted read-write
     -> tails container logs to execution.jsonl
     -> watchdog thread enforces wall-clock timeout
     -> on exit: records status, exit code, artifact paths

Local persistence
  -> SQLite (runs, artifacts, events tables)
  -> ./data/runs/<run-id>/ for logs and artifacts
```

---

## Core Components

### 1. Golden Image

A single pre-built Docker image containing everything an agent needs:

- Agent CLIs: Claude Code, Codex CLI, Gemini CLI
- Development tools: git, Graphite CLI, language runtimes (Python, Node, Rust)
- Project tooling: linters, test runners, speckit scripts

A single image eliminates container startup variability and simplifies
Day 1 debugging. The image is built once and referenced by digest in
orchestrator configuration.

### 2. Local CLI

Single operator-facing entry point:

```bash
archive-run submit --task T-07 --repo /path/to/repo --commit <sha>
archive-run status <run-id>
archive-run logs <run-id>
archive-run cancel <run-id>
archive-run list
```

A local HTTP API is not needed for the MVP. Add it only if it accelerates
integration work in a later phase.

### 3. Local Orchestrator

One in-process coordinator. Replaces the API Service, Orchestrator,
Scheduler, and Policy Service from the full architecture.

Responsibilities:

- validate repo path, commit SHA, and task ID against tasks.md
- create a run record in SQLite
- write manifest.json to the run directory
- acquire the concurrency semaphore
- invoke `docker run` with correct mounts, limits, and security flags
- tail stdout and stderr to `execution.jsonl`
- run a watchdog thread that calls `docker stop` at the timeout threshold
- on container exit: record final status, exit code, and artifact paths in SQLite
- release the semaphore

This is a single-process state machine, not a distributed control plane.

### 4. Concurrency Semaphore

A threading semaphore caps concurrent container runs:

```python
MAX_CONCURRENT_RUNS = 3
semaphore = threading.Semaphore(MAX_CONCURRENT_RUNS)
```

Submissions beyond the limit block until a slot opens. No queue
infrastructure is needed. The cap prevents accidental resource exhaustion
on a local machine without requiring any scheduling logic.

### 5. Manifest

Write `manifest.json` to the run directory before container start and mount
it read-only into the container. Do not use environment variables for
manifest delivery — keeping the manifest as a structured file on disk makes
it inspectable, diffable, and consistent with the full architecture's
principle of manifest immutability.

Credentials (GitHub token, model API key) are passed as environment
variables separately from the manifest.

Minimal manifest contents:

```json
{
  "run_id": "run_abc123",
  "task_id": "T-07",
  "repo_path": "/workspace/repo",
  "commit_sha": "abc123def",
  "output_dir": "/workspace/output",
  "runtime_config": {}
}
```

### 6. Container Configuration

```bash
docker run \
  --rm \
  --network none \
  --cap-drop ALL \
  --user 1000:1000 \
  --read-only \
  --tmpfs /tmp \
  --memory 4g \
  --cpus 2 \
  --stop-timeout 7200 \
  -v ./data/runs/<id>/manifest.json:/manifest.json:ro \
  -v ./data/runs/<id>/output:/workspace/output:rw \
  -v /path/to/repo:/workspace/repo:ro \
  -e GITHUB_TOKEN=... \
  -e MODEL_API_KEY=... \
  archive-agent@sha256:<digest>
```

`--network none` is the default for implementation tasks. It approximates
the full architecture's deny-all egress baseline from day one rather than
retrofitting it later. If a task genuinely needs network access (package
installation, model API calls), that is a deliberate exception configured
per run, not the default.

### 7. State Store (SQLite)

Three tables provide run history, artifact tracking, and a lightweight
audit trail:

```sql
CREATE TABLE runs (
  id           TEXT PRIMARY KEY,
  task_id      TEXT NOT NULL,
  repo_path    TEXT NOT NULL,
  commit_sha   TEXT NOT NULL,
  status       TEXT NOT NULL,  -- submitted | running | succeeded | failed | cancelled | timed_out
  started_at   TEXT,
  finished_at  TEXT,
  exit_code    INTEGER,
  container_id TEXT
);

CREATE TABLE artifacts (
  run_id  TEXT NOT NULL,
  kind    TEXT NOT NULL,
  path    TEXT NOT NULL
);

CREATE TABLE events (
  run_id   TEXT NOT NULL,
  ts       TEXT NOT NULL,
  event    TEXT NOT NULL,
  message  TEXT
);
```

The `events` table is written append-only throughout the run. It costs
almost nothing to maintain and provides the first audit capability needed
when a run fails unexpectedly. Write events at: run created, container
started, timeout fired, container exited, artifacts recorded.

### 8. Artifact and Log Storage

```text
./data/runs/<run-id>/
  manifest.json       (written by orchestrator before start)
  execution.jsonl     (stdout/stderr tailed from container)
  output/
    manifest.json     (declared outputs written by agent)
    <task artifacts>
  result.json         (written by orchestrator on completion)
```

### 9. Lifecycle

```text
submitted -> running -> succeeded
                     -> failed
                     -> cancelled
                     -> timed_out
```

Intermediate states from the full architecture (`validated`, `scheduled`,
`launching`, `completing`) are implementation details at this stage, not
user-visible states.

---

## Execution Flow

1. Operator submits a run via CLI.
2. Orchestrator validates the repo path, commit SHA, and task ID. Checks
   that the task exists in `tasks.md` with acceptance criteria present.
3. Orchestrator writes a run record (status: submitted) and an events record.
4. Orchestrator writes `manifest.json` to the run directory.
5. Orchestrator acquires the concurrency semaphore.
6. Orchestrator starts the Docker container with the configuration above.
   Updates run record to status: running.
7. Agent clones or uses the mounted repo, reads manifest, executes the task:
   - creates branch
   - follows TDD cycle per acceptance criterion
   - commits, pushes, opens PR
   - writes declared outputs to `/workspace/output/`
8. Orchestrator tails logs to `execution.jsonl` throughout.
9. Watchdog thread kills the container if it exceeds the timeout.
10. On container exit, orchestrator reads `output/manifest.json`, records
    artifact paths in SQLite, writes `result.json`, updates run status.
11. Operator inspects status, logs, and output via CLI.

The operator opens the PR on the host using `gh` or `gt` if the agent has
not done so. GitHub automation is not required for the loop to be proven.

---

## Codebase Structure

```text
archive-run/
├── cli.py          # entry point, argument parsing
├── orchestrator.py # run lifecycle state machine
├── runner.py       # docker run, log tail, watchdog
├── db.py           # SQLite schema, read/write helpers
├── validator.py    # repo path, commit SHA, tasks.md checks
└── config.py       # MAX_CONCURRENT_RUNS, timeout, image digest
agent/
├── Dockerfile
└── entrypoint.sh   # reads manifest, runs CLI, writes output manifest
data/
└── runs/           # created at runtime
```

---

## Build Plan

### Day 1 — Execution substrate

- Build `agent/Dockerfile` (Golden Image with all CLIs)
- Implement `runner.py`: `docker run` with correct security flags, log
  tail, watchdog thread
- Smoke test: manually run a hello-world task inside the container, confirm
  isolation and log capture work

### Day 2 — State and orchestration

- Implement `db.py`: SQLite schema, `create_run`, `update_run`, `list_runs`,
  `append_event`, `record_artifact`
- Implement `validator.py`: repo path exists, commit SHA resolvable, task ID
  present in `tasks.md` with acceptance criteria
- Implement `orchestrator.py`: manifest write, semaphore, docker run, exit
  handling
- Wire CLI commands: `submit`, `status`, `list`

### Day 3 — Observability and polish

- Implement `logs` and `cancel` commands
- Wire artifact recording from `output/manifest.json`
- Add one happy-path demo task end to end
- Harden error output on validation failure
- Write `result.json` on completion

### Optional Day 4

- Add `--network host` or targeted egress flag for tasks that need network
  access (model API calls during execution)
- Add optional GitHub Issue label update on run completion
- Add one simple retry flag for container-level infrastructure failures

---

## Acceptance Criteria

The MVP is complete when a single developer can:

1. Submit a task run locally with a single CLI command
2. Watch it execute in an isolated Docker container with no network access
3. Inspect run status while it is in progress
4. Cancel or time out the run
5. Inspect structured logs and output artifacts after completion
6. Rerun the same task against a different commit SHA and get independent results

---

## Accepted Limitations

- Local execution only — no remote workers or horizontal scaling
- `--network none` means agent cannot call model APIs mid-run unless network
  is explicitly re-enabled; the model invocation must be wired through the
  container entrypoint at startup or an exception flag must be added
- Weak security compared to gVisor sandbox
- No retry logic — failed runs require manual resubmission
- Credentials in environment variables
- No GitHub automation unless Optional Day 4 is completed
- Single machine capacity ceiling

---

## Recommended Next Step

Capture this approach in an ADR before implementation begins. The full
distributed architecture remains the long-term target. This MVP is a
validation instrument, not a scaled-down permanent replacement. Decisions
made here — manifest format, state schema, lifecycle states, artifact
conventions — will either survive into the full architecture or be replaced
with documented reasons. Either outcome is valuable.
