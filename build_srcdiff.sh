#!/bin/bash
set -e

WS="$HOME/Projects/srcWorkspace"
SRCDIFF="$WS/srcDiff"
SRCML_INSTALL="$WS/srcML-install"

BUILDDIR="$SRCDIFF/build"

rm -rf "$BUILDDIR"
mkdir -p "$BUILDDIR"
cd "$BUILDDIR"

cmake -G Ninja \
  -DsrcML_DIR="$SRCML_INSTALL/share/cmake/srcml" \
  "$SRCDIFF"

ninja

echo "Built srcDiff at: $BUILDDIR/bin/srcdiff"
