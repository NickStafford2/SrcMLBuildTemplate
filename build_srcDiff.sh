#!/usr/bin/env bash
set -euo pipefail

# load functions/vars into this script
source "$(dirname "$0")/utils.sh"

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
echo "=== [1/7] Checking for srcDiff repository ==="
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
# Sanity Checks
#############################################
echo "=== [3/7] Checking prerequisites ==="
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
# Build directory check (prompt only if exists)
#############################################
echo "=== [4/7] Build directory check ==="
if [ -d "$BUILDDIR" ]; then
  echo "Existing build directory detected:"
  echo "  $BUILDDIR"
  echo ""
  read -r -p "Delete and rebuild from scratch? Type 'y' or 'yes' to continue: " CONFIRM

  CONFIRM_LC="$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')"

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

cmake -S "$SRCDIFF" \
  -B "$BUILDDIR" \
  -G Ninja \
  -DsrcML_DIR="$SRCML_CMAKE_DIR" \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF

# -DCMAKE_BUILD_TYPE=Debug \

echo "✓ CMake configure complete"
echo ""

#############################################
# Build srcDiff
#############################################
echo "=== [7/7] Building srcDiff (ninja) ==="
ninja -C "$BUILDDIR"
echo "✓ Build complete"

echo ""
echo "Built srcDiff at: $BUILDDIR/bin/srcdiff"
echo "=== All steps finished successfully ==="
