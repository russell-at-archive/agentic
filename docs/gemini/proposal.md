# Symphony MVP Proposal: 5-Day Implementation Plan

This document proposes a plan to achieve an MVP version of the Symphony service as defined in `docs/gemini/symphony.md` within 5 days.

## 1. MVP Scope Definition

To meet the 5-day timeline, the MVP will focus on a local, single-binary orchestrator. Advanced features like high-concurrency SSH workers, a web dashboard, and complex Docker isolation will be prioritized for Phase 2.

### In-Scope for MVP
- **Workflow Loader**: Support for `WORKFLOW.md` (YAML front matter + Markdown prompt body).
- **Linear Integration**: Poll candidate issues, fetch current states for reconciliation.
- **Workspace Management**: Local directory creation per issue, sanitized identifiers, and basic hooks (`after_create`, `before_run`).
- **Agent Runner**: Subprocess management for `codex app-server` via JSON-RPC over stdio.
- **Orchestration**: Single-instance in-memory state, poll loop, basic concurrency, and exponential backoff retries.
- **Observability**: Structured JSON logs to stdout.

### Out-of-Scope (Phase 2)
- Docker/OCI container isolation (local subprocess execution only for MVP).
- Full HTTP API and Web Dashboard.
- SSH-based remote worker execution.
- Complex multi-turn continuation logic (MVP will focus on single-turn per poll cycle).

---

## 2. 5-Day Implementation Schedule

### Day 1: Foundation & Configuration
- Initialize project (Node.js/TypeScript).
- Implement `WorkflowLoader` and `ConfigLayer`.
- Support YAML front matter parsing and `$VAR` environment expansion.
- Create CLI entry point to validate `WORKFLOW.md` and print effective config.

### Day 2: Linear Tracker & Workspace Management
- Implement `LinearClient` for candidate fetching and state refresh using GraphQL.
- Implement `WorkspaceManager` for directory lifecycle (sanitization, creation, and path safety).
- Implement `PromptRenderer` with support for `issue` and `attempt` template variables.

### Day 3: Agent Runner (Protocol Layer)
- Implement `AgentRunner` to launch and manage the `codex app-server` subprocess.
- Implement the JSON-RPC handshake (`initialize`, `thread/start`, `turn/start`).
- Implement streaming output parsing and event mapping from Codex to Symphony internal events.

### Day 4: Orchestration & Core Loop
- Implement the `Orchestrator` main loop (Poll -> Reconcile -> Dispatch).
- Implement in-memory state tracking for `claimed` and `running` issues.
- Implement basic concurrency limiting and retry scheduling with exponential backoff.

### Day 5: Validation & Refinement
- Implement structured logging for all state transitions and agent events.
- Final integration testing with a real Linear project and a mock/local `codex` instance.
- Document MVP usage, limitations, and the path to Phase 2 (Isolation, Dashboard).

---

## 3. Technical Stack
- **Language**: TypeScript (Node.js) for rapid development and strong typing.
- **Tracker**: `linear-sdk` or raw `graphql-request` for Linear integration.
- **Template**: `liquidjs` for prompt rendering.
- **Logging**: `pino` for high-performance structured logging.

---

## 4. Success Criteria
1. Symphony starts and loads a valid `WORKFLOW.md`.
2. It fetches an active issue from Linear and creates a local workspace.
3. it renders the prompt and successfully handshakes with `codex app-server`.
4. It completes a single turn, logs the outcome, and enters a retry/wait state.
5. It stops the session if the issue state changes to terminal in Linear.
