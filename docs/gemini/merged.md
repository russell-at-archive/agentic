# MVP: The Speckit Local Runner (SLR)

## 1. Goal & Strategy

The Speckit Local Runner (SLR) is a local-first execution substrate designed to prove the core agentic loop: **Take an approved task, launch an isolated container, execute the task, and submit the result for review.**

The MVP aims to answer these critical questions:

- Can an agent reliably execute tasks by reading local repository planning artifacts (`spec.md`, `plan.md`)?
- Does the container isolation provide sufficient safety for autonomous implementation?
- What minimal manifest data is required to drive an agent without a full control plane?

## 2. What Is Cut (Full Architecture vs. MVP)

Every component designed for enterprise scale, multi-tenancy, and high availability is removed to enable a "single-human" 3-day build.

| Full Architecture Component | MVP Disposition (SLR) |
| --- | --- |
| Kubernetes + Worker Controller | Replaced by local `docker run` |
| KEDA Autoscaling | Fixed concurrency (MAX_CONCURRENT_RUNS = 1-3) |
| NATS Work Queue / Event Bus | In-memory queue / direct shell execution |
| Policy Service | Inlined as simple pre-flight checks (Tasks status: ready) |
| Spec Resolver Service | Inlined as local filesystem reads of `specs/` |
| GitHub Integration Service | Replaced by host-side `gh` CLI proxy (or direct API) |
| Tool Gateway (Audited Proxy) | Dropped — agent calls tools directly in container |
| PostgreSQL Cluster | Local SQLite for run history + Git for live state |
| gVisor Secure Runtime | Standard Docker with `--network none` & `--cap-drop` |
| Artifact Store (S3) | Local filesystem under `specs/<feature>/logs/` |

## 3. Core Architecture

### 3.1 Orchestrator (`slr.py`)

A Python-based CLI that manages the lifecycle of a run on the developer's machine.

- **Task Parsing**: Reads `specs/<feature>/tasks.md` to find the next incomplete task.
- **Branch Management**: Automatically creates `t-<id>-<slug>` branches before execution.
- **Docker Wrapper**: Orchestrates the `docker run` command with the correct security profiles and volume mounts.
- **State Store**: Updates a local `local.db` (SQLite) with run metadata and marks tasks as `[x]` in Markdown upon success.

### 3.2 Hardened Execution (Docker)

The SLR prioritizes isolation even in the MVP phase:

- **Isolation**: Containers run with `--network none` for implementation tasks (no data exfiltration).
- **Security**: All containers use `--cap-drop=ALL` and run as a non-root UID (1000).
- **Bind Mounts**: The project root is bind-mounted (Read/Write) to allow the agent to modify source code directly, while `specs/` is used for artifact/log capture.

### 3.3 Hybrid Persistence Model

- **Live State (Git)**: The repository's own branches and Markdown files are the source of truth for the current work.
- **Audit Store (SQLite)**: A simple schema tracks every run attempt:
  - `id`, `task_id`, `commit_sha`, `status` (queued, running, done, failed), `exit_code`, `duration`.

## 4. Simplified Lifecycle

```text
submitted (CLI) -> launching (Docker) -> running -> done (Success)
                                                 -> failed (Retry)
                                                 -> timed_out
```

## 5. Implementation Plan (3 Days)

### Day 1: The Execution Substrate

- **Golden Image**: Build a `Dockerfile` with the agent CLIs (`claude`, `gemini`), Git, and standard language runtimes.
- **Runner Script**: Create the Python logic to launch `docker run` with volume mounts and the security-hardened profile (`--network none`).
- **Smoke Test**: Verify an agent can change one file inside the container and have it persist on the host.

### Day 2: Task Orchestration & State

- **Task Parser**: Implement the Markdown parser to extract task IDs and descriptions from `tasks.md`.
- **SQLite Integration**: Setup the local database to track run history and logs.
- **Branch Automation**: Logic to checkout a new task branch before the container starts and commit the result on success.

### Day 3: The Completion Loop & UX

- **Host CLI Proxy**: Integrate the host's `gh` (GitHub) and `gt` (Graphite) CLIs to allow the orchestrator to submit PRs on behalf of the agent.
- **Interactive Gates**: Add a "Review & Approve" prompt that shows a `git diff` before the orchestrator finalizes a task.
- **Documentation**: Write a `README.md` for developers to use the SLR tool.

## 6. Definition of Done

The SLR MVP is complete when a developer can:

1. Run `slr init <feature>` to setup a new specification directory.
2. Run `slr run <feature>` and see the orchestrator automatically execute the next pending task in an isolated container.
3. Observe the orchestrator creating a branch, committing the code, and updating the task status in Markdown.
4. Review and submit the resulting PR to GitHub using a single command.
