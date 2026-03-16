# Symphony MVP Proposal — 5-Day Plan

## Executive Summary

Symphony is a daemon service that polls a Linear project for issues, creates isolated
per-issue workspaces, and runs a coding agent (Codex app-server) against each issue. This
proposal defines the smallest functional slice that validates the core value proposition:
**issues move through a workflow automatically without manual agent invocation**.

---

## Scope Decision: What the MVP Includes

### In Scope

| Area | Included |
|------|----------|
| WORKFLOW.md loader (YAML front matter + prompt body) | Yes |
| Config layer (typed getters, defaults, env resolution) | Yes |
| Linear issue tracker client (read-only) | Yes |
| Poll loop with fixed interval | Yes |
| In-memory orchestrator state (running, claimed, retry queue) | Yes |
| Workspace manager (create, reuse, sanitized path) | Yes |
| Workspace hooks (after\_create, before\_run, after\_run) | Yes |
| Agent Runner (Codex app-server over stdio, JSON-RPC) | Yes |
| Prompt template rendering (Liquid-compatible, strict) | Yes |
| Exponential backoff retry | Yes |
| Stall detection | Yes |
| Active-run reconciliation (per tick) | Yes |
| Startup terminal workspace cleanup | Yes |
| Structured logging to stderr | Yes |
| Concurrency limit (global) | Yes |

### Deferred (Post-MVP)

| Area | Reason |
|------|--------|
| Docker container isolation | Adds complexity; use local subprocess for MVP trust posture |
| HTTP server + dashboard | Observability-only; logs are sufficient for Day 1 operation |
| Dynamic WORKFLOW.md hot-reload | File-watch complexity; restart-to-reload is acceptable for MVP |
| Per-state concurrency limits | Refinement; global limit covers MVP needs |
| SSH host distribution | Not needed for single-host MVP |
| `linear_graphql` client-side tool extension | Agent can use its own Linear tooling |
| Terminal UI / status surface | Structured logs are sufficient |
| `before_remove` hook | Low priority; workspace cleanup is fire-and-forget |

---

## Technical Decisions

**Language**: TypeScript (Node.js)
- Native async/await for concurrent agent sessions
- Strong typing for the domain model
- `js-yaml` for WORKFLOW.md parsing
- `liquidjs` for Liquid-compatible prompt templates

**No persistent database**: Orchestrator state is in-memory; restart recovery is
tracker-driven (re-poll on startup) and filesystem-driven (workspace dirs on disk).

**Trust posture for MVP**: High-trust local execution. The agent subprocess runs with
full host credentials. No sandbox. Document this explicitly in README.

---

## Daily Plan

### Day 1 — Foundation: Config + Linear Client

**Goal**: Load WORKFLOW.md and successfully query Linear for candidate issues.

Tasks:

1. Project scaffolding: `package.json`, `tsconfig.json`, `src/` layout mirroring spec layers
2. **Workflow Loader** (`src/workflow/loader.ts`)
   - Read file, split YAML front matter from prompt body
   - Return `{ config, prompt_template }`
   - Error classes: `missing_workflow_file`, `workflow_parse_error`, `workflow_front_matter_not_a_map`
3. **Config Layer** (`src/config/index.ts`)
   - Typed getters for all spec-defined fields (§6.4 cheat sheet)
   - `$VAR` env resolution, `~` expansion, built-in defaults
4. **Linear Client** (`src/tracker/linear.ts`)
   - `fetchCandidateIssues()` — paginated GraphQL query filtered by project slug + active states
   - `fetchIssuesByStates()` — startup cleanup query
   - `fetchIssueStatesByIds()` — reconciliation query
   - Normalize responses to the `Issue` domain model (§4.1.1)
5. **Domain types** (`src/types.ts`) — all entities from §4.1

Acceptance: `npm run dev` loads a `WORKFLOW.md`, prints config, and fetches a page of Linear issues.

---

### Day 2 — Workspace Manager + Prompt Rendering

**Goal**: Given an issue, produce a workspace directory and a rendered prompt string.

Tasks:

1. **Workspace Manager** (`src/workspace/manager.ts`)
   - `ensureWorkspace(issue)` — sanitize identifier → path, mkdir-p, `created_now` flag
   - `removeWorkspace(workspaceKey)` — delete directory
   - Run `after_create` hook on new workspaces
   - Safety invariants: path must be inside workspace root (§9.5 invariants 1-3)
2. **Hook Runner** (`src/workspace/hooks.ts`)
   - Execute shell scripts via `bash -lc` with cwd = workspace path
   - Apply `hooks.timeout_ms`; fatal vs. ignored semantics per spec §9.4
3. **Prompt Renderer** (`src/prompt/renderer.ts`)
   - `renderPrompt(template, issue, attempt)` using `liquidjs` in strict mode
   - Unknown variables and unknown filters throw `template_render_error`
   - Fallback minimal prompt when template body is empty
4. **Startup Terminal Cleanup** (`src/orchestrator/cleanup.ts`)
   - On startup: fetch terminal-state issues, delete their workspace directories

Acceptance: Given a fake issue object, workspace directory is created, `after_create`
hook fires, and a rendered prompt string is produced.

---

### Day 3 — Agent Runner (Codex App-Server Protocol)

**Goal**: Launch a Codex app-server subprocess and drive one full turn to completion.

Tasks:

1. **Agent Runner** (`src/agent/runner.ts`)
   - Launch `bash -lc <codex.command>` with cwd = workspace path
   - Session startup handshake: `initialize` → `initialized` → `thread/start` → `turn/start`
   - Extract `thread_id` from `thread/start` result, `turn_id` from `turn/start` result
   - Read line-delimited stdout; parse JSON events
   - Stream turn until `turn/completed`, `turn/failed`, `turn/cancelled`, timeout, or exit
   - Emit typed events back to caller: `session_started`, `turn_completed`, `turn_failed`, etc.
