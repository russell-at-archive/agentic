# ADR-001: Isolated Docker Container for Subagent Task Execution

**Status**: Proposed
**Date**: 2026-03-18
**Linear Issue**: INFRA-1813

## Context

The orchestrator dispatches subagent tasks (Claude Code, Codex, Gemini CLI, PI
agent) that currently execute directly on the host system. This exposes the host
to unintended side effects: file system mutations outside the working directory,
dependency conflicts, and process-level interference between concurrent tasks.

The repository already uses a devcontainer (`.devcontainer/`) for interactive
development. However, the devcontainer is designed as a long-running development
environment, not a one-off task executor. Using it for orchestrated tasks would
conflate two distinct concerns and create lifecycle management complexity.

## Decision

Introduce a separate Docker container image and bash wrapper script dedicated
to one-off subagent task execution.

- **Image location**: `docker/agent-run/Dockerfile` (separate from
  `.devcontainer/Dockerfile`)
- **Base image**: `ubuntu:24.04` (not the devcontainer base)
- **Invocation**: `bin/agent-run <command>` runs a single `docker run --rm`
  invocation
- **Scope**: One container per task. The container is created, runs the command,
  and is removed.

The devcontainer workflow remains completely unchanged. The two container
definitions share no Dockerfiles, no naming conventions, and no lifecycle
management code.

## Consequences

### Positive

- Host system is protected from unintended mutations by subagent processes.
- Each task gets a clean, reproducible environment.
- The orchestrator can dispatch tasks to containers without managing container
  lifecycle beyond a single `docker run` call.
- The devcontainer remains focused on interactive development.

### Negative

- Two Dockerfiles to maintain with overlapping tool installations (Node.js,
  agent CLIs). Changes to agent CLI versions must be applied in both places.
- Container startup adds latency to each task invocation (mitigated by keeping
  the image pre-built and cached).
- Host bind mounts for auth create a coupling between the container and host
  filesystem layout (see ADR-002).

### Neutral

- The image tagging and rebuild strategy is manual for now. A CI-based image
  build pipeline is out of scope for this initial implementation but may be
  warranted later.

## Alternatives Considered

1. **Reuse the devcontainer for task execution**: Rejected because the
   devcontainer lifecycle (long-running, stateful, VS Code-integrated) is
   fundamentally different from one-off task execution. Mixing these concerns
   would complicate both workflows.

2. **Use Docker Compose for multi-container orchestration**: Rejected as
   premature. The current need is single-task isolation. Compose adds
   configuration complexity without corresponding benefit at this scale.

3. **Use a lightweight container runtime (e.g., Podman)**: Rejected because
   Docker is the established tool in this project and on the team's
   workstations. Introducing a different runtime adds friction without clear
   benefit.
