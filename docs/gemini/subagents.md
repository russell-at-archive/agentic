# Gemini CLI Sub-Agents

This document provides a technical overview of **Sub-Agents** within the Gemini CLI. It defines their architecture, configuration, and management without project-specific context.

## Overview

Sub-agents are specialized "expert" personas that operate as **tools** available to the main Gemini CLI session. Instead of the main agent attempting to handle every task directly, it can delegate complex or specialized work—such as deep codebase analysis, security auditing, or web research—to these sub-agents.

### Key Characteristics

- **Independent Context**: Each sub-agent operates with its own system prompt and context window. This keeps the main session's token count low and prevents the main agent's history from becoming cluttered with technical details.
- **Specialized Toolsets**: Sub-agents can be granted restricted or unique sets of tools (e.g., `read_file`, `run_shell_command`, `web_search`) tailored to their specific mission.
- **Reporting**: When a sub-agent completes a task, it returns a structured summary of its findings or actions to the main agent, which then continues the session.
- **YOLO Mode**: By default, sub-agents may execute tools without individual user confirmation for each step, enabling fully autonomous execution of specialized tasks.

## Defining Sub-Agents

Sub-agents are defined as Markdown files with YAML frontmatter. These files are typically stored in the project's `.gemini/agents/` directory.

### Structure

A sub-agent definition consists of two parts:

1. **Frontmatter**: Defines metadata, tool access, and model selection.
2. **Body**: The system prompt that defines the agent's persona, mission, and instructions.

### Frontmatter Parameters

```yaml
---
name: analyst                 # Unique identifier for the agent
description: Expert in code   # Short description shown in logs
kind: local                   # 'local' for project-defined agents
tools: [read_file, glob]      # Tools this agent is allowed to use
model: gemini-2.0-flash-exp   # The model used for this specific agent
---
```

### Example Definition

```markdown
---
name: codebase_investigator
description: Analyzes codebase patterns and architecture.
kind: local
tools: [grep_search, glob, read_file]
model: gemini-2.0-pro-exp-02-05
---

# Codebase Investigator

You are an expert software architect. Your mission is to reverse-engineer 
codebase patterns and identify structural dependencies.

## Instructions
1. Map the directory structure using `glob`.
2. Identify core abstractions using `grep_search`.
3. Report back with a high-level architectural map.
```

## Sub-Agent Management

The Gemini CLI provides internal commands to manage the registry of available sub-agents.

| Command | Description |
| --- | --- |
| `/agents list` | Lists all registered sub-agents and their status. |
| `/agents refresh` | Scans `.gemini/agents/` and reloads definitions. |
| `/agents enable <name>` | Enables a specific agent for the session. |
| `/agents disable <name>` | Disables a specific agent for the session. |

## Configuration

Sub-agents are currently an experimental feature and must be explicitly enabled in your Gemini CLI `settings.json` or `config.toml`:

```json
{
  "experimental": {
    "enableAgents": true
  }
}
```

## Built-in Agents

The Gemini CLI includes several pre-configured "Internal" sub-agents:

- **`codebase_investigator`**: Optimized for deep codebase mapping and analysis.
- **`cli_help`**: An expert on Gemini CLI documentation and commands.
- **`generalist`**: A routing specialist used to dispatch tasks to other agents.

## Best Practices

- **Narrow Missions**: Give sub-agents highly specific goals to minimize their context usage and increase reliability.
- **Scoped Tools**: Only grant the tools necessary for the sub-agent's role to prevent unexpected side effects.
- **Clear Reporting**: Instruction sub-agents to provide concise, high-signal summaries back to the main session.
- **Model Selection**: Use smaller/faster models (like Flash) for simple research tasks and larger models (like Pro) for complex architectural analysis.
