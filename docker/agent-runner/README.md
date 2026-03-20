# Agent Runner Container

This image is an ephemeral agent task runner. It shallow-clones a repository,
runs the selected CLI inside the cloned checkout, and then exits.

It is intentionally not a devcontainer and does not mount your existing
working tree.

## Included Software

Pinned to the versions observed locally on `2026-03-19`:

| Tool | Version |
| --- | --- |
| `codex` | `0.115.0` |
| `claude` | installer-managed |
| `gt` | `1.7.17` |
| `gh` | Ubuntu package |
| `linear` | `1.11.1` |

Supporting tools:

- `git`
- `git-lfs`
- `jq`
- `nodejs`
- `npm`
- `python3`
- `rg`
- `fd`
- `ssh`
- `yq`

## Build

```bash
docker build -t agent-runner docker/agent-runner
```

## Usage

The image entrypoint expects an SSH repository URL and then a command after
`--`. Clone settings are configured with environment variables rather than
entrypoint flags.

```bash
docker run --rm \
  -v "$HOME/.codex:/home/agent/.codex" \
  -v "$HOME/.ssh:/home/agent/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/agent/.gitconfig:ro" \
  -e BASE_BRANCH=main \
  -e CLONE_DEPTH=1 \
  agent-runner \
  git@github.com:acme/project.git \
  -- \
  codex --dangerously-bypass-approvals-and-sandbox exec -C . "Summarize the current repository."
```

Claude example:

```bash
docker run --rm \
  -v "$HOME/.claude:/home/agent/.claude" \
  -v "$HOME/.claude.json:/home/agent/.claude.json" \
  -v "$HOME/.ssh:/home/agent/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/agent/.gitconfig:ro" \
  -e BASE_BRANCH=main \
  -e CLONE_DEPTH=1 \
  agent-runner \
  git@github.com:acme/project.git \
  -- \
  claude --dangerously-skip-permissions -p "Summarize the current repository."
```

If you are already inside a local clone and want the container to use that
repository's SSH `origin` remote automatically, use the wrapper script:

```bash
AE_PROMPT="Summarize the current repository" scripts/agent-exec
```

To select Claude:

```bash
AE_TOOL=claude AE_PROMPT="Summarize the current repository" \
  scripts/agent-exec
```

For raw Codex arguments, pass them after `--`:

```bash
scripts/agent-exec -- \
  -s danger-full-access -a never exec -C . "Fix the failing test"
```

In prompt mode, `agent-exec` uses
`codex --dangerously-bypass-approvals-and-sandbox exec -C .` because Docker is
the intended isolation boundary for this POC.

The wrapper:

- reads `git remote get-url origin` from the local repo
- requires the origin remote to use SSH
- mounts the selected tool's host state paths
- passes `GITHUB_TOKEN` through when set on the host
- mounts `~/.ssh` read-only for SSH clone access
- mounts `~/.gitconfig` and detected include paths read-only for Git identity
- mounts `~/.config/graphite` read-write for Graphite CLI auth and aliases
- uses `AE_*` environment variables for image and clone settings

Current tool mounts:

- `codex`: `~/.codex`
- `claude`: `~/.claude`, `~/.claude.json`
- `gt`: `~/.config/graphite`
- `gh`: `~/.config/gh`
- `linear`: `~/.config/linear`

GitHub CLI note:

- macOS `gh auth login` may rely on the system keychain, which is not available
  inside the Linux container.
- For portable container auth, prefer exporting `GITHUB_TOKEN` on the host
  before invoking `agent-exec` or `test-agent-exec`.

## Entry Point Interface

```text
agent-runner-entrypoint <repo-url> -- <command> [args...]
```

Environment:

- `BASE_BRANCH`: clone branch. Default: `main`.
- `CLONE_DEPTH`: shallow clone depth. Default: `1`.
- `CLONE_DIR`: checkout path. Default: `/workspace/<repo>`.
- `WORK_BRANCH`: optional branch to create after cloning.

## Design Constraints

- The image uses Ubuntu 24.04 as the base image.
- The image is provisioned during `docker build`, not at task runtime.
- The working tree is always disposable.
- The container only clones the target branch with a shallow history by
  default.
- The entrypoint exits with the invoked command's exit code.
