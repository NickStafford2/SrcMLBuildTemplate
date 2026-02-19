#!/usr/bin/env bash
# utils.sh

greet() {
  echo "hi $1"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "✗ Missing required command: $1" >&2
    exit 1
  fi
}

require_build_tools() {
  require_cmd cmake
  require_cmd ninja
  require_cmd clang++
  echo "✓ Commands found"
  echo ""
}

confirm_clean_builddir() {
  local builddir="$1"
  if [ -d "$builddir" ]; then
    echo "Existing build directory detected:"
    echo "  $builddir"
    echo ""
    read -r -p "Delete and rebuild from scratch? Type 'y' or 'yes' to continue: " CONFIRM
    CONFIRM_LC="$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')"
    case "$CONFIRM_LC" in
    y | ye | yes) ;;
    *)
      echo "✗ Confirmation not received — aborting."
      exit 1
      ;;
    esac

    rm -rf "$builddir"
    mkdir -p "$builddir"
    echo "✓ Build directory ready: $builddir"
    echo ""
  fi
}

resolve_ws() {
  local maybe="${1:-}"
  if [ -n "$maybe" ]; then
    # canonicalize user-provided path
    (cd "$maybe" && pwd)
  else
    # directory containing the script that called this
    local script_dir
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[1]}")" && pwd)"
    echo "$script_dir"
  fi
}
