# Research: mise en place Integration with VS Code Devcontainers

## Problem

The project's devcontainer (`/.devcontainer/`) currently installs tools via npm and a
curl-based installer for Claude Code. The project's `mise.toml` is present at the repo
root but is not wired into the devcontainer. This research investigates how to add mise
and have it activate automatically — including in non-interactive shells — so that tools
declared in `mise.toml` are available immediately upon container start.

## Constraints

- Base image is `mcr.microsoft.com/devcontainers/base:ubuntu-24.04`.
- Remote user is `vscode`, whose home directory is `/home/vscode`.
- The devcontainer bind-mounts several host directories into `/home/vscode/` (`.claude`,
  `.codex`, `.gemini`, `.pi`, `.aws`, `.ssh`). This is the critical constraint: because
  the home directory is partially shadowed by mounts, mise's default tool install path
  (`~/.local/share/mise/installs`) may be hidden or inaccessible depending on how mounts
  land.
- PATH already includes `/home/vscode/.local/bin` and `/usr/local/bin` via a Dockerfile
  `ENV` statement.

## Affected Areas

- `/.devcontainer/Dockerfile` — where mise is installed and shell rc files are modified.
- `/.devcontainer/devcontainer.json` — where features, lifecycle hooks, `remoteEnv`, and
  volume mounts are declared.
- `/mise.toml` — the project-level tool configuration that mise will read.
- All AI agent CLIs running inside the container that need language runtimes or tools
  declared in `mise.toml`.

## Unknowns Resolved

### 1. Is there an official devcontainer feature for mise?

There is no official (Microsoft/devcontainers-org) feature for mise. The community
feature is:

```
ghcr.io/devcontainers-extra/features/mise:1
```

This feature is maintained in the `devcontainers-extra/features` repository (a community
fork of the formerly-active `devcontainers-contrib` project). It accepts one option:

| Option  | Type   | Default  | Purpose                        |
|---------|--------|----------|--------------------------------|
| version | string | `latest` | Pin a specific mise version    |

Usage in `devcontainer.json`:
```json
"features": {
  "ghcr.io/devcontainers-extra/features/mise:1": {}
}
```

