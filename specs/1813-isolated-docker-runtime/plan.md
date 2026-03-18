# Implementation Plan: Isolated Docker Runtime

**Branch**: `1813-isolated-docker-runtime` | **Date**: 2026-03-18 | **Spec**: `specs/1813-isolated-docker-runtime/spec.md`
**Input**: Feature specification from `specs/1813-isolated-docker-runtime/spec.md`

## Summary

Add a standalone Docker-based execution environment for orchestrator-dispatched
subagent tasks. The implementation consists of a new Dockerfile (Ubuntu 24.04)
and a bash wrapper script that builds the image and runs one-off containers with
host-mounted auth/session state. This is additive and does not modify the
existing devcontainer workflow.

## Technical Context

**Language/Version**: Bash (wrapper script), Dockerfile (container definition)
**Primary Dependencies**: Docker Engine, Node.js LTS, Claude Code, Codex,
Gemini CLI, PI coding agent
**Storage**: N/A (stateless one-off containers; state persists via host bind mounts)
**Testing**: Manual integration tests via wrapper script invocations
**Target Platform**: Linux (container) on macOS/Linux host with Docker
**Project Type**: Infrastructure / platform tooling
**Performance Goals**: Container startup under 5 seconds (image pre-built)
**Constraints**: Must not modify `.devcontainer/`; must preserve host auth flows
**Scale/Scope**: Single-task container execution; one container per invocation

## Constitution Check

No constitution file exists in this project. The following project-level
constraints are inferred from AGENTS.md and the existing codebase:

- All significant architectural decisions require ADRs: **PASS** (ADR-001 and
  ADR-002 created alongside this plan)
- Additive-only constraint (no devcontainer modification): **PASS**
- Non-root container execution: **PASS** (Dockerfile creates and uses a
  dedicated user)

## Project Structure

### Documentation (this feature)

```text
specs/1813-isolated-docker-runtime/
+-- spec.md
+-- plan.md
+-- tasks.md
```

### Source Code (repository root)

```text
docker/
+-- agent-run/
    +-- Dockerfile          # Ubuntu 24.04 agent runtime image

bin/
+-- agent-run               # Bash wrapper for one-off container execution
+-- claude-keychain-export  # (existing) credential export helper
+-- dc                      # (existing) devcontainer helper

docs/adr/
+-- 001-isolated-agent-runtime.md
+-- 002-agent-auth-bind-mount.md
```

**Structure Decision**: The new Dockerfile lives under `docker/agent-run/` to
clearly separate it from the `.devcontainer/` directory. The wrapper script
follows the existing `bin/` convention established by `bin/dc` and
`bin/claude-keychain-export`.

## Implementation Details

### Dockerfile (`docker/agent-run/Dockerfile`)

The Dockerfile mirrors the tool installation approach in
`.devcontainer/Dockerfile` but uses a plain Ubuntu 24.04 base (not the
devcontainer base image) and adds a dedicated non-root user:

1. `FROM ubuntu:24.04`
2. Install system dependencies (`curl`, `git`, `ca-certificates`)
3. Install Node.js LTS via NodeSource
4. Install agent CLIs globally via npm: `@google/gemini-cli`, `@openai/codex`,
   `@mariozechner/pi-coding-agent`
5. Create a non-root user (`agent`, UID 1000)
6. Switch to that user and install Claude Code via the native installer
7. Set PATH to include `/home/agent/.local/bin` and npm global bin

### Wrapper Script (`bin/agent-run`)

The wrapper script:

1. Resolves the workspace root (same pattern as `bin/dc`)
2. Checks that Docker is available
3. Builds the image if `archive-agent-run:latest` does not exist
4. Constructs `docker run` with:
   - `--rm` for automatic cleanup
   - Bind mounts for all agent config directories
   - Environment variable forwarding for API keys
   - Workspace mount at `/workspace`
   - User mapping to match host UID
   - All remaining arguments passed as the container command
5. Forwards the container exit code

### Makefile Integration

Add `agent-run` and `agent-build` targets to the existing Makefile under a new
`##@ Agent Runtime` section, following the existing pattern.

## Complexity Tracking

No constitution violations. The implementation adds two files (Dockerfile +
wrapper script) and two Makefile targets. No new abstractions or patterns are
introduced beyond what already exists in the repository.
