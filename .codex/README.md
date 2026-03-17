# Codex Multi-Agent Configuration

This repository now includes a Codex-oriented multi-agent team definition under
[`.codex/agents.toml`](./agents.toml) plus per-role prompt files in
[`.codex/agents/`](./agents/).

## What Is Checked In

- [`.codex/config.toml`](./config.toml): safe project-scoped Codex settings
  that only use documented keys and enable the experimental `multi_agent`
  feature
- [`.codex/agents.toml`](./agents.toml): repo-owned definition of the delivery
  team described in [docs/agentic-team.md](../docs/agentic-team.md)
- [`.codex/agents/director.md`](./agents/director.md)
- [`.codex/agents/feature-draft.md`](./agents/feature-draft.md)
- [`.codex/agents/architect.md`](./agents/architect.md)
- [`.codex/agents/coordinator.md`](./agents/coordinator.md)
- [`.codex/agents/engineer.md`](./agents/engineer.md)
- [`.codex/agents/technical-lead.md`](./agents/technical-lead.md)
- [`.codex/agents/explorer.md`](./agents/explorer.md)

## Important Constraint

Codex multi-agent support is still marked experimental in the local Codex
documentation available in this environment, and that documentation does not
fully specify a stable project-level agent schema. Because of that:

- [`.codex/config.toml`](./config.toml) contains only documented Codex settings
- [`.codex/agents.toml`](./agents.toml) is treated as the repo source of truth
  for team structure and prompt mapping
- runtime wiring from Codex into this team definition should be handled by a
  thin loader or orchestration layer once the target Codex schema is confirmed

## Team Mapping

The checked-in configuration maps the team document to seven Codex roles:

- Feature Draft Agent
- Director
- Architect
- Coordinator
- Engineer
- Technical Lead
- Explorer

This matches the roster and state machine in
[docs/agentic-team.md](../docs/agentic-team.md) and preserves the document's
constraints around state-driven dispatch, human plan review, compliance gates,
ADRs, and blocked-on-ambiguity behavior. The one explicit exception is the
Feature Draft Agent, which is human-invoked and creates the first `Draft`
issue before Director dispatch begins.

## Intentional Non-Decisions

This configuration does not resolve open architectural questions that the team
document leaves open, including:

- final Codex-native runtime schema for agent loading
- Director polling versus webhook invocation
- authentication and secrets management
- AWS ownership and operational scope
- lock implementation details beyond the documented contract

Those remain subject to the ADR and open-question process already documented in
[docs/agentic-team.md](../docs/agentic-team.md) and
[docs/open-questions.md](../docs/open-questions.md).
