# ADR-002: Host Bind Mounts for Agent Authentication and Session State

**Status**: Proposed
**Date**: 2026-03-18
**Linear Issue**: INFRA-1813

## Context

Agent CLIs (Claude Code, Codex, Gemini CLI, PI agent) store authentication
tokens, session state, and configuration in user home directory paths on the
host:

- `~/.claude/` and `~/.claude.json` (Claude Code OAuth tokens and config)
- `~/.codex/` (Codex configuration)
- `~/.gemini/` (Gemini CLI configuration)
- `~/.pi/` (PI agent configuration)
- `~/.aws/` (AWS credentials used by some agent operations)
- `~/.ssh/` (SSH keys for git operations)
- `~/.agents/` (shared agent configuration)

When these CLIs run inside a Docker container (per ADR-001), they need access
to this state to authenticate without interactive login prompts.

The existing devcontainer configuration in `.devcontainer/devcontainer.json`
already establishes the pattern of bind-mounting these directories. This ADR
formalizes the same approach for the isolated agent runtime.

## Decision

Use Docker bind mounts to map host-side authentication and session directories
into the agent runtime container. Additionally, forward API key environment
variables (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`) from the
host environment into the container.

Specific mount rules:

- `~/.ssh` is mounted as **readonly** to prevent the container from modifying
  SSH keys.
- All other directories are mounted read-write so CLIs can update their own
  session state (e.g., token refresh).
- `~/.claude.json` is a single file mount (not a directory).
- Mounts for directories that do not exist on the host are skipped with a
  warning rather than causing a hard failure.

Claude Code on macOS stores OAuth credentials in the system Keychain, which is
not accessible from a Linux container. The existing `bin/claude-keychain-export`
script extracts these credentials to `~/.claude/.credentials.json`, which the
bind mount then makes available inside the container.

## Consequences

### Positive

- No re-authentication required inside the container.
- Matches the established pattern in `.devcontainer/devcontainer.json`.
- Simple to implement and understand.
- Supports the immediate bootstrap need without introducing new secrets
  infrastructure.

### Negative

- Tight coupling between container and host filesystem layout. If a CLI changes
  its config directory location, both the host and the mount configuration must
  be updated.
- Read-write mounts (except `~/.ssh`) mean the container can mutate host auth
  state. A misbehaving agent process could corrupt credentials.
- The `claude-keychain-export` step is a manual prerequisite on macOS. Forgetting
  it results in a confusing auth failure inside the container.
- This approach does not scale to multi-host or CI environments where host home
  directories are not available.

### Neutral

- This is explicitly documented as the bootstrap approach, not the long-term
  steady-state design. A future ADR may introduce a secrets management solution
  (e.g., Vault, cloud secrets manager) that replaces bind mounts for
  credential distribution.

## Alternatives Considered

1. **Copy credentials into the image at build time**: Rejected because it bakes
   secrets into the image layer, creating a security risk if the image is shared
   or pushed to a registry.

2. **Use Docker secrets**: Rejected because Docker secrets require Swarm mode
   or Compose, which adds orchestration complexity beyond the scope of ADR-001's
   single-container model.

3. **Use environment variables for all auth**: Rejected because most agent CLIs
   use file-based session state that cannot be fully represented as environment
   variables. API keys are forwarded as env vars where applicable, but file-based
   state requires bind mounts.

4. **Mount everything as readonly**: Rejected because several CLIs write session
   updates (token refresh, cache files) to their config directories. Readonly
   mounts would break these flows.
