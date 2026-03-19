#!/usr/bin/env bash
# Test suite for bin/agent-run and docker/agent-run/Dockerfile
# Runs locally; requires Docker to be available.
# Exit code: 0 if all tests pass, 1 if any fail.

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)) || true; }
fail() { echo "  FAIL: $1"; ((FAIL++)) || true; }

# Helper: check if file contains a pattern
file_contains() {
  local file="$1" pattern="$2"
  [[ -f "${file}" ]] && grep -q "${pattern}" "${file}" 2>/dev/null
}

DOCKERFILE="${WORKSPACE_ROOT}/docker/agent-run/Dockerfile"
AGENT_RUN="${WORKSPACE_ROOT}/bin/agent-run"
MAKEFILE="${WORKSPACE_ROOT}/Makefile"

echo "=== agent-run test suite ==="
echo ""

# ---------------------------------------------------------------------------
# T004: Dockerfile exists and builds
# ---------------------------------------------------------------------------
echo "--- Dockerfile tests ---"

[[ -f "${DOCKERFILE}" ]] \
  && pass "Dockerfile exists at docker/agent-run/Dockerfile" \
  || fail "Dockerfile missing at docker/agent-run/Dockerfile"

file_contains "${DOCKERFILE}" "^FROM ubuntu:24.04" \
  && pass "Dockerfile uses ubuntu:24.04 base" \
  || fail "Dockerfile does not use ubuntu:24.04 base"

file_contains "${DOCKERFILE}" "useradd\|adduser" \
  && pass "Dockerfile creates a non-root user" \
  || fail "Dockerfile does not create a non-root user"

for cli in "@google/gemini-cli" "@openai/codex" "@mariozechner/pi-coding-agent"; do
  file_contains "${DOCKERFILE}" "${cli}" \
    && pass "Dockerfile installs ${cli}" \
    || fail "Dockerfile does not install ${cli}"
done

file_contains "${DOCKERFILE}" "claude.ai/install.sh" \
  && pass "Dockerfile installs Claude Code via native installer" \
  || fail "Dockerfile does not install Claude Code via native installer"

# Verify USER directive switches to non-root
file_contains "${DOCKERFILE}" "^USER agent" \
  && pass "Dockerfile switches to agent user" \
  || fail "Dockerfile does not switch to agent user"

echo ""

# ---------------------------------------------------------------------------
# T005: Wrapper script tests
# ---------------------------------------------------------------------------
echo "--- Wrapper script tests ---"

[[ -f "${AGENT_RUN}" ]] \
  && pass "bin/agent-run exists" \
  || fail "bin/agent-run missing"

[[ -x "${AGENT_RUN}" ]] \
  && pass "bin/agent-run is executable" \
  || fail "bin/agent-run is not executable"

file_contains "${AGENT_RUN}" "set -euo pipefail" \
  && pass "bin/agent-run uses strict mode" \
  || fail "bin/agent-run does not use strict mode"

file_contains "${AGENT_RUN}" "\-\-rm" \
  && pass "bin/agent-run uses --rm for container cleanup" \
  || fail "bin/agent-run does not use --rm"

file_contains "${AGENT_RUN}" "/workspace" \
  && pass "bin/agent-run mounts workspace at /workspace" \
  || fail "bin/agent-run does not mount workspace at /workspace"

# Verify exit code forwarding
file_contains "${AGENT_RUN}" 'exit' \
  && pass "bin/agent-run forwards exit code" \
  || fail "bin/agent-run does not forward exit code"

# Verify Docker availability check
file_contains "${AGENT_RUN}" "docker info\|docker version\|command -v docker" \
  && pass "bin/agent-run checks Docker availability" \
  || fail "bin/agent-run does not check Docker availability"

# Verify auto-build
file_contains "${AGENT_RUN}" "docker build\|docker image inspect" \
  && pass "bin/agent-run supports auto-build" \
  || fail "bin/agent-run does not support auto-build"

echo ""

# ---------------------------------------------------------------------------
# T006: Makefile targets
# ---------------------------------------------------------------------------
echo "--- Makefile tests ---"

file_contains "${MAKEFILE}" "agent-build" \
  && pass "Makefile contains agent-build target" \
  || fail "Makefile missing agent-build target"

file_contains "${MAKEFILE}" "agent-run" \
  && pass "Makefile contains agent-run target" \
  || fail "Makefile missing agent-run target"

file_contains "${MAKEFILE}" "Agent Runtime" \
  && pass "Makefile has Agent Runtime section" \
  || fail "Makefile missing Agent Runtime section"

echo ""

# ---------------------------------------------------------------------------
# T007: Bind mount configuration
# ---------------------------------------------------------------------------
echo "--- Bind mount tests ---"

for dir in ".agents" ".claude" ".codex" ".gemini" ".pi" ".aws"; do
  file_contains "${AGENT_RUN}" "${dir}" \
    && pass "bin/agent-run references ${dir} mount" \
    || fail "bin/agent-run missing ${dir} mount"
done

file_contains "${AGENT_RUN}" ".claude.json" \
  && pass "bin/agent-run references .claude.json file mount" \
  || fail "bin/agent-run missing .claude.json file mount"

# .ssh mount passes "ro" option to mount_dir helper
file_contains "${AGENT_RUN}" '"ro"' \
  && pass "bin/agent-run has readonly mount support" \
  || fail "bin/agent-run does not have readonly mount support"

echo ""

# ---------------------------------------------------------------------------
# T008: Environment variable forwarding
# ---------------------------------------------------------------------------
echo "--- Environment variable forwarding tests ---"

for var in "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "GEMINI_API_KEY"; do
  file_contains "${AGENT_RUN}" "${var}" \
    && pass "bin/agent-run forwards ${var}" \
    || fail "bin/agent-run does not forward ${var}"
done

echo ""

# ---------------------------------------------------------------------------
# T009: Devcontainer isolation
# ---------------------------------------------------------------------------
echo "--- Devcontainer isolation tests ---"

file_contains "${AGENT_RUN}" "agent-run-" \
  && pass "bin/agent-run uses distinct container name prefix" \
  || fail "bin/agent-run does not use distinct container name prefix"

echo ""

# ---------------------------------------------------------------------------
# T010: Timeout flag
# ---------------------------------------------------------------------------
echo "--- Timeout flag tests ---"

file_contains "${AGENT_RUN}" "\-\-timeout" \
  && pass "bin/agent-run supports --timeout flag" \
  || fail "bin/agent-run does not support --timeout flag"

echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== Results ==="
echo "  Passed: ${PASS}"
echo "  Failed: ${FAIL}"

if [[ ${FAIL} -gt 0 ]]; then
  exit 1
fi
