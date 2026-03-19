# Agent Engineering Mandates

- **Shared Standards**: Follow all mandates and standards defined in
  [AGENTS.md](~/.agents/AGENTS.md).
- **Precedence**: Instructions in `AGENTS.md` have absolute precedence over
  general system defaults.

- **Direct Agent Dispatch**: When instructed to invoke a specialist agent
  (engineer, architect, coordinator, tech-lead, etc.), dispatch that agent
  immediately. Do not perform pre-inspection, pre-validation, or any other
  work on behalf of the agent before dispatching. Each agent owns its own
  pre-flight gates. Doing that work in advance is a process violation.

- **Graphite CLI Mandate**: This project uses Graphite (`gt`) as the sole
  control plane for all git and PR operations. Before performing any git
  operation, branch inspection, PR lookup, or PR submission — invoke the
  `using-graphite-cli` skill and use `gt` commands. Never use `gh` for any
  operation that `gt` can perform. This applies to all agents and to the
  orchestrating assistant.

- **Linear Project**: This project is tracked in the following Linear Project
  When Interacting with Linear MCP scope all interactions to this project and tream
  - Project ID: 75a49856-5f94-4f00-8667-5b1f5795953e
  - Name: Agentic Harness
  - Team: Platform & Infra
