FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Install Node.js LTS (required for gemini-cli and codex)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install remaining agentic CLI coding tools via npm
RUN npm install -g \
    @google/gemini-cli \
    @openai/codex \
    @mariozechner/pi-coding-agent

# Install Claude Code as vscode user (native installer writes to ~/.local/bin)
USER vscode

RUN curl -fsSL https://claude.ai/install.sh | bash

# Ensure npm global bin and vscode user local bin are on PATH
ENV PATH="/home/vscode/.local/bin:/usr/local/bin:$PATH"
