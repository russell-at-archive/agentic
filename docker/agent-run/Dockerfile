FROM ubuntu:24.04

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install agent CLIs globally via npm
RUN npm install -g \
    @google/gemini-cli \
    @openai/codex \
    @mariozechner/pi-coding-agent

# Create non-root user for security (FR-008)
RUN useradd -m -s /bin/bash -u 1000 agent

# Switch to non-root user and install Claude Code via native installer
USER agent

RUN curl -fsSL https://claude.ai/install.sh | bash

# Ensure npm global bin and agent user local bin are on PATH
ENV PATH="/home/agent/.local/bin:/usr/local/bin:$PATH"

WORKDIR /workspace
