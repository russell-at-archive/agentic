# MVP Analysis Report: Agentic Execution Substrate

This report analyzes and compares the three MVP proposals for the ArchiveResale Agentic Harness execution substrate. All three proposals aim to reduce the enterprise-scale architecture (Kubernetes, NATS, PostgreSQL) into a local-first MVP that can be built by a single human in a few days.

## 1. Summary of Proposals

| Feature | Claude Proposal | Codex Proposal | Gemini Proposal |
| --- | --- | --- | --- |
| **Core Concept** | Local Docker Orchestrator | Local Docker Agent Runner | Speckit Local Docker Runner (SLDR) |
| **Orchestrator** | Python process (CLI) | Local command / tiny API | Python CLI tool (`sldr.py`) |
| **State Store** | SQLite | SQLite | Local Git + Filesystem (No DB) |
| **Isolation** | Standard Docker | Standard Docker | Docker + `--network none` + Cap-drop |
| **Integration** | Direct GitHub API calls | Optional GitHub write-back | Host-side `gh`/`gt` CLI usage |
| **Artifacts** | Local `runs/` directory | Local `./data/runs/` | Local `specs/` directory |

---

## 2. Comparative Analysis

### 2.1 Technical Approach & Persistence

- **Claude & Codex** both suggest using **SQLite** to manage run metadata, history, and status. This provides a structured way to query past runs.
- **Gemini** takes a "minimalist" approach, using the **local Git repository and filesystem** as the state store. It relies on Git branches and the existence of files in `specs/` to track progress, which avoids the overhead of managing a database file but may make cross-run reporting more difficult.

### 2.2 Security & Isolation

- **Gemini** emphasizes **hardened isolation** even in the MVP, suggesting `--network none` for implementation tasks and `--cap-drop=ALL`.
- **Claude & Codex** treat isolation as "Standard Docker," focusing more on the functional loop than the security sandbox in the initial few days.

### 2.3 Integration with Existing "Speckit" Process

- **Gemini** is the most tightly coupled with the existing **"Speckit" methodology** (Specify -> Plan -> Tasks). It focuses on automating the transitions between these specific Markdown artifacts.
- **Claude & Codex** provide a more general-purpose "Agent Runner" that could theoretically execute any task, though they both mention reading `tasks.md` and `plan.md`.

### 2.4 GitHub & External Tooling

- **Claude** proposes direct **GitHub API** integration for label updates and PR comments from the orchestrator.
- **Gemini** proposes using the **host's existing CLI tools** (`gh`, `gt`) for external actions. This is arguably easier to build in 3 days as it avoids authentication complexity within the Python script itself.
- **Codex** makes GitHub integration optional for the MVP (Day 4).

---

## 3. Strengths and Weaknesses

### Claude Proposal

- **Strength**: Most "feature-complete" for a CLI tool (SQLite, Log Tailing, GitHub Labels).
- **Weakness**: Slightly higher implementation complexity (SQLite + API integrations) for a 3-day target.

### Codex Proposal

- **Strength**: Strongest focus on "answering questions" and validating the product hypothesis.
- **Weakness**: Less specific about the implementation details of the agent's interaction with the repo (entrypoint logic).

### Gemini Proposal (SLDR)

- **Strength**: Extremely lightweight (no DB) and focuses on the "Local Dev" experience (using host CLIs). High focus on security defaults.
- **Weakness**: Lack of a central run database makes it harder to build a "dashboard" or audit view later.

---

## 4. Synthesis & Recommendation

The ideal MVP should likely be a **hybrid** of these three:

1. **Orchestrator**: Use a **Python CLI** (Gemini/Claude) for flexibility.
2. **State Store**: Start with **Git/Filesystem** (Gemini) for the first 2 days to get the loop working, but add **SQLite** (Claude/Codex) on Day 3 for history and logs.
3. **Isolation**: Use **Docker with `--network none`** (Gemini) by default to enforce the "autonomous but safe" principle.
4. **Integration**: Use **host-side CLIs (`gh`, `gt`)** (Gemini) for the MVP to minimize API credential management, but structure the code so it can move to the **GitHub Integration Service** (Full Architecture) later.

**Final Recommendation**: Proceed with the **SLDR (Gemini)** approach but adopt the **SQLite schema (Claude)** as an enhancement for tracking run history.
