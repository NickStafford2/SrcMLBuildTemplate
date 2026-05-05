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

confirm_or_exit() {
  local prompt="${1:-Type 'y' or 'yes' to continue: }"

  if [ "${AUTO_YES:-0}" = "1" ]; then
    echo "✓ Auto-confirm enabled (--yes); continuing"
    return
  fi

  local confirm
  read -r -p "$prompt" confirm

  local confirm_lc
  confirm_lc="$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')"

  case "$confirm_lc" in
  y | ye | yes) ;;
  *)
    echo "✗ Confirmation not received — aborting."
    exit 1
    ;;
  esac
}

confirm_clean_builddir() {
  local builddir="$1"

  if [ -d "$builddir" ]; then
    echo "Existing build directory detected:"
    echo "  $builddir"
    echo ""
    confirm_or_exit "Delete and rebuild from scratch? Type 'y' or 'yes' to continue: "
    rm -rf "$builddir"
  fi

  mkdir -p "$builddir"
  echo "✓ Build directory ready: $builddir"
  echo ""
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

require_boost() {
  if [ ! -d /usr/include/boost ]; then
    echo "Boost not found. Installing libboost-all-dev..."
    require_cmd sudo
    sudo apt-get update
    sudo apt-get install -y libboost-all-dev
    echo "✓ Boost installed"
    echo ""
  else
    echo "✓ Boost headers found"
    echo ""
  fi
}

# Ensure compile_commands.json is available at project root for clangd.
link_compile_commands() {
  local builddir="$1"
  local project_root="$2"

  local cc="$builddir/compile_commands.json"
  if [ -f "$cc" ]; then
    ln -sf "$cc" "$project_root/compile_commands.json"
    echo "✓ Linked compile_commands.json -> $project_root/compile_commands.json"
  else
    echo "✗ compile_commands.json not found at: $cc"
    echo "  Did CMake configure run with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ?"
    exit 1
  fi
}
