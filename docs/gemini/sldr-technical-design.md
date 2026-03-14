# Technical Design: Speckit Local Docker Runner (SLDR)

## 1. Problem Statement & Context

The current "Speckit" workflow (Specify -> Plan -> Tasks -> Implement) is a high-discipline process that relies on agents following complex prompt instructions. However, it lacks:

- **Execution Isolation**: Agents run directly on the host, which is risky for untrusted or complex implementation tasks.
- **Automation**: There is no "orchestrator" to sequence tasks automatically or manage the transition between planning and implementation.
- **Consistency**: Different agents may interpret the process slightly differently.

The **Speckit Local Docker Runner (SLDR)** aims to provide a local-first, container-isolated environment that automates the Speckit lifecycle using the developer's local Docker daemon.

## 2. Proposed Architecture

### 2.1 The SLDR Orchestrator (`sldr.py`)

A Python CLI tool that acts as the "Local Control Plane."

- **Source of Truth**: The local filesystem (specifically `specs/` and `.git/`).
- **Task Management**: Parses `tasks.md` to identify the next pending task.
- **Docker Wrapper**: Executes `docker run` with specific security profiles, mounts, and environment variables.

### 2.2 The Execution Plane (Docker)

The SLDR execution plane uses a security-hardened Docker environment:

- **Image**: A "Speckit Golden Image" containing:
  - AI Agent CLIs (`claude`, `gemini`, etc.)
  - Project toolchains (Git, Python, Node, etc.)
  - The repository's bash scripts (`.specify/scripts/bash/`)
- **Mounts**:
  - Project Root: Mounted at `/workspace` (Read/Write).
  - SSH/Git Config: Optional read-only mounts for pushing to remotes.
- **Security**:
  - `--network none`: Default for implementation tasks (prevents data exfiltration).
  - `--network bridge`: Enabled only for "Research" tasks.
  - `--cap-drop=ALL`: Minimizes container privileges.

### 2.3 Workflow Sequence

1. **Initialize**: `sldr init <feature>` creates `specs/<feature>/spec.md`.
2. **Design**: Human/Agent fills `spec.md`, `plan.md`, and `tasks.md`.
3. **Execute**: `sldr run <feature>`:
   - Detects the first incomplete task in `tasks.md`.
   - Creates/switches to branch `t-<id>-<slug>`.
   - Starts the Docker container.
   - Inside: Agent executes the task and marks it `[x]`.
   - Outside: SLDR detects the container exit code and file changes.
   - On Success: Automatically commits the changes.

## 3. Step-by-Step Task List

### Phase 1: Foundation & Environment (Context)

1. **Research Agent Requirements**: Identify the minimum set of env vars and binary dependencies for Claude Code and Gemini CLI.
2. **Draft "Golden Image" Dockerfile**: Include basic dev tools (git, curl) and language-specific runtimes.
3. **Design CLI Interface**: Define subcommands for `init`, `plan`, `run`, and `status`.

### Phase 2: Orchestrator Development (Task)

1. **Implement Task Parser**: Build a robust Markdown parser to extract task IDs, descriptions, and statuses from `tasks.md`.
2. **Implement Branch Manager**: Automate `git checkout -b` and `git commit` flows based on task metadata.
3. **Implement Docker Runner**:
   - Logic to map host environment variables (e.g., `ANTHROPIC_API_KEY`) to the container.
   - Logic to handle container signals and exit codes.

### Phase 3: Integration & UX (Refine)

1. **Interactive Gating**: Add a "Review & Approve" prompt that displays `git diff` before committing.
2. **Logging**: Redirect container stdout/stderr to `specs/<feature>/logs/<task-id>.log`.
3. **Documentation**: Write the `SLDR_README.md` for end-users.

## 4. Verification & Testing Plan

### 4.1 Automated Validation

- **Parser Tests**: Verify the Python task parser correctly handles incomplete, completed, and skipped tasks.
- **Mock Runner**: Test the orchestration logic by replacing `docker run` with a script that simulates file changes and exit codes.

### 4.2 Manual Validation (Smoke Test)

1. Create a "Test Feature" (e.g., "Add a contributor list").
2. Run through the full SLDR lifecycle:
   - `sldr init test-feature`
   - (Manual) Add a single task to `tasks.md`.
   - `sldr run test-feature`
3. Verify:
   - A new branch was created.
   - The file was modified inside the container.
   - The orchestrator committed the change.
   - The task was marked as completed in `tasks.md`.

## 5. Architectural Decisions & Rationale

- **Decision: Bind Mounts over Volumes**: Simplifies local development as the host and container share the same files instantly.
- **Decision: Python over Shell**: Allows for better error handling, structured logging, and more complex parsing logic as the system grows.
- **Decision: Local Git as State**: Avoids the need for a separate database (Redis/Postgres), keeping the MVP simple and "single-human" manageable.
