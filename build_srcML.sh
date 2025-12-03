#!/usr/bin/env bash
# build_srcDiff.sh
#
# Clone (if needed), update submodules, and build srcDiff against a
# locally installed srcML.
#
# Workspace:
#   - If you pass an argument, that is the workspace directory.
#   - Otherwise, the workspace is the directory you run this script from.
#
# Expected layout:
#   <workspace>/srcML-install           (created by build_srcML.sh)
#   <workspace>/srcML-install/share/cmake/srcml (CMake config dir)
#   <workspace>/srcDiff                 (git clone of srcDiff)
#   <workspace>/srcDiff/build           (build dir, will be wiped)

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

SRCDIFF="$WS/srcDiff"
SRCML_INSTALL="$WS/srcML-install"
BUILDDIR="$SRCDIFF/build"
SRCML_CMAKE_DIR="$SRCML_INSTALL/share/cmake/srcml"

echo "srcDiff source:         $SRCDIFF"
echo "srcML install (cmake):  $SRCML_CMAKE_DIR"
echo "Build directory:        $BUILDDIR"
echo ""

#############################################
# Prerequisite checks
#############################################

echo "=== [0/7] Checking required commands ==="
require_cmd git
require_cmd cmake
require_cmd ninja
echo "✓ git, cmake, and ninja found"
echo ""

#############################################
# Clone srcDiff if needed
#############################################

echo "=== [1/7] Checking for srcDiff repository ==="
if [ -d "$SRCDIFF/.git" ]; then
  echo "↻ srcDiff repo already exists — skipping clone"
else
  echo "Cloning srcDiff into: $SRCDIFF"
  git clone https://github.com/srcML/srcDiff.git "$SRCDIFF"
  echo "✓ srcDiff repository cloned"
fi
echo ""

#############################################
# Update submodules
#############################################

echo "=== [2/7] Updating srcDiff submodules ==="
(
  cd "$SRCDIFF"
  git submodule update --init --recursive
)
echo "✓ Submodules updated"
echo ""

#############################################
# Sanity Checks for Directories
#############################################

echo "=== [3/7] Checking required directories ==="

if [ ! -d "$SRCDIFF" ]; then
  echo "✗ srcDiff directory not found at: $SRCDIFF"
  echo "  Expected layout:"
  echo "    $WS/srcDiff"
  echo "    $WS/srcML-install"
  exit 1
fi

if [ ! -d "$SRCML_CMAKE_DIR" ]; then
  echo "✗ srcML CMake config directory not found at:"
  echo "  $SRCML_CMAKE_DIR"
  echo "  Make sure srcML has been built and installed into: $SRCML_INSTALL"
  exit 1
fi

if [ ! -f "$SRCML_CMAKE_DIR/srcMLConfig.cmake" ]; then
  echo "✗ srcMLConfig.cmake not found in:"
  echo "  $SRCML_CMAKE_DIR"
  echo "  srcDiff needs the srcML CMake configuration files."
  exit 1
fi

echo "✓ srcDiff source and srcML CMake config found"
echo ""

#############################################
# Build directory check (prompt only if exists)
#############################################

echo "=== [4/7] Build directory check ==="
if [ -d "$BUILDDIR" ]; then
  echo "Existing build directory detected:"
  echo "  $BUILDDIR"
  echo ""
  read -r -p "Delete and rebuild from scratch? Type 'y' or 'yes' to continue: " CONFIRM

  CONFIRM_LC="$(printf '%s' "$CONFIRM" | tr '[:upper:]' '[:lower:]')"

  case "$CONFIRM_LC" in
  y | ye | yes)
    echo "✓ User confirmed removal of existing build directory"
    ;;
  *)
    echo "✗ Confirmation not received — aborting."
    exit 1
    ;;
  esac
else
  echo "No existing build directory found; a fresh one will be created."
fi
echo ""

#############################################
# Clean & Prepare Build Directory
#############################################

echo "=== [5/7] Preparing build directory ==="
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"
echo "✓ Build directory ready: $BUILDDIR"
echo ""

#############################################
# Configure with CMake
#############################################

echo "=== [6/7] Configuring srcDiff with CMake ==="
cd "$BUILDDIR"

cmake -G Ninja \
  -DsrcML_DIR="$SRCML_CMAKE_DIR" \
  "$SRCDIFF"

echo "✓ CMake configure complete"
echo ""

#############################################
# Build srcDiff
#############################################

echo "=== [7/7] Building srcDiff (ninja) ==="
ninja
echo "✓ Build complete"
echo ""

if [ -x "$BUILDDIR/bin/srcdiff" ]; then
  echo "srcDiff binary: $BUILDDIR/bin/srcdiff"
else
  echo "⚠ srcdiff binary not found at $BUILDDIR/bin/srcdiff (check build logs)."
fi

echo "=== All srcDiff steps finished successfully ==="
echo ""
