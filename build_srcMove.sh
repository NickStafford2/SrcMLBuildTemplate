#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcMove.sh [--yes|-y] [workspace]

  --yes, -y   Skip the interactive confirmation before wiping the build directory.
  workspace   Optional workspace directory. Defaults to this script's directory.

Environment:
  SRCMOVE_DEBUG=1     Build a Debug configuration in ./srcMove/build-debug.
                      Default is Release in ./srcMove/build.
  SRCREADER_DEBUG=1   Link against ./srcReader/build-debug instead of ./srcReader/build.
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

SRCMOVE="$WS/srcMove"
SRCREADER="$WS/srcReader"
SRCML_INSTALL="$WS/srcML-install"

case "${SRCMOVE_DEBUG:-0}" in
0)
  BUILD_TYPE="Release"
  BUILDDIR="$SRCMOVE/build"
  ;;
1)
  BUILD_TYPE="Debug"
  BUILDDIR="$SRCMOVE/build-debug"
  ;;
*)
  echo "✗ Invalid SRCMOVE_DEBUG value: ${SRCMOVE_DEBUG}"
  echo "  Use SRCMOVE_DEBUG=1 for a debug build, or leave it unset for the default optimized build."
  exit 1
  ;;
esac

case "${SRCREADER_DEBUG:-0}" in
0)
  SRCREADER_BUILDDIR="$SRCREADER/build"
  ;;
1)
  SRCREADER_BUILDDIR="$SRCREADER/build-debug"
  ;;
*)
  echo "✗ Invalid SRCREADER_DEBUG value: ${SRCREADER_DEBUG}"
  echo "  Use SRCREADER_DEBUG=1 for a debug build, or leave it unset for the default optimized build."
  exit 1
  ;;
esac

echo "srcMove source:         $SRCMOVE"
echo "Build type:             $BUILD_TYPE"
echo "Build directory:        $BUILDDIR"
echo "srcReader:              $SRCREADER"
echo "srcReader build dir:    $SRCREADER_BUILDDIR"
echo "srcML-install:          $SRCML_INSTALL"
echo ""

echo "=== [1/4] Checking prerequisites ==="
require_build_tools
require_boost # if you added this earlier; safe even if srcMove doesn't include boost yet

# ensure deps exist
if [ ! -f "$SRCREADER_BUILDDIR/bin/libsrcreader.so" ] && [ ! -f "$SRCREADER_BUILDDIR/bin/libsrcreader.a" ]; then
  echo "✗ srcReader not built yet."
  echo "  Expected srcreader outputs in: $SRCREADER_BUILDDIR/bin/"
  echo "  Build srcReader first."
  exit 1
fi

if [ ! -d "$SRCML_INSTALL/include" ] || [ ! -d "$SRCML_INSTALL/lib" ]; then
  echo "✗ srcML-install not found or incomplete at: $SRCML_INSTALL"
  echo "  Expected: include/ and lib/ under srcML-install"
  exit 1
fi

echo "=== [2/4] Checking directories ==="
if [ ! -f "$SRCMOVE/CMakeLists.txt" ]; then
  echo "✗ CMakeLists.txt not found at: $SRCMOVE/CMakeLists.txt"
  exit 1
fi
echo "✓ srcMove directory looks valid"
echo ""

echo "=== [3/4] Build directory check ==="
confirm_clean_builddir "$BUILDDIR"

echo "=== [4/4] Configuring + building srcMove ==="
cmake_args=(
  -S "$SRCMOVE"
  -B "$BUILDDIR"
  -G Ninja
  -DCMAKE_CXX_COMPILER=clang++
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
  -DWORKSPACE_ROOT="$WS"
  -DSRCREADER_BUILD_DIR="$SRCREADER_BUILDDIR"
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

echo ""
echo "✓ Build complete"
echo "Built $BUILD_TYPE srcMove at: $BUILDDIR/srcMove"

link_compile_commands "$BUILDDIR" "$SRCMOVE"
