#!/usr/bin/env bash
# build_srcReader.sh
set -euo pipefail

# load functions/vars into this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcReader.sh [--yes|-y] [--debug|--release] [workspace]

  --yes, -y   Skip the interactive confirmation before wiping the build directory.
  --debug     Build a Debug configuration in ./srcReader/build-debug.
  --release   Build a Release configuration in ./srcReader/build.
  workspace   Optional workspace directory. Defaults to this script's directory.

Environment:
  SRCREADER_DEBUG=1   Build a Debug configuration in ./srcReader/build-debug.
                      Default is Release in ./srcReader/build.
                      CLI flags override this environment variable.
EOF
}

AUTO_YES=0
WS_ARG=""
BUILD_MODE_OVERRIDE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
  -y | --yes)
    AUTO_YES=1
    ;;
  --debug)
    BUILD_MODE_OVERRIDE="Debug"
    ;;
  --release)
    BUILD_MODE_OVERRIDE="Release"
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

WS="$(resolve_ws "$WS_ARG")"
echo "=== Workspace: $WS ==="

SRCREADER="$WS/srcReader"
SRCML_INSTALL="$WS/srcML-install"

if [ -n "$BUILD_MODE_OVERRIDE" ]; then
  BUILD_TYPE="$BUILD_MODE_OVERRIDE"
else
  case "${SRCREADER_DEBUG:-0}" in
  0)
    BUILD_TYPE="Release"
    ;;
  1)
    BUILD_TYPE="Debug"
    ;;
  *)
    echo "✗ Invalid SRCREADER_DEBUG value: ${SRCREADER_DEBUG}"
    echo "  Use SRCREADER_DEBUG=1 for a debug build, or leave it unset for the default optimized build."
    exit 1
    ;;
  esac
fi

case "$BUILD_TYPE" in
Release)
  BUILDDIR="$SRCREADER/build"
  ;;
Debug)
  BUILDDIR="$SRCREADER/build-debug"
  ;;
*)
  echo "✗ Invalid build type: $BUILD_TYPE"
  exit 1
  ;;
esac

echo "srcReader source:       $SRCREADER"
echo "Build type:             $BUILD_TYPE"
echo "Build directory:        $BUILDDIR"
echo ""

# Prereqs
echo "=== [1/4] Checking prerequisites ==="
require_build_tools
require_boost

# Sanity checks
echo "=== [2/4] Checking directories ==="
if [ ! -f "$SRCREADER/CMakeLists.txt" ]; then
  echo "✗ srcReader CMakeLists.txt not found at: $SRCREADER"
  exit 1
fi
echo "✓ srcReader directory looks valid"
echo ""

# Build dir check + clean
echo "=== [3/4] Build directory check ==="
confirm_clean_builddir "$BUILDDIR"

# Configure + build
echo "=== [4/4] Configuring + building srcReader ==="
cmake_args=(
  -S "$SRCREADER"
  -B "$BUILDDIR"
  -G Ninja
  -DSRCML_INSTALL_PREFIX="$SRCML_INSTALL"
  -DCMAKE_CXX_COMPILER=clang++
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF
)
if [ "$BUILD_TYPE" = "Debug" ]; then
  cmake_args+=(
    -DCMAKE_CXX_FLAGS_DEBUG=-O0\ -g3\ -gdwarf-4\ -fstandalone-debug\ -fno-omit-frame-pointer
    -DCMAKE_EXE_LINKER_FLAGS_DEBUG=-g
    -DCMAKE_SHARED_LINKER_FLAGS_DEBUG=-g
  )
fi
cmake "${cmake_args[@]}"

ninja -C "$BUILDDIR"
echo "✓ Build complete"
echo ""
echo "Built $BUILD_TYPE srcReader libs at: $BUILDDIR/bin/"

link_compile_commands "$BUILDDIR" "$SRCREADER"
