# Feature Specification: Isolated Docker Runtime for Subagent Tasks

**Feature Branch**: `1813-isolated-docker-runtime`
**Created**: 2026-03-18
**Status**: Draft
**Linear Issue**: INFRA-1813

## User Scenarios & Testing

### User Story 1 - Single-Task Container Execution (Priority: P1)

An orchestrator dispatches a subagent task (e.g., a Claude Code prompt, a Codex
command, or a Gemini CLI invocation) to an isolated Docker container. The
container runs the task using the specified agent CLI, produces output, and
exits. The orchestrator receives the exit code and any stdout/stderr output.

**Why this priority**: This is the core value proposition. Without the ability
to run a single task in a container, nothing else matters. It delivers host
isolation immediately.

**Independent Test**: Invoke the wrapper script with a trivial Claude Code
command (e.g., `claude --print "echo hello"`) and confirm the container starts,
runs the command, prints output, and exits with code 0.

**Acceptance Scenarios**:

1. **Given** the Docker image is built and the host has valid agent credentials,
   **When** the operator runs `bin/agent-run claude --print "hello"`,
   **Then** the container starts, Claude Code executes the prompt, output
   appears on stdout, and the container exits with code 0.
2. **Given** the Docker image is built,
   **When** the operator runs `bin/agent-run codex "list files"`,
   **Then** the Codex CLI executes inside the container and output appears on
   stdout.
3. **Given** the Docker image is built,
   **When** the operator runs a command that fails inside the container,
   **Then** the wrapper script forwards the non-zero exit code to the caller.

---

### User Story 2 - Host Auth and Session Reuse (Priority: P1)

The containerized agent CLIs reuse existing host-side authentication and session
state through bind mounts. The operator does not need to re-authenticate inside
the container.

**Why this priority**: Equal to US1 because without auth passthrough the
container cannot actually run any agent CLI successfully.

**Independent Test**: Export Claude credentials via `bin/claude-keychain-export`,
then run `bin/agent-run claude --print "hello"` and confirm it authenticates
without prompting.

**Acceptance Scenarios**:

1. **Given** `~/.claude/.credentials.json` exists on the host,
   **When** the container starts,
   **Then** Claude Code inside the container can authenticate using the
   bind-mounted credentials without interactive login.
2. **Given** `ANTHROPIC_API_KEY` is set in the host environment,
   **When** the container starts,
   **Then** the environment variable is forwarded into the container.
3. **Given** `~/.ssh` is bind-mounted as readonly,
   **When** the containerized task attempts to write to `~/.ssh`,
   **Then** the write fails (readonly enforcement).

---

### User Story 3 - Devcontainer Isolation (Priority: P2)

The new runtime does not interfere with the existing `.devcontainer` workflow.
Both can coexist without naming collisions, port conflicts, or shared state
mutations.

**Why this priority**: Important for safety but not blocking core functionality.
The existing devcontainer is a development environment; the new runtime is a
task executor. They must not conflict.

**Independent Test**: Start the devcontainer via `bin/dc up`, then run a task
via `bin/agent-run`, then confirm both are running independently with separate
container names and no shared volumes.

**Acceptance Scenarios**:

1. **Given** the devcontainer is running via `bin/dc up`,
   **When** the operator runs `bin/agent-run claude --print "hello"`,
   **Then** a separate container starts and completes without affecting the
   devcontainer.
2. **Given** neither container is running,
   **When** the operator runs `bin/agent-run` followed by `bin/dc up`,
   **Then** both containers can start without naming or resource conflicts.

---

### Edge Cases

- What happens when a required host config directory (e.g., `~/.claude`) does
  not exist? The wrapper script should fail with a clear error message before
  attempting to start the container.
- What happens when Docker is not running? The wrapper script should detect this
  and exit with a descriptive error.
- What happens when the agent-run image is not yet built? The wrapper script
  should build it automatically on first use.
- What happens when a task runs indefinitely? The wrapper script should support
  an optional timeout flag.

## Requirements

### Functional Requirements

- **FR-001**: The system MUST provide a Dockerfile at `docker/agent-run/Dockerfile`
  based on Ubuntu 24.04 that is separate from `.devcontainer/Dockerfile`.
- **FR-002**: The runtime image MUST include Node.js LTS, npm, Claude Code,
  `@openai/codex`, `@google/gemini-cli`, and `@mariozechner/pi-coding-agent`.
- **FR-003**: The system MUST provide a bash wrapper script at `bin/agent-run`
  that builds the image (if needed) and runs a one-off container with the
  user-supplied command.
- **FR-004**: The wrapper script MUST bind-mount the following host directories
  into the container: `~/.agents`, `~/.claude`, `~/.claude.json`, `~/.codex`,
  `~/.gemini`, `~/.pi`, `~/.aws`, and `~/.ssh` (readonly).
- **FR-005**: The wrapper script MUST forward `ANTHROPIC_API_KEY`,
  `OPENAI_API_KEY`, and `GEMINI_API_KEY` environment variables from the host
  when they are set.
- **FR-006**: The wrapper script MUST forward the container process exit code
  to the calling process.
- **FR-007**: The wrapper script MUST mount the repository working directory
  into the container so subagent tasks can read and write project files.
- **FR-008**: The container MUST run as a non-root user for security.
- **FR-009**: The container MUST use `--rm` so one-off containers are cleaned
  up automatically after exit.

### Key Entities

- **Agent Runtime Image**: The Docker image built from
  `docker/agent-run/Dockerfile`. Tagged as `archive-agent-run:latest`.
- **Wrapper Script**: `bin/agent-run`, the bash entrypoint that the orchestrator
  calls to dispatch tasks.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `bin/agent-run claude --print "hello"` completes successfully
  with correct output and exit code 0.
- **SC-002**: `bin/agent-run codex "list files"` completes successfully inside
  the container.
- **SC-003**: Running `bin/agent-run` does not modify any files in
  `.devcontainer/` or affect a running devcontainer instance.
- **SC-004**: All five agent CLIs (`claude`, `codex`, `gemini`, `pi`, `npm`)
  are present and executable inside the container.
- **SC-005**: The container automatically cleans up after task completion
  (no dangling containers from normal usage).
