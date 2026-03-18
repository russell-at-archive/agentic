# Tasks: Isolated Docker Runtime

**Input**: Design documents from `specs/1813-isolated-docker-runtime/`
**Prerequisites**: plan.md (required), spec.md (required)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

## Phase 1: Setup

**Purpose**: Create directory structure and ADR documents.

- [ ] T001 Create `docker/agent-run/` directory
- [ ] T002 [P] Create ADR `docs/adr/001-isolated-agent-runtime.md` documenting
  the decision to use a separate Docker container for subagent task execution
- [ ] T003 [P] Create ADR `docs/adr/002-agent-auth-bind-mount.md` documenting
  the decision to use host bind mounts for agent authentication and session state

**Checkpoint**: Directory structure and ADRs in place.

---

## Phase 2: User Story 1 - Single-Task Container Execution (Priority: P1)

**Goal**: An orchestrator can dispatch a single command to an isolated container
and receive the exit code and output.

**Independent Test**: Run `bin/agent-run echo "hello world"` and confirm output
and exit code 0.

### Implementation for User Story 1

- [ ] T004 [US1] Create `docker/agent-run/Dockerfile` with Ubuntu 24.04 base,
  Node.js LTS, and all agent CLI installations (Claude Code, Codex, Gemini CLI,
  PI coding agent). Create non-root `agent` user (UID 1000). Set PATH.
- [ ] T005 [US1] Create `bin/agent-run` wrapper script with: workspace root
  resolution, Docker availability check, auto-build on first run, `docker run
  --rm` invocation with workspace mount at `/workspace`, and exit code
  forwarding. (Depends on T004)
- [ ] T006 [US1] Add `agent-build` and `agent-run` targets to `Makefile` under
  a new `##@ Agent Runtime` section. (Depends on T005)

**Checkpoint**: `bin/agent-run echo "hello"` works end to end.

---

## Phase 3: User Story 2 - Host Auth and Session Reuse (Priority: P1)

**Goal**: Containerized agent CLIs can use host credentials and session state
without re-authentication.

**Independent Test**: Run `bin/agent-run claude --print "hello"` with valid
host credentials and confirm successful authentication.

### Implementation for User Story 2

- [ ] T007 [US2] Add bind mount flags to `bin/agent-run` for all agent config
  directories: `~/.agents`, `~/.claude`, `~/.claude.json`, `~/.codex`,
  `~/.gemini`, `~/.pi`, `~/.aws`, and `~/.ssh` (readonly). Add conditional
  mount logic that skips directories that do not exist on the host with a
  warning. (Depends on T005)
- [ ] T008 [US2] Add environment variable forwarding to `bin/agent-run` for
  `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and `GEMINI_API_KEY` (only when set
  on the host). (Depends on T005)

**Checkpoint**: `bin/agent-run claude --print "hello"` authenticates and
produces output using host-mounted credentials.

---

## Phase 4: User Story 3 - Devcontainer Isolation (Priority: P2)

**Goal**: The new runtime and existing devcontainer coexist without conflicts.

**Independent Test**: Start devcontainer via `bin/dc up`, run a task via
`bin/agent-run`, confirm both run independently.

### Implementation for User Story 3

- [ ] T009 [US3] Ensure container naming in `bin/agent-run` uses a distinct
  prefix (e.g., `agent-run-<random>`) that cannot collide with the devcontainer
  name `archive-agentic`. Verify no shared volumes or port mappings. (Depends
  on T005)

**Checkpoint**: Both containers can run simultaneously without interference.

---

## Phase 5: Polish

**Purpose**: Documentation and edge case handling.

- [ ] T010 Add `--timeout` flag support to `bin/agent-run` that passes
  `--stop-timeout` to `docker run`. (Depends on T005)
- [ ] T011 [P] Update `README.md` with a brief section on the agent runtime
  explaining usage of `bin/agent-run` and `make agent-run`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies. T002 and T003 can run in parallel.
- **Phase 2 (US1)**: T004 has no code dependencies. T005 depends on T004.
  T006 depends on T005.
- **Phase 3 (US2)**: T007 and T008 both depend on T005 (wrapper script exists).
  T007 and T008 can run in parallel with each other.
- **Phase 4 (US3)**: T009 depends on T005.
- **Phase 5 (Polish)**: T010 depends on T005. T011 can run in parallel.

### Parallel Opportunities

- T002 and T003 (ADRs) can run in parallel
- T007 and T008 (auth mounts and env vars) can run in parallel
- T010 and T011 (polish tasks) can run in parallel
- Phases 3 and 4 can run in parallel once Phase 2 is complete

### Recommended Execution Order

1. T001, T002, T003 (setup, parallel ADRs)
2. T004 (Dockerfile)
3. T005 (wrapper script)
4. T006, T007, T008, T009 (all depend on T005, can run in parallel)
5. T010, T011 (polish, parallel)

## Notes

- Each task is scoped for a single stacked PR.
- The Dockerfile and wrapper script are the two core deliverables.
- ADRs must land before or alongside implementation per AGENTS.md mandate.
