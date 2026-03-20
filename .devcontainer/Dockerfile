FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/nodesource.gpg] \
      https://deb.nodesource.com/node_22.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y \
    nodejs \
    gh \
    jq \
    yq \
    && npm install -g \
    @openai/codex \
    @devcontainers/cli \
    @google/gemini-cli \
    @withgraphite/graphite-cli \
    @schpet/linear-cli \
    @mariozechner/pi-coding-agent \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && npm cache clean --force

# Welcome banner via MOTD
COPY motd /etc/motd
RUN echo '[ -r /etc/motd ] && cat /etc/motd' >> /etc/bash.bashrc

# Install Claude Code as vscode user (native installer writes to ~/.local/bin)
USER vscode

RUN curl -fsSL https://claude.ai/install.sh | bash

# Ensure npm global bin and vscode user local bin are on PATH
ENV PATH="/home/vscode/.local/bin:/usr/local/bin:$PATH"
