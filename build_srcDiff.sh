#!/usr/bin/env bash
set -euo pipefail

# load functions/vars into this script
source "$(dirname "$0")/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcDiff.sh [--yes|-y] [workspace]

  --yes, -y   Skip the interactive confirmation before wiping the build directory.
  workspace   Optional workspace directory. Defaults to this script's directory.
EOF
}

AUTO_YES=0
WS_ARG=""

while [ "$#" -gt 0 ]; do
  case "$1" in
  -y | --yes)
    AUTO_YES=1
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
SRCML_CMAKE_DIR="$SRCML_INSTALL/share/cmake/srcml"

case "${SRCDIFF_DEBUG:-0}" in
0)
  BUILD_TYPE="Release"
  BUILDDIR="$SRCDIFF/build"
  ;;
1)
  BUILD_TYPE="Debug"
  BUILDDIR="$SRCDIFF/build-debug"
  ;;
*)
  echo "✗ Invalid SRCDIFF_DEBUG value: ${SRCDIFF_DEBUG}"
  echo "  Use SRCDIFF_DEBUG=1 for a debug build, or leave it unset for the default optimized build."
  exit 1
  ;;
esac

echo "srcDiff source:         $SRCDIFF"
echo "srcML install (cmake):  $SRCML_CMAKE_DIR"
echo "Build type:             $BUILD_TYPE"
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
  confirm_or_exit "Delete and rebuild from scratch? Type 'y' or 'yes' to continue: "
  echo "✓ Build directory reset confirmed"
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
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF

echo "✓ CMake configure complete"
echo ""

#############################################
# Build srcDiff
#############################################
echo "=== [7/7] Building srcDiff (ninja) ==="
ninja -C "$BUILDDIR"
echo "✓ Build complete"

echo ""
echo "Built $BUILD_TYPE srcDiff at: $BUILDDIR/bin/srcdiff"
echo "=== All steps finished successfully ==="
