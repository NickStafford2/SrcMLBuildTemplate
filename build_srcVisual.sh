#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcVisual.sh [workspace]

  workspace   Optional workspace directory. Defaults to this script's directory.

Environment:
  SRCVISUAL_REPO_URL  Repository URL used when ./srcVisual is missing.
                      Default: https://github.com/NickStafford2/srcVisual.git
EOF
}

WS_ARG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "✗ Unknown option: $1"
    usage
    exit 1
    ;;
  *)
    if [ -n "$WS_ARG" ]; then
      echo "✗ Unexpected extra argument: $1"
      usage
      exit 1
    fi
    WS_ARG="$1"
    ;;
  esac
  shift
done

WS="$(resolve_ws "$WS_ARG")"
SRCVISUAL="$WS/srcVisual"
FRONTEND="$SRCVISUAL/frontend"
VENV="$SRCVISUAL/.venv"
SRCVISUAL_REPO_URL="${SRCVISUAL_REPO_URL:-https://github.com/NickStafford2/srcVisual.git}"

echo "=== Workspace: $WS ==="
echo "srcVisual source:       $SRCVISUAL"
echo "Python environment:     $VENV"
echo "Frontend output:        $FRONTEND/dist"
echo ""

echo "=== [1/4] Checking prerequisites ==="
require_cmd git
require_cmd python3
require_cmd npm
echo "✓ Commands found"
echo ""

echo "=== [2/4] Checking for srcVisual repository ==="
if [ -d "$SRCVISUAL/.git" ]; then
  echo "↻ srcVisual repo already exists — skipping clone"
elif [ -f "$SRCVISUAL/pyproject.toml" ]; then
  echo "↻ srcVisual source directory already exists without git metadata — skipping clone"
else
  echo "Cloning srcVisual into: $SRCVISUAL"
  git clone "$SRCVISUAL_REPO_URL" "$SRCVISUAL"
  echo "✓ srcVisual repository cloned"
fi
echo ""

echo "=== [3/4] Installing Python backend ==="
if [ ! -f "$SRCVISUAL/pyproject.toml" ]; then
  echo "✗ pyproject.toml not found at: $SRCVISUAL/pyproject.toml"
  exit 1
fi

if [ ! -x "$VENV/bin/python" ]; then
  if ! python3 -m venv "$VENV"; then
    echo "✗ Could not create the Python virtual environment at: $VENV"
    echo "  Install the Python venv package for your system and rerun this script."
    exit 1
  fi
fi

"$VENV/bin/python" -m pip install --editable "$SRCVISUAL"
echo "✓ Python backend installed"
echo ""

echo "=== [4/4] Building frontend ==="
if [ ! -f "$FRONTEND/package-lock.json" ]; then
  echo "✗ package-lock.json not found at: $FRONTEND/package-lock.json"
  exit 1
fi

npm --prefix "$FRONTEND" ci
npm --prefix "$FRONTEND" run build

echo ""
echo "✓ srcVisual build complete"
echo "Backend command:        $VENV/bin/web"
echo "Frontend output:        $FRONTEND/dist"
