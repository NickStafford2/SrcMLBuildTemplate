#!/usr/bin/env bash
# build_srcReader.sh
set -euo pipefail

# load functions/vars into this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcReader.sh [--yes|-y] [workspace]

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

WS="$(resolve_ws "$WS_ARG")"
echo "=== Workspace: $WS ==="

SRCREADER="$WS/srcReader"
BUILDDIR="$SRCREADER/build"
SRCML_INSTALL="$WS/srcML-install"

echo "srcReader source:       $SRCREADER"
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
cmake -S "$SRCREADER" \
  -B "$BUILDDIR" \
  -G Ninja \
  -DSRCML_INSTALL_PREFIX="$SRCML_INSTALL" \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
  -DCMAKE_CXX_FLAGS_DEBUG="-O0 -g3 -gdwarf-4 -fstandalone-debug -fno-omit-frame-pointer" \
  -DCMAKE_EXE_LINKER_FLAGS_DEBUG="-g" \
  -DCMAKE_SHARED_LINKER_FLAGS_DEBUG="-g"
# -DCMAKE_BUILD_TYPE=Release \

ninja -C "$BUILDDIR"
echo "✓ Build complete"
echo ""
echo "Built libs at: $BUILDDIR/bin/"

link_compile_commands "$BUILDDIR" "$SRCREADER"
