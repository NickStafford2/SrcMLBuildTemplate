#!/bin/bash
set -e

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
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  WS="$SCRIPT_DIR"
  echo "=== No workspace provided. Using script directory as workspace: $WS ==="
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
# Clone srcDiff if needed
#############################################
echo "=== [1/6] Checking for srcDiff repository ==="
require_cmd git

if [ -d "$SRCDIFF/.git" ]; then
  echo "↻ srcDiff repo already exists — skipping clone"
else
  echo "Cloning srcDiff into: $SRCDIFF"
  git clone https://github.com/srcML/srcDiff.git "$SRCDIFF"
  echo "✓ srcDiff repository cloned"
fi
echo ""

#############################################
# Sanity Checks
#############################################
echo "=== [2/6] Checking prerequisites ==="
require_cmd cmake
require_cmd ninja

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
echo "✓ Commands and required directories found"
echo ""

#############################################
# Confirm Deletion of Build Directory
#############################################
echo "=== [3/6] Build directory check ==="
if [ -d "$BUILDDIR" ]; then
  echo "Existing build directory detected:"
  echo "  $BUILDDIR"
  echo ""
  read -r -p "Delete and rebuild from scratch? Type 'y' or 'yes' to continue: " CONFIRM

  CONFIRM_LC="$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')"

  case "$CONFIRM_LC" in
  y | ye | yes)
    echo "✓ OK. :) removing existing build directory"
    ;;
  *)
    echo "✗ Bad Idea. :/ aborting."
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
echo "=== [4/6] Preparing build directory ==="
rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"
echo "✓ Build directory ready: $BUILDDIR"
echo ""

#############################################
# Configure with CMake
#############################################
echo "=== [5/6] Configuring srcDiff with CMake ==="
cd "$BUILDDIR"

cmake -G Ninja \
  -DsrcML_DIR="$SRCML_CMAKE_DIR" \
  "$SRCDIFF"

echo "✓ CMake configure complete"
echo ""

#############################################
# Build srcDiff
#############################################
echo "=== [6/6] Building srcDiff (ninja) ==="
ninja
echo "✓ Build complete"

echo ""
echo "Built srcDiff at: $BUILDDIR/bin/srcdiff"
echo "=== All steps finished successfully ==="
