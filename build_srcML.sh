#!/usr/bin/env bash
# build_srcML.sh
#
# Clone (if needed) and build srcML into a local install directory.
#
# Workspace:
#   - If you pass an argument, that is the workspace directory.
#   - Otherwise, the workspace is the directory you run this script from.
#
# Layout created:
#   <workspace>/srcML         (git clone of https://github.com/srcML/srcML.git)
#   <workspace>/srcML-build   (build dir, will be wiped)
#   <workspace>/srcML-install (CMake install prefix, will be wiped)

set -euo pipefail

#############################################
# Helpers
#############################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcML.sh [--yes|-y] [--preset <name>] [workspace]

  --yes, -y   Skip the interactive confirmation before wiping build directories.
  --preset    CMake configure/build preset to use for srcML. Defaults to `ci-ubuntu`.
  workspace   Optional workspace directory. Defaults to the current directory.
EOF
}

AUTO_YES=0
WS_ARG=""
SRCML_PRESET="ci-ubuntu"

while [ "$#" -gt 0 ]; do
  case "$1" in
  -y | --yes)
    AUTO_YES=1
    ;;
  --preset)
    if [ "$#" -lt 2 ]; then
      echo "✗ --preset requires a value"
      usage
      exit 1
    fi
    SRCML_PRESET="$2"
    shift
    ;;
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

#############################################
# Workspace Resolution
#############################################

if [ -n "$WS_ARG" ]; then
  WS="$WS_ARG"
  echo "=== Using user-provided workspace: $WS ==="
else
  WS="$(pwd)"
  echo "=== No workspace provided. Using current directory as workspace: $WS ==="
fi
echo ""

#############################################
# Path Setup
#############################################

SRCML="$WS/srcML"
BUILDDIR="$WS/srcML-build"
INSTALLDIR="$WS/srcML-install"

echo "srcML source:      $SRCML"
echo "Build directory:   $BUILDDIR"
echo "Install location:  $INSTALLDIR"
echo "CMake preset:      $SRCML_PRESET"
echo ""

#############################################
# Prerequisite checks
#############################################

echo "=== [0/6] Checking required commands ==="
require_cmd git
require_cmd cmake
echo "✓ git and cmake found"
echo ""

#############################################
# Clone srcML if needed
#############################################

echo "=== [1/6] Checking for srcML repository ==="
if [ -d "$SRCML/.git" ]; then
  echo "↻ srcML repo already exists — skipping clone"
else
  echo "Cloning srcML into: $SRCML"
  git clone https://github.com/srcML/srcML.git "$SRCML"
  echo "✓ srcML repository cloned"
fi
echo ""

#############################################
# Confirm deletion of old build/install
#############################################

echo "=== [2/6] Preparing to reset build/install directories ==="
echo "These directories will be permanently deleted (if they exist):"
echo "  $BUILDDIR"
echo "  $INSTALLDIR"
echo ""
confirm_or_exit
echo "✓ Directory reset confirmed"
echo ""

#############################################
# Clean & Prepare
#############################################

echo "=== [3/6] Resetting build and install directories ==="
rm -rf "$BUILDDIR" "$INSTALLDIR"
mkdir -p "$BUILDDIR"
echo "✓ Directories reset"
echo ""

#############################################
# Configure with CMake
#############################################

echo "=== [4/6] Configuring srcML with CMake ==="
(
  cd "$SRCML"
  cmake \
    --preset "$SRCML_PRESET" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLDIR"
)

echo "✓ CMake configure complete"
echo ""

#############################################
# Build
#############################################

echo "=== [5/6] Building srcML ==="
(
  cd "$SRCML"
  cmake --build --preset "$SRCML_PRESET"
)
echo "✓ Build complete"
echo ""

#############################################
# Install
#############################################

echo "=== [6/6] Installing srcML ==="
cmake --install "$BUILDDIR"
echo "✓ Installation complete"
echo ""

if [ -x "$INSTALLDIR/bin/srcml" ]; then
  echo "srcML binary: $INSTALLDIR/bin/srcml"
else
  echo "⚠ srcML binary not found at $INSTALLDIR/bin/srcml (check build logs)."
fi

echo "=== All srcML steps finished successfully ==="
echo ""
