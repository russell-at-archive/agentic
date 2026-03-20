#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  agent-runner-entrypoint <repo-url> -- <command> [args...]

Environment:
  BASE_BRANCH   Branch to clone. Default: main.
  CLONE_DEPTH   Shallow clone depth. Default: 1.
  WORK_BRANCH   Optional branch to create after cloning.
  CLONE_DIR     Optional checkout path. Default: /workspace/<repo>.

Examples:
  agent-runner-entrypoint git@github.com:acme/project.git -- \
    codex exec --full-auto -C . "Summarize the current diff."
EOF
}

repo_url="${REPO_URL:-}"
base_branch="${BASE_BRANCH:-main}"
clone_depth="${CLONE_DEPTH:-1}"
clone_dir="${CLONE_DIR:-}"
work_branch="${WORK_BRANCH:-}"
command=()

while (($# > 0)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      command=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "${repo_url}" ]]; then
        repo_url="$1"
        shift
      else
        echo "Unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      ;;
  esac
done

if [[ -z "${repo_url}" ]]; then
  echo "A repository URL is required." >&2
  usage >&2
  exit 2
fi

if ((${#command[@]} == 0)); then
  echo "A command to run inside the cloned repository is required." >&2
  usage >&2
  exit 2
fi

if ! [[ "${clone_depth}" =~ ^[1-9][0-9]*$ ]]; then
  echo "CLONE_DEPTH must be a positive integer." >&2
  exit 2
fi

repo_name="$(basename "${repo_url}")"
repo_name="${repo_name%.git}"

if [[ -z "${clone_dir}" ]]; then
  clone_dir="/workspace/${repo_name}"
fi

mkdir -p "$(dirname "${clone_dir}")"
rm -rf "${clone_dir}"

echo "Cloning ${repo_url} (${base_branch}, depth=${clone_depth}) into ${clone_dir}" >&2
git clone \
  --depth "${clone_depth}" \
  --branch "${base_branch}" \
  --single-branch \
  "${repo_url}" \
  "${clone_dir}"

cd "${clone_dir}"

if [[ -n "${work_branch}" ]]; then
  git checkout -b "${work_branch}"
fi

echo "Running command in $(pwd): ${command[*]}" >&2
exec "${command[@]}"
