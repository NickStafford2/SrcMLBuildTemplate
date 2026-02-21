#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

WS="$(resolve_ws "${1:-}")"

echo "=== Workspace: $WS ==="

SRCMOVE="$WS/srcMove"
BUILDDIR="$SRCMOVE/build"
SRCREADER="$WS/srcReader"
SRCML_INSTALL="$WS/srcML-install"

echo "srcMove source:         $SRCMOVE"
echo "Build directory:        $BUILDDIR"
echo "srcReader:              $SRCREADER"
echo "srcML-install:          $SRCML_INSTALL"
echo ""

echo "=== [1/4] Checking prerequisites ==="
require_build_tools
require_boost # if you added this earlier; safe even if srcMove doesn't include boost yet

# ensure deps exist
if [ ! -f "$SRCREADER/build/bin/libsrcreader.so" ] && [ ! -f "$SRCREADER/build/bin/libsrcreader.a" ]; then
  echo "✗ srcReader not built yet."
  echo "  Expected srcreader outputs in: $SRCREADER/build/bin/"
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
cmake -S "$SRCMOVE" \
  -B "$BUILDDIR" \
  -G Ninja \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_CXX_FLAGS_DEBUG="-O0 -g3 -gdwarf-4 -fstandalone-debug -fno-omit-frame-pointer" \
  -DCMAKE_EXE_LINKER_FLAGS_DEBUG="-g" \
  -DCMAKE_SHARED_LINKER_FLAGS_DEBUG="-g" \
  -DWORKSPACE_ROOT="$WS"

ninja -C "$BUILDDIR"

echo ""
echo "✓ Build complete"
echo "Built srcMove at: $BUILDDIR/srcMove"

link_compile_commands "$BUILDDIR" "$SRCMOVE"
