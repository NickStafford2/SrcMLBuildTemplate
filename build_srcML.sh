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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "✗ Missing required command: $1" >&2
    exit 1
  fi
}

#############################################
# Workspace Resolution
#############################################

if [ -n "${1:-}" ]; then
  WS="$1"
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
read -r -p "Type 'y' or 'yes' to continue: " CONFIRM

CONFIRM_LC="$(printf '%s' "$CONFIRM" | tr '[:upper:]' '[:lower:]')"

case "$CONFIRM_LC" in
y | ye | yes)
  echo "✓ User confirmed directory removal"
  ;;
*)
  echo "✗ Confirmation not received — aborting."
  exit 1
  ;;
esac
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
cd "$BUILDDIR"

cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" \
  "$SRCML"

echo "✓ CMake configure complete"
echo ""

#############################################
# Build
#############################################

echo "=== [5/6] Building srcML ==="
cmake --build . --parallel
echo "✓ Build complete"
echo ""

#############################################
# Install
#############################################

echo "=== [6/6] Installing srcML ==="
cmake --install .
echo "✓ Installation complete"
echo ""

if [ -x "$INSTALLDIR/bin/srcml" ]; then
  echo "srcML binary: $INSTALLDIR/bin/srcml"
else
  echo "⚠ srcML binary not found at $INSTALLDIR/bin/srcml (check build logs)."
fi

echo "=== All srcML steps finished successfully ==="
echo ""
