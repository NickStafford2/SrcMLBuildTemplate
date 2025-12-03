#!/bin/bash
set -e

#############################################
# Workspace Path Resolution
#############################################
if [ -n "${1:-}" ]; then
  WS="$1"
  echo "=== Using user-provided workspace: $WS ==="
else
  WS="$(pwd)"
  echo "=== No workspace provided. Using current directory: $WS ==="
fi
echo ""

#############################################
# Clone srcML Repo If Missing
#############################################
SRCML="$WS/srcML"

echo "=== [0/7] Checking for srcML repository ==="
if [ -d "$SRCML/.git" ]; then
  echo "↻ srcML repo already exists — skipping clone"
else
  echo "Cloning srcML into: $SRCML"
  git clone https://github.com/srcML/srcML.git "$SRCML"
  echo "✓ srcML repository cloned"
fi
echo ""

#############################################
# Path Setup
#############################################
BUILDDIR="$WS/srcML-build"
INSTALLDIR="$WS/srcML-install"

echo "SRCML source:      $SRCML"
echo "Build directory:   $BUILDDIR"
echo "Install location:  $INSTALLDIR"
echo ""

#############################################
# Confirm Deletion
#############################################
echo "=== [1/7] Preparing to remove old build/install directories ==="
echo "These directories will be permanently deleted:"
echo "  $BUILDDIR"
echo "  $INSTALLDIR"
echo ""
read -r -p "Type 'y' or 'yes' to continue: " CONFIRM

CONFIRM_LC="$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')"

case "$CONFIRM_LC" in
y | ye | yes)
  echo "✓ User confirmed directory removal"
  ;;
*)
  echo "✗ Confirmation not received — aborting."
  exit 1
  ;;
esac
echo ""

#############################################
# Clean & Prepare
#############################################
echo "=== [2/7] Resetting build and install directories ==="
rm -rf "$BUILDDIR" "$INSTALLDIR"
mkdir -p "$BUILDDIR"
echo "✓ Directories reset"
echo ""

#############################################
# Preset Configure
#############################################
echo "=== [3/7] Running preset CMake configure ==="
cmake "$SRCML" --preset ci-ubuntu
echo "✓ Preset configure complete"
echo ""

#############################################
# Manual Configure
#############################################
echo "=== [4/7] Running manual CMake configure ==="
cd "$BUILDDIR"
cmake -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" .
echo "✓ Manual configure complete"
echo ""

#############################################
# Build
#############################################
echo "=== [5/7] Building srcML ==="
cmake --build .
echo "✓ Build complete"
echo ""

#############################################
# Install
#############################################
echo "=== [6/7] Installing srcML ==="
cmake --install .
echo "✓ Installation complete"
echo ""

echo "=== All steps finished successfully ==="
