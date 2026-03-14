# Unified MVP Proposal: The Speckit Local Runner (SLR)

## 1. Executive Summary

The Speckit Local Runner (SLR) is a hybrid MVP that merges the **security-first isolation** of the Gemini proposal, the **structured state management** of the Claude/Codex proposals, and the **low-friction integration** of using host-side CLI tools. It provides a "single-human" implementable path to a local-first execution plane that validates the core agentic loop.

## 2. Core Pillars

### 2.1 Orchestration (Python CLI)

A Python-based orchestrator (`slr.py`) provides a robust, extensible CLI for the developer. It avoids the overhead of a distributed control plane while allowing for complex task sequencing and error handling.

### 2.2 Hardened Execution (Docker)

Following the Gemini model, the SLR prioritizes security from Day 1:

- **Default Isolation**: Containers run with `--network none` for implementation tasks to prevent data exfiltration.
- **Privilege Reduction**: All containers use `--cap-drop=ALL` and run as a non-root user.
- **Golden Image**: A single Docker image contains the agent CLIs and necessary toolchains.

### 2.3 Hybrid Persistence (SQLite + Git)

The SLR uses a two-tier persistence model:

- **Live State (Git)**: The repository and the `specs/` directory remain the primary source of truth for the current feature and task status.
- **Historical Audit (SQLite)**: Adopting the Claude/Codex approach, a local SQLite database tracks run history, performance metrics, and exit codes for retrospective analysis.

### 2.4 Proxy Integration (Host CLIs)

To minimize authentication and credential management complexity (Secret Volumes vs. API Tokens), the SLR uses the **Host CLI Proxy** model:

- The orchestrator invokes `gh` (GitHub) and `gt` (Graphite) on the host machine using the developer's existing session.
- This provides an immediate "PR Loop" without needing to build a dedicated Integration Service or manage OAuth tokens inside containers.

## 3. Unified Architecture

```text
Host Machine (Developer)
├── slr.py (Orchestrator)
│   ├── Task Parser (Markdown -> Python Objects)
│   ├── Docker Manager (Shells out to `docker run`)
│   └── State Manager (Writes to SQLite & Git)
├── local.db (SQLite: Run history, logs, and timing)
└── Repository Root/
    ├── .git/ (Branch management)
    └── specs/<feature>/
        ├── tasks.md (Task queue)
        └── logs/ (Per-run log captures)

Docker Container (Agent)
├── /workspace (Bind-mount of Project Root)
├── /output (Bind-mount for artifacts)
└── Agent Environment (Claude/Gemini CLI + Runtimes)
```

## 4. Integrated 3-Day Build Plan

### Day 1: The Execution Substrate (Security & Docker)

- **Task**: Create the "Golden Image" Dockerfile and the Python runner core.
- **Goal**: Successfully run a "Hello World" task where an agent modifies a file inside a `--network none` container and the change persists to the host.

### Day 2: Structured Orchestration (State & Parsing)

- **Task**: Implement the `tasks.md` parser and the SQLite schema.
- **Goal**: Automate the "Next Task" selection. The orchestrator should see an incomplete task in Markdown, create a branch, and launch the container for that specific task ID.

### Day 3: The Completion Loop (Git & PRs)

- **Task**: Integrate branch committing and host-side `gh` PR creation.
- **Goal**: A full "End-to-End" run. `slr run <feature>` should execute the next task, run tests, commit the result, and prompt the user to open a PR via `gh pr create`.

## 5. Definition of Done

The SLR MVP is considered complete when a developer can:

1. Initialize a feature using the Speckit workflow.
2. Run a single command (`slr run`) that automatically executes the next pending task in an isolated container.
3. Review the `git diff` and see the task marked as completed in `tasks.md`.
4. Submit the work to GitHub using the host's existing CLI tools.
