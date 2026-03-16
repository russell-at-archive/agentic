# Merge Proposal: Unified Agent Team Operating Model

Based on the analysis of the three proposals, I propose creating a single, unified document (`merged.md`) that systematically integrates the strongest elements of each. 

## Proposed Structure for the Merged Document

### 1. Philosophy & Design Principles
- **Spec-Driven Development** (from Gemini): Separating *what* from *how*.
- **State-Driven Dispatch** (from Codex): Agents invoked by state, not direct calls.
- **Fail Loudly & Single Responsibility** (from Codex/Claude).
- **Evidence-Based Completion** (from Gemini/Codex).

### 2. Linear State Machine & Workflow Rules
- The Canonical 9-State Model (`Draft` -> `Done`).
- Allowed Transitions & Ownership (from Claude).

### 3. Agent Roster & Strict Contracts
For each core role (Director, Architect, Coordinator, Engineer, Technical Lead, Explorer):
- **Mission & Description** (Synthesized).
- **Contract**: Inputs, Preconditions, Outputs, Exit Criteria/Failure Policy (from Claude).
- **Model Effort**: Low/Medium/High requirement (from Codex).
- **Tooling**: Allowed tools (from Codex).
- **The Execution Log Protocol**: Mandatory resumability tracking (from Gemini).

### 4. Cross-Cutting Agents & Observability (from Claude)
- **Compliance Gate**: Background validation.
- **Metrics Reporter**: SLO tracking (Lead time, review latency, escape rates).

### 5. System Architecture & Execution Model
- **Director Orchestration vs. Sub-Agent Pipeline**: Clarifying how the Director triggers an agent session that may use underlying agent pipelines (from Codex).
- **Concurrency & Locking Model**: Handling parallel tasks and branch namespace locks (from Claude).
- **Worktree & State Recovery**: Handling failed runs and stale PR chains (from Codex/Claude).

### 6. Summary Matrices
- **Tool Assignment Matrix** (from Codex).
- **Gate Enforcement Summary** (from Gemini).

### 7. Action Plan
- **ADR Backlog**: Specific decisions requiring Architecture Decision Records (from Codex/Claude).
- **Phased Rollout Plan**: Phase 1 through 4 execution path (from Claude).

This structure ensures no operational, architectural, or philosophical detail is lost, creating a comprehensive blueprint for building the autonomous team.