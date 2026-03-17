# Claude Code Sub-Agents

Sub-agents are specialized AI assistants that run in isolated context windows
with custom system prompts, restricted tool access, and independent permissions.
Claude delegates tasks to sub-agents automatically when a task matches an
agent's description, or explicitly when instructed.

## Core Concepts

- Each sub-agent runs in its own context window (fresh conversation per call)
- Only the final message from the sub-agent returns to the parent
- Intermediate tool results and context stay isolated in the sub-agent
- Sub-agents inherit parent permissions but can be further restricted
- Sub-agents **cannot** spawn other sub-agents (no nesting)

## Defining Agents

### File-Based (Recommended)

Create a markdown file with YAML frontmatter in one of:

| Location | Scope | Priority |
| --- | --- | --- |
| `--agents` CLI flag | Current session only | 1 (highest) |
| `.claude/agents/<name>.md` | Current project | 2 |
| `~/.claude/agents/<name>.md` | All projects (user) | 3 |
| Plugin `agents/<name>.md` | Where plugin enabled | 4 (lowest) |

```markdown
---
name: code-reviewer
description: Expert code reviewer. Use proactively for security and quality reviews.
tools: Read, Grep, Glob
model: sonnet
---

You are a senior code reviewer...
```

### Frontmatter Fields

| Field | Required | Description |
| --- | --- | --- |
| `name` | Yes | Unique identifier (lowercase, hyphens) |
| `description` | Yes | When Claude should delegate to this agent |
| `tools` | No | Allowed tools; inherits all if omitted |
| `disallowedTools` | No | Tools to remove from inherited set |
| `model` | No | `sonnet`, `opus`, `haiku`, or full model ID |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | No | Maximum agentic turns before stopping |
| `isolation` | No | `worktree` for isolated git worktree |
| `background` | No | Always run as background task |
| `skills` | No | Skill names to preload into agent context |
| `mcpServers` | No | MCP servers scoped to this agent |
| `hooks` | No | Lifecycle hooks (`PreToolUse`, `PostToolUse`) |
| `memory` | No | Persistent memory scope: `user`, `project`, `local` |

> **Plugin agents** cannot use `hooks`, `mcpServers`, or `permissionMode`.
> Copy to `.claude/agents/` if you need those fields.

## Built-In Agent Types

| Agent | Model | Tools | Purpose |
| --- | --- | --- | --- |
| `general-purpose` | Inherits | All | Complex multi-step tasks requiring exploration and action |
| `Explore` | Haiku | Read, Grep, Glob, Bash (no Write/Edit) | Fast codebase exploration |
| `Plan` | Inherits | Read-only | Research during plan mode |

## Invocation

### Automatic

Claude matches the task against each agent's `description` field. Use specific,
action-oriented language in descriptions to maximize automatic delegation:

```
# Weak — unlikely to trigger automatic delegation
description: code reviewer

# Strong — triggers delegation reliably
description: Expert code reviewer. Use proactively when code is changed or added.
```

### Explicit

```text
Use the code-reviewer agent to check the auth module.
Have the debugger subagent investigate why users can't log in.
```

### Agent Tool Parameters

When Claude invokes a sub-agent via the Agent tool:

| Parameter | Description |
| --- | --- |
| `subagent_type` | Name of the agent to invoke |
| `prompt` | Task-specific prompt (include all needed context) |
| `description` | Brief 3–5 word label shown in the UI |
| `model` | Optional per-call model override |
| `isolation` | `worktree` for an isolated git directory |
| `run_in_background` | `true` to run concurrently |

## Communication Model

Communication is strictly one-way:

```
Parent → Agent tool prompt → Sub-agent context
Sub-agent final message → Parent conversation
```

Sub-agents receive:

- Their own system prompt
- The Agent tool's prompt
- Project `CLAUDE.md`
- Tool definitions
- Working directory

Sub-agents do **not** receive:

- Parent conversation history
- Parent tool results
- Other agent definitions
- Skills (unless listed in `skills` frontmatter)

### Implications

- Include all necessary context in the prompt (file paths, error messages, etc.)
- Ask sub-agents to summarize before returning to keep parent context lean
- Chain sub-agents from the main conversation; they cannot chain themselves

## Background vs Foreground

### Foreground (default)

- Blocks main conversation until complete
- Permission prompts pass through to the user
- User can interrupt with `Ctrl+C`
- Use when the result is needed before proceeding

### Background

- Runs concurrently while user continues working
- Requires permissions pre-approved upfront
- Unpre-approved tool calls are auto-denied (agent continues)
- Use for independent research, parallel analysis, long-running tasks

Trigger background mode:

- Say "run this in the background"
- Press `Ctrl+B` during execution
- Set `background: true` in frontmatter

## Worktree Isolation

Set `isolation: worktree` in frontmatter (or the Agent tool call) to run the
sub-agent in a temporary git worktree:

- Created at `.claude/worktrees/<name>/`
- Branches from default remote
- Auto-cleaned if no commits are made; preserved if commits exist
- Enables safe parallel agents that modify files without conflicting

Add `.claude/worktrees/` to `.gitignore`.

## Tool Access

### Allowlist

```yaml
tools: Read, Grep, Glob
```

Only these tools are available; Agent tool is excluded by default.

### Denylist

```yaml
disallowedTools: Write, Edit
```

Remove specific tools from the inherited set.

### Restrict Sub-agent Spawning

```yaml
tools: Agent(worker, researcher), Read, Bash
```

Only the named sub-agents can be spawned from this agent.

## Persistent Memory

Set `memory` to build knowledge across conversations:

```yaml
memory: user    # personal, cross-project
memory: project # shared with team, project-scoped
memory: local   # local machine only
```

The agent maintains a `MEMORY.md` index and per-topic memory files.

## Discovery and Management

```bash
# List all available agents
claude agents

# Interactive agent management
/agents
```

The `/agents` command allows creating, editing, and deleting agents. Agents
defined in `.claude/agents/` should be committed to version control so the
whole team can use and improve them.

## Patterns

### Isolate High-Volume Output

```text
Use a sub-agent to run the full test suite and report only failing tests.
```

Prevents verbose output from consuming main context.

### Parallel Research

```text
Research the auth, database, and API modules in parallel using separate sub-agents.
```

Each explores independently; Claude synthesizes the findings.

### Chain Specialists

```text
Use the code-reviewer to find issues, then use the optimizer to fix them.
```

Each agent stays focused; the main conversation routes between them.

## Limitations

| Limitation | Detail |
| --- | --- |
| No nesting | Sub-agents cannot spawn sub-agents |
| One-way communication | Only prompt in, final message out |
| Fresh context | Each invocation starts with a new context window |
| Windows CLI limit | Prompts over 8191 chars may fail on Windows |
| Plugin restrictions | Plugin agents cannot use `hooks`, `mcpServers`, `permissionMode` |

## Related Documents

- [agent-invocation.md](agent-invocation.md) — project-specific agent roster and dispatch rules
