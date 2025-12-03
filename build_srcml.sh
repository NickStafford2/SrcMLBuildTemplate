#!/bin/bash
set -e

WS="$HOME/Projects/srcWorkspace"
SRCML="$WS/srcML"
BUILDDIR="$WS/srcML-build"
INSTALLDIR="$WS/srcML-install"

rm -rf "$BUILDDIR" "$INSTALLDIR"
mkdir -p "$BUILDDIR"

cmake "$SRCML" --preset ci-ubuntu

cd "$BUILDDIR"
cmake -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" .

cmake --build .

cmake --install .
