# MVP Proposal: Speckit Local Docker Runner (SLDR)

## Overview

The Speckit Local Docker Runner (SLDR) reduces the enterprise-scale execution plane to a local CLI orchestrator that runs agents inside isolated Docker containers on a developer's machine. This provides the safety and reproducibility of the full architecture without the overhead of Kubernetes, NATS, or a distributed control plane.

## Core Components

### 1. The SLDR Orchestrator (`sldr.py`)

A simple Python-based CLI that manages the lifecycle of an agentic run.

- **Job Definition**: Reads task metadata from `specs/<feature>/tasks.md`.
- **Container Management**: Wraps `docker run` to launch agent containers with specific mounts and environment variables.
- **State Tracking**: Uses the local Git repository and filesystem as the source of truth (no external database).

### 2. The Agent Docker Image

A single "Golden Image" containing:

- **Agent CLIs**: Claude Code, Gemini CLI, etc.
- **Development Tools**: Git, Graphite, language runtimes (Python/Node/Rust), and project-specific linters/test runners.
- **Speckit Scripts**: The existing `.specify/scripts/bash` toolset.

### 3. Isolation Model (Local Docker)

- **Filesystem**: The project root is bind-mounted into the container as a read-only base, with a writeable overlay or dedicated `specs/` mount for artifacts.
- **Networking**: Containers run with `--network none` by default for implementation tasks, or restricted access for "Research" phases.
- **Credentials**: API keys and GitHub tokens are passed via `--env-file` or temporary secret mounts.

## Workflow

1. **Intake/Planning (Host)**: The human uses local agent commands to generate `spec.md` and `plan.md` in `specs/`.
2. **Execution (Docker)**:
    - User runs `sldr run <task-id>`.
    - SLDR checks out a new branch on the host.
    - SLDR launches the Docker container, mounting the repo.
    - Inside the container, the agent executes the task according to `plan.md`.
3. **Validation (Host)**: Once the container exits, the human reviews the changes and uses the `gh` CLI on the host to open a PR.

## Implementation Plan (3 Days)

### Day 1: The Execution Substrate

- Build the `Dockerfile` for the agent environment.
- Create the Python wrapper to launch `docker run` with the correct volume mounts and security flags (`--cap-drop=ALL`, `--user=1000:1000`).
- **Goal**: Manually run a "hello world" implementation task inside the container.

### Day 2: Task Orchestration

- Implement the task parser to read `tasks.md` and identify dependencies.
- Add branch management logic to the orchestrator (create branch before run, commit after success).
- **Goal**: Automate the transition from "Task Ready" to "Code Changed" in a single command.

### Day 3: Integration & UX

- Integrate the host's `gh` (GitHub) and `gt` (Graphite) CLIs for PR submission.
- Add a simple "Approval Gate" prompt between tasks.
- **Goal**: Complete a full feature lifecycle (Specify -> Plan -> Implement -> PR) using the SLDR.

## Key Reductions from Full Architecture

- **Control Plane**: Replaced by a Python script and the local filesystem.
- **Message Queue**: Replaced by sequential execution in the CLI.
- **Persistence**: Replaced by local Git branches and the `specs/` directory.
- **Telemetry**: Replaced by standard Docker logs redirected to `specs/<feature>/logs/`.