Source: [devcontainers-extra/features/src/mise](https://github.com/devcontainers-extra/features/tree/main/src/mise)

Alternatively, mise publishes a first-party Docker image (`jdxcode/mise`) from which the
binary can be copied directly in a Dockerfile. This avoids the community feature
entirely:

```dockerfile
COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/
```

Source: [rezachegini.com — Mise and Dev Containers Simple Setup Guide](https://rezachegini.com/2025/10/14/mise-and-dev-containers-simple-setup-guide/)

mise also ships a first-party CLI command for generating a devcontainer config:
`mise generate devcontainer`. This command produces a `devcontainer.json` that references
the `ghcr.io/devcontainers-extra/features/mise:1` feature and the `hverlin.mise-vscode`
VS Code extension. Flags: `--image`, `--mount-mise-data`, `--name`, `--write`.

Source: [mise generate devcontainer — mise-en-place docs](https://mise.jdx.dev/cli/generate/devcontainer.html)

---

### 2. How does mise shell activation work in devcontainers (non-interactive shells, PATH setup)?

`mise activate` works by injecting a shell hook that fires when the shell prompt is
displayed. This means **it does not modify PATH in non-interactive shells** (scripts,
`postCreateCommand`, `onCreateCommand`, CI runners), because no prompt is ever shown.

Source: [mise FAQs — non-interactive shells](https://mise.jdx.dev/faq.html), [mise
Troubleshooting](https://mise.jdx.dev/troubleshooting.html)

There are three approaches for non-interactive contexts:

**A. Shims (recommended by mise for non-interactive use)**

Shims are small wrapper executables in a directory (e.g., `/home/vscode/.local/share/mise/shims`
or a custom path). Each shim inspects `$PWD` at execution time and routes the call to the
correct tool version. They work without a running shell hook.

To make shims available everywhere, add the shims directory to PATH either in the
Dockerfile `ENV` or in `devcontainer.json`'s `remoteEnv`:

```json
"remoteEnv": {
  "PATH": "${containerEnv:PATH}:/home/vscode/.local/share/mise/shims"
}
```

Or in the Dockerfile:
```dockerfile
ENV PATH="/home/vscode/.local/share/mise/shims:$PATH"
```

Source: [mise Shims docs](https://mise.jdx.dev/dev-tools/shims.html), [blog.ace-dev.me — How We Use Mise and DevContainers](https://blog.ace-dev.me/posts/2025/04/how-we-use-mise-at-work-part-2/)

**B. `eval "$(mise activate bash/zsh)"` in rc files**

For interactive terminal sessions inside the container, appending activation to `.bashrc`
and `.zshrc` gives the full hook-driven experience (automatic version switching as you
`cd` between projects). This should be done in the Dockerfile:

```dockerfile
RUN echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc \
 && echo 'eval "$(mise activate zsh)"'  >> /home/vscode/.zshrc
```

Source: [rezachegini.com — Mise and Dev Containers Simple Setup Guide](https://rezachegini.com/2025/10/14/mise-and-dev-containers-simple-setup-guide/)

**C. Explicit prefix: `mise exec --` / `mise x --`**

If only specific commands need mise-managed tools, prefix them:

```bash
mise x -- node --version
```

This is useful in `postCreateCommand` scripts where a full shell activation is
unnecessary.

Source: [mise FAQs](https://mise.jdx.dev/faq.html)

---

### 3. What is the recommended approach for mise.toml to work automatically in a devcontainer?

The full recommended pattern combines four elements:

**Step 1 — Install mise in the Dockerfile**

Either via the community feature, or by copying from the official image:

```dockerfile
COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/
```

**Step 2 — Add shims to PATH and activate in rc files**

```dockerfile
ENV MISE_DATA_DIR="/home/vscode/.local/share/mise"
ENV PATH="/home/vscode/.local/share/mise/shims:$PATH"

RUN echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc \
 && echo 'eval "$(mise activate zsh)"'  >> /home/vscode/.zshrc
```

Note: If using a custom `MISE_DATA_DIR` (e.g., a Docker volume path), the shims path
must match.

**Step 3 — Trust and install in postCreateCommand**

`mise trust` tells mise the `mise.toml` is safe to read (required since mise 2024
introduced trust checks). `mise install` downloads and installs all declared tools.

```json
"postCreateCommand": "mise trust --yes && mise install --yes"
```

Or with a script file for more complex setups:

```json
"postCreateCommand": "scripts/setup.sh"
```

Source: [sreake.com — Dev Container + mise template](https://sreake.com/en/blog/stop-worrying-about-ai-wrecking-your-code-a-template-for-unified-development-environments-using-dev-containers-and-mise/)

**Step 4 — Optionally add the VS Code extension**

```json
"customizations": {
  "vscode": {
    "extensions": ["hverlin.mise-vscode"]
  }
}
```

The `hverlin.mise-vscode` extension configures other VS Code extensions (Python, Node,
etc.) to use the mise-managed runtimes automatically, without requiring manual launch
configuration changes.

Source: [mise IDE Integration docs](https://mise.jdx.dev/ide-integration.html), [blog.ace-dev.me](https://blog.ace-dev.me/posts/2025/04/how-we-use-mise-at-work-part-2/)

---

### 4. Are there any known issues or gotchas with mise in devcontainers?

**Gotcha A — Home directory mount shadowing**

This is the most critical risk for this project. The devcontainer bind-mounts multiple
directories into `/home/vscode/`. If mise installs tools to
`~/.local/share/mise/installs` (the default), those tools will be inside the home
directory. A bind mount that lands at or above that path at container start will shadow
the pre-installed tools, making them disappear.

The official mise Docker cookbook explicitly addresses this:

> "Devcontainers often mount the user's home directory, which means
> `~/.local/share/mise/installs` comes from the mount rather than the Docker image."

The recommended fix is to set `MISE_DATA_DIR` to a path outside the home directory
(e.g., `/usr/local/share/mise`) and use `mise install --system`:

```dockerfile
ENV MISE_DATA_DIR="/usr/local/share/mise"
ENV PATH="/usr/local/share/mise/shims:$PATH"
```

Source: [mise Docker Cookbook](https://mise.jdx.dev/mise-cookbook/docker.html)

This project mounts `.claude`, `.codex`, `.gemini`, `.pi`, `.aws`, `.ssh` — these are
subdirectories of `/home/vscode/`, not the home root, so the default tool path
(`~/.local/share/mise`) is likely not shadowed. However, this should be verified.
(DECISION REQUIRED — see below.)

**Gotcha B — mise trust prompt blocks non-interactive runs**

Since a security update in 2024, mise will refuse to read `mise.toml` unless it has been
explicitly trusted. Running `mise install` in `postCreateCommand` without first running
`mise trust` will either fail silently or prompt interactively (which hangs). Always run:

```bash
mise trust --yes && mise install --yes
```

Source: [sreake.com](https://sreake.com/en/blog/stop-worrying-about-ai-wrecking-your-code-a-template-for-unified-development-environments-using-dev-containers-and-mise/)

**Gotcha C — Shims vs. activate for VS Code extension compatibility**

VS Code extensions (Python, ESLint, etc.) do not source `.bashrc` — they launch in a
non-interactive environment. If `mise activate` is only in `.bashrc`, those extensions
will not see mise-managed runtimes. The shims-in-PATH approach (via `remoteEnv` or
Dockerfile `ENV`) is required to make extensions work.

Source: [blog.ace-dev.me](https://blog.ace-dev.me/posts/2025/04/how-we-use-mise-at-work-part-2/), [mise IDE Integration docs](https://mise.jdx.dev/ide-integration.html)

**Gotcha D — Tool install timing vs. container lifecycle**

`postCreateCommand` runs once, after the container is created. If a user rebuilds the
container image without invalidating the layer cache, tools may not be reinstalled.
Pinning tool versions in `mise.toml` and using a volume for the mise data directory
prevents this from causing drift.

Source: [blog.ace-dev.me](https://blog.ace-dev.me/posts/2025/04/how-we-use-mise-at-work-part-2/)

**Gotcha E — Community feature maintenance risk**

`ghcr.io/devcontainers-extra/features/mise:1` is a community feature, not an
official Microsoft or mise-maintained artifact. The upstream `devcontainers-contrib`
project became inactive and was forked. The `COPY --from=jdxcode/mise` approach in the
Dockerfile is maintained by the mise team itself and is lower-risk.

Source: [GitHub — devcontainers-extra/features](https://github.com/devcontainers-extra/features)

## Risks Identified

1. **Home directory mount shadowing** — This project's devcontainer mounts several paths
   into `/home/vscode/`. If `MISE_DATA_DIR` is left at its default
   (`~/.local/share/mise`), there is a non-trivial risk that a future mount addition
   shadows installed tools. Setting `MISE_DATA_DIR` to a system path proactively
   eliminates the risk.

2. **mise.toml currently contains a credential** — The existing `mise.toml` at the repo
   root sets `LINEAR_API_KEY` in `[env]`. If `mise trust --yes` is run in
   `postCreateCommand`, that key will be loaded into the container environment
   automatically. This may be intentional but should be confirmed. If this key should not
   live in `mise.toml`, it should be moved to `containerEnv` in `devcontainer.json` or a
   secrets manager.

3. **Community feature supply chain** — The `devcontainers-extra/features/mise` feature
   runs a shell script from a community registry during container build. If that package
   is compromised or unpublished, the build breaks. The `COPY --from=jdxcode/mise`
   approach reduces the trust surface to the mise team's own Docker Hub image.

4. **Non-interactive shell PATH gaps** — If shims are not explicitly on PATH via `ENV`
   or `remoteEnv`, any tool invoked by a VS Code extension, `postCreateCommand` script,
   or agent process will not find mise-managed binaries.

## Suggested Directions

These are options for the implementer to choose between. No architectural decision is
made here.

**Option 1 — Dockerfile-only approach (lower external dependency)**

- Copy mise binary from `jdxcode/mise` image in the Dockerfile.
- Set `MISE_DATA_DIR` to `/usr/local/share/mise` (outside home, avoids shadowing).
- Add `/usr/local/share/mise/shims` to `PATH` in `ENV`.
- Append `eval "$(mise activate bash/zsh)"` to rc files in the Dockerfile.
- Add `mise trust --yes && mise install --yes` to `postCreateCommand`.
- Add `hverlin.mise-vscode` to VS Code extensions.

Trade-offs: No community feature dependency. Requires Dockerfile changes. mise version
is pinned by the `jdxcode/mise` tag used.

**Option 2 — Community feature approach (less Dockerfile complexity)**

- Add `ghcr.io/devcontainers-extra/features/mise:1` to the `features` block in
  `devcontainer.json`.
- Add `remoteEnv.PATH` to include the shims directory.
- Add `mise trust --yes && mise install --yes` to `postCreateCommand`.
- Add `hverlin.mise-vscode` to VS Code extensions.

Trade-offs: Minimal Dockerfile changes. Relies on community feature registry. Shell rc
activation still needs to be added manually (the feature only installs the binary).

**Option 3 — mise-generated config as starting point**

Run `mise generate devcontainer --write` on the host to produce a reference
`devcontainer.json`, then merge relevant sections (features, extensions, remoteEnv) into
the existing config.

Trade-offs: Quick starting point. The generated config assumes a fresh container and
may conflict with the existing Dockerfile structure and mounts.

**Decision required**: Whether to use Option 1 (Dockerfile copy) or Option 2 (community
feature). The primary technical consideration is supply-chain trust vs. config
simplicity.

**Decision required**: Whether to store `LINEAR_API_KEY` in `mise.toml [env]` or move
it to `devcontainer.json` `containerEnv` (sourced from host env) to separate credentials
from tool declarations.

## Sources

- [mise generate devcontainer — mise-en-place docs](https://mise.jdx.dev/cli/generate/devcontainer.html)
- [mise Shims — mise-en-place docs](https://mise.jdx.dev/dev-tools/shims.html)
- [mise IDE Integration — mise-en-place docs](https://mise.jdx.dev/ide-integration.html)
- [mise Docker Cookbook — mise-en-place docs](https://mise.jdx.dev/mise-cookbook/docker.html)
- [mise Troubleshooting — mise-en-place docs](https://mise.jdx.dev/troubleshooting.html)
- [mise FAQs — mise-en-place docs](https://mise.jdx.dev/faq.html)
- [mise activate — mise-en-place docs](https://mise.jdx.dev/cli/activate.html)
- [devcontainers-extra/features (GitHub)](https://github.com/devcontainers-extra/features)
- [devcontainers-extra/features/src/mise (GitHub)](https://github.com/devcontainers-extra/features/tree/main/src/mise)
- [How We Use Mise and DevContainers to Simplify Development — blog.ace-dev.me](https://blog.ace-dev.me/posts/2025/04/how-we-use-mise-at-work-part-2/)
- [Mise and Dev Containers Simple Setup Guide — rezachegini.com](https://rezachegini.com/2025/10/14/mise-and-dev-containers-simple-setup-guide/)
- [Dev Container + mise template — sreake.com](https://sreake.com/en/blog/stop-worrying-about-ai-wrecking-your-code-a-template-for-unified-development-environments-using-dev-containers-and-mise/)
- [2025 experimental features — jdx/mise GitHub Discussion #5085](https://github.com/jdx/mise/discussions/5085)
- [mise generate devcontainer source — jdx/mise GitHub](https://github.com/jdx/mise/blob/main/src/cli/generate/devcontainer.rs)
- [feat: add devcontainer generator PR #4355 — jdx/mise GitHub](https://github.com/jdx/mise/pull/4355)