2. **Timeout enforcement** (`src/agent/timeouts.ts`)
   - `read_timeout_ms` for startup sync request/response
   - `turn_timeout_ms` for total turn duration
3. **Multi-turn continuation** within one worker run
   - After a successful turn, re-check issue state; if still active and under `agent.max_turns`, send continuation `turn/start` on same thread
   - First turn uses full rendered prompt; continuation turns use minimal guidance
4. **Approval handling**
   - Auto-approve all command/file-change approvals (high-trust posture)
   - `turn_input_required` → hard failure

Acceptance: Given a real Codex app-server binary and a workspace, one complete agent
turn runs from prompt to `turn/completed`.

---

### Day 4 — Orchestrator Core

**Goal**: Full polling loop with dispatch, concurrency, retry, and reconciliation.

Tasks:

1. **Orchestrator** (`src/orchestrator/index.ts`)
   - In-memory state: `running` map, `claimed` set, `retry_attempts` map, `completed` set, `codex_totals`
   - Poll tick sequence (§8.1):
     1. Reconcile active runs (stall check + tracker state refresh)
     2. Dispatch preflight validation (§6.3)
     3. Fetch candidate issues
     4. Sort by priority → created\_at → identifier
     5. Dispatch eligible issues while global slots remain
2. **Dispatch eligibility** (§8.2): id/title/state present, state in active\_states, not claimed, slots available, blocker rule for Todo
3. **Retry/backoff** (§8.4):
   - Continuation retry: fixed 1000 ms after clean worker exit
   - Failure retry: `min(10000 * 2^(attempt-1), max_retry_backoff_ms)`
4. **Reconciliation** (§8.5):
   - Part A: stall detection per running issue
   - Part B: tracker state refresh → terminate workers whose issues went terminal
5. **Worker exit handling**: update aggregate token/runtime totals, schedule appropriate retry

Acceptance: With two active Linear issues, both are dispatched concurrently, complete,
and state is updated correctly in the orchestrator.

---

### Day 5 — Integration, Observability, and Hardening

**Goal**: End-to-end smoke test, structured logging, startup validation, and documentation.

Tasks:

1. **Structured logging** (`src/logging/index.ts`)
   - All log lines to stderr in `key=value` format
   - Required fields: `issue_id`, `issue_identifier`, `session_id` where applicable
   - Log: dispatch, workspace create/reuse, hook start/fail, agent session lifecycle, retry schedule, reconciliation actions, config errors
2. **Startup validation** (§6.3)
   - Validate `tracker.kind`, `tracker.api_key`, `tracker.project_slug`, `codex.command` before loop starts
   - Fail fast with clear error message
3. **CLI entrypoint** (`src/index.ts`)
   - `symphony [--workflow <path>]` starts the service
   - Loads config, runs startup cleanup, starts poll loop
   - Graceful shutdown on SIGINT/SIGTERM: stop accepting new work, wait for active sessions to finish or timeout
4. **`before_run` and `after_run` hooks** wired into Agent Runner
5. **Integration test / smoke run**: real WORKFLOW.md, real Linear project, real Codex binary
6. **README + WORKFLOW.md example**: document trust posture, required env vars, sample front matter

Acceptance: Service starts, picks up a live Linear issue in `Todo` state, runs Codex,
logs completion, and the issue moves to the handoff state as directed by the workflow prompt.

---

## Key Risks

| Risk | Mitigation |
|------|-----------|
| Codex app-server protocol shape differs from spec examples | Capture real protocol traffic on Day 3; adjust field extraction |
| Linear GraphQL schema drift | Isolate query construction; test against real API on Day 1 |
| Agent turns run very long in testing | Use short test prompts with bounded tasks; set low `turn_timeout_ms` during dev |
| Workspace hook failures breaking dispatch | Hook error surfaces must not crash the poll loop; errors are logged and handled per §9.4 |

---

## File Layout (Target)

```
src/
  index.ts              # CLI entrypoint
  types.ts              # Domain types (Issue, RunAttempt, LiveSession, etc.)
  workflow/
    loader.ts           # WORKFLOW.md reader + YAML front matter parser
  config/
    index.ts            # Typed config getters, defaults, env resolution
  tracker/
    linear.ts           # Linear GraphQL client + normalization
  workspace/
    manager.ts          # Workspace create/reuse/delete
    hooks.ts            # Hook runner
  prompt/
    renderer.ts         # Liquid template rendering
  agent/
    runner.ts           # Codex app-server subprocess + JSON-RPC protocol
    timeouts.ts         # Timeout helpers
  orchestrator/
    index.ts            # Poll loop, state machine, dispatch, reconciliation
    cleanup.ts          # Startup terminal workspace cleanup
  logging/
    index.ts            # Structured logger
WORKFLOW.md             # Example workflow for this repo
```

---

## Definition of Done

The MVP is complete when:

- [ ] Service starts from a `WORKFLOW.md` and a `LINEAR_API_KEY` environment variable
- [ ] Issues in the configured active states are automatically dispatched to Codex
- [ ] Each issue gets an isolated workspace directory
- [ ] Workspace hooks run correctly at the right lifecycle points
- [ ] Agent turns complete and failures trigger exponential backoff retry
- [ ] Stalled sessions are detected and retried
- [ ] Issues moved to terminal state in Linear cause their running sessions to be cancelled
- [ ] Structured logs allow an operator to follow every dispatch, run, and retry
- [ ] Startup validation prevents misconfigured launches with a clear error
