# syntax=docker/dockerfile:1.7

FROM ubuntu:24.04

ARG CODEX_VERSION=0.115.0
ARG GRAPHITE_VERSION=1.7.17
ARG LINEAR_VERSION=1.11.1

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      fd-find \
      gh \
      git \
      git-lfs \
      jq \
      libatomic1 \
      nodejs \
      npm \
      openssh-client \
      python3 \
      ripgrep \
      tini \
      yq \
      xz-utils && \
    ln -sf /usr/bin/fdfind /usr/local/bin/fd && \
    npm install -g "@openai/codex@${CODEX_VERSION}" "@schpet/linear-cli@${LINEAR_VERSION}" "@withgraphite/graphite-cli@${GRAPHITE_VERSION}" && \
    npm cache clean --force && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash agent && \
    mkdir -p /workspace && \
    chown -R agent:agent /workspace /home/agent

ENV HOME=/home/agent \
    PATH=/home/agent/.local/bin:${PATH}

USER agent

RUN curl -fsSL https://claude.ai/install.sh | bash

COPY --chmod=0755 entrypoint.sh /usr/local/bin/agent-runner-entrypoint

WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/agent-runner-entrypoint"]
CMD ["--help"]
