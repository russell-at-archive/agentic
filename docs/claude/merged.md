# MVP: Local Docker Agent Runner

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

The following are explicitly out of scope. If any become necessary during
implementation, that is evidence the MVP scope is wrong, not a reason to
expand it.

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
  -> local CLI
       archive-run submit --task T-07 --repo /path/to/repo --commit <sha>
       archive-run status <run-id>
       archive-run logs <run-id>
       archive-run cancel <run-id>
       archive-run list

  -> local orchestrator (single process)
       validates repo path, commit SHA, task ID against tasks.md
       writes run record to SQLite
       writes manifest.json to run directory
       acquires concurrency semaphore (max 3)
       starts Docker container
       tails logs to execution.jsonl
       watchdog thread enforces wall-clock timeout
       on exit: records status, exit code, artifact paths in SQLite

Local persistence
  SQLite  ->  runs / artifacts / events tables
  ./data/runs/<run-id>/  ->  manifest, logs, output artifacts
```

---

## Core Components

### 1. Golden Image

A single pre-built Docker image containing everything an agent needs:

- Agent CLIs: Claude Code, Codex CLI, Gemini CLI
- Development tools: git, Graphite CLI, language runtimes (Python, Node, Rust)
- Project tooling: linters, test runners, speckit scripts

One image eliminates container startup variability, simplifies Day 1
debugging, and gives every run a consistent, auditable execution environment.
The image is built once and referenced by digest in orchestrator configuration.

### 2. Local CLI

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

One in-process coordinator replaces the API Service, Orchestrator, Scheduler,
and Policy Service from the full architecture.

Responsibilities:

- validate the repo path, commit SHA, and task ID (task must exist in
  `tasks.md` with acceptance criteria present)
- create a run record in SQLite (status: submitted) and write an events record
- write `manifest.json` to the run directory
- acquire the concurrency semaphore
- invoke `docker run` with correct mounts, resource limits, and security flags
- tail container stdout and stderr to `execution.jsonl`
- run a watchdog thread that calls `docker stop` at the timeout threshold
- on container exit: read `output/manifest.json`, record artifact paths in
  SQLite, write `result.json`, update run status, release the semaphore

This is a single-process state machine, not a distributed control plane.

### 4. Concurrency Semaphore

A threading semaphore caps concurrent container runs:

```python
MAX_CONCURRENT_RUNS = 3
semaphore = threading.Semaphore(MAX_CONCURRENT_RUNS)
```

Submissions beyond the limit block until a slot opens. No queue infrastructure
is required. The cap prevents accidental resource exhaustion on a local machine
without any scheduling logic.

### 5. Manifest

Write `manifest.json` to the run directory before container start and mount it
read-only into the container. Do not use environment variables for manifest
delivery — a file on disk is inspectable, diffable, and consistent with the
full architecture's principle of manifest immutability. Credentials are passed
as environment variables separately.

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

`--network none` is the default for all implementation runs. It approximates
the full architecture's deny-all egress baseline from day one rather than
retrofitting it later. If a task requires network access (model API calls,
package installation), that is a deliberate per-run exception, not the default.

`--cap-drop ALL`, `--user 1000:1000`, and `--read-only` apply to every run
regardless of task type. These are one-time flags that meaningfully reduce
the blast radius of a misbehaving agent at no implementation cost.

### 7. State Store (SQLite)

Three tables provide run history, artifact tracking, and a lightweight
append-only audit trail:

```sql
CREATE TABLE runs (
  id           TEXT PRIMARY KEY,
  task_id      TEXT NOT NULL,
  repo_path    TEXT NOT NULL,
  commit_sha   TEXT NOT NULL,
  status       TEXT NOT NULL,
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

`status` values: `submitted` | `running` | `succeeded` | `failed` |
`cancelled` | `timed_out`

The `events` table is written append-only throughout the run. Write events at:
run created, container started, timeout fired, container exited, artifacts
recorded. This costs almost nothing to maintain and provides the first audit
capability needed when a run fails unexpectedly.

### 8. Filesystem Layout

```text
archive-run/
├── cli.py           entry point, argument parsing
├── orchestrator.py  run lifecycle state machine
├── runner.py        docker run, log tail, watchdog thread
├── db.py            SQLite schema, read/write helpers
├── validator.py     repo path, commit SHA, tasks.md checks
└── config.py        MAX_CONCURRENT_RUNS, timeout, image digest

agent/
├── Dockerfile
└── entrypoint.sh    reads manifest, invokes CLI, writes output manifest

data/
└── runs/            created at runtime
    └── <run-id>/
        ├── manifest.json      written by orchestrator before start
        ├── execution.jsonl    stdout/stderr tailed from container
        ├── result.json        written by orchestrator on completion
        └── output/
            ├── manifest.json  declared outputs written by agent
            └── <artifacts>
```

---

## Execution Flow

1. Operator runs `archive-run submit`.
2. Orchestrator validates repo path, commit SHA, and task ID. Confirms task
   exists in `tasks.md` with acceptance criteria present.
3. Orchestrator writes run record (status: submitted) and initial event to
   SQLite.
4. Orchestrator writes `manifest.json` to the run directory.
5. Orchestrator acquires the concurrency semaphore (blocks if at max).
6. Orchestrator starts the Docker container. Updates run record to status:
   running. Writes container-started event.
7. Agent reads `/manifest.json`, uses the mounted `/workspace/repo` checkout,
   and executes the task:
   - creates branch `t-<##>-<slug>`
   - follows TDD cycle per acceptance criterion
   - commits, pushes, opens PR
   - writes declared outputs to `/workspace/output/`
   - writes `/workspace/output/manifest.json` listing produced artifacts
8. Orchestrator tails logs to `execution.jsonl` throughout.
9. Watchdog thread calls `docker stop` if the container exceeds the timeout.
   Writes timeout event, updates run status to timed_out.
10. On container exit 0: orchestrator reads `output/manifest.json`, records
    artifact paths in SQLite, writes `result.json`, updates status to
    succeeded.
11. On non-zero exit: orchestrator updates status to failed, writes failure
    event with exit code.
12. Semaphore released. Operator inspects status, logs, and output via CLI.

The operator reviews and merges the PR on the host using `gh` or `gt`.
GitHub automation is not required to prove the loop.

---

## Lifecycle

```text
submitted -> running -> succeeded
                     -> failed
                     -> cancelled
                     -> timed_out
```

Intermediate states from the full architecture (`validated`, `scheduled`,
`launching`, `completing`) are implementation detail, not user value, at
this scale.

---

## Build Plan

### Day 1 — Execution substrate

- Build `agent/Dockerfile`: Golden Image with all agent CLIs, language
  runtimes, git, Graphite, speckit scripts
- Implement `runner.py`: `docker run` with security flags, log tail to file,
  watchdog thread
- Smoke test: manually run a hello-world task inside the container; confirm
  `--network none` isolation, log capture, and clean exit all work

### Day 2 — State and orchestration

- Implement `db.py`: SQLite schema, `create_run`, `update_run`, `list_runs`,
  `append_event`, `record_artifact`
- Implement `validator.py`: repo path exists, commit SHA resolvable, task ID
  present in `tasks.md` with acceptance criteria
- Implement `orchestrator.py`: manifest write, semaphore acquire/release,
  `docker run`, exit handling, artifact recording
- Wire `submit`, `status`, and `list` CLI commands

### Day 3 — Observability and polish

- Wire `logs` and `cancel` CLI commands
- Write `result.json` on run completion
- Run one full happy-path demo task end to end
- Harden error output on validation failure and container non-zero exit

### Optional Day 4

- Add `--network host` or a targeted egress flag for tasks that require
  network access during execution (model API mid-run, package installation)
- Add optional GitHub Issue label update on run completion
- Add one simple retry flag for container-level infrastructure failures
- Add a minimal local HTTP API if programmatic submission is needed

---

## Acceptance Criteria

The MVP is complete when a single developer can:

1. Submit a task run locally with a single CLI command
2. Watch it execute in an isolated Docker container with no network access
3. Inspect run status while it is in progress
4. Cancel or time out the run cleanly
5. Inspect structured logs and output artifacts after completion
6. Rerun the same task against a different commit SHA and get independent results

---

## Accepted Limitations

- Local execution only — no remote workers or horizontal scaling
- `--network none` means agent cannot call model APIs during execution unless
  a network exception flag is added on Day 4; initial testing requires a
  workflow that does not need mid-run egress, or the flag must be added first
- No retry logic — failed runs require manual resubmission
- Credentials in environment variables
- No GitHub automation unless Optional Day 4 is completed
- Single machine capacity ceiling
- Standard Docker isolation only — no kernel sandboxing

Each limitation maps directly to a named component in the full architecture
and can be addressed incrementally once the core loop is validated.

---

## Recommended Next Step

Capture this approach in an ADR before implementation begins. The full
distributed architecture remains the long-term target. This MVP is a
validation instrument, not a permanent replacement. Decisions made here —
manifest format, state schema, lifecycle states, artifact conventions — will
either survive into the full architecture or be replaced with documented
reasons. Either outcome is valuable.
