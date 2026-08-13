#!/usr/bin/env bash
# build_srcML.sh
#
# Clone (if needed), build srcML, and optionally package it for release.
#
# Workspace:
#   - If you pass an argument, that is the workspace directory.
#   - Otherwise, the workspace is the directory you run this script from.
#
# Layout created:
#   <workspace>/srcML         (git clone of https://github.com/srcML/srcML.git)
#   <workspace>/srcML-build   (build dir, will be wiped)
#   <workspace>/srcML-install (CMake install prefix, will be wiped)
#   <workspace>/srcML-dist    (optional package output, will be wiped with --package)

set -euo pipefail

#############################################
# Helpers
#############################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcML.sh [--yes|-y] [--preset <name>] [--package] [--test] [--production] [workspace]

  --yes, -y      Skip the interactive confirmation before wiping build directories.
  --preset       CMake configure/build/package preset to use. Defaults to ci-ubuntu.
  --package      Generate CPack artifacts into <workspace>/srcML-dist.
  --test         Run ctest after the build.
  --production   Release-oriented build: preset build + tests + CPack artifacts.
  workspace      Optional workspace directory. Defaults to the current directory.
EOF
}

AUTO_YES=0
WS_ARG=""
SRCML_PRESET="ci-ubuntu"
RUN_PACKAGE=0
RUN_TESTS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
  -y | --yes)
    AUTO_YES=1
    ;;
  --preset)
    if [ "$#" -lt 2 ]; then
      echo "✗ --preset requires a value"
      usage
      exit 1
    fi
    SRCML_PRESET="$2"
    shift
    ;;
  --package)
    RUN_PACKAGE=1
    ;;
  --test)
    RUN_TESTS=1
    ;;
  --production)
    RUN_PACKAGE=1
    RUN_TESTS=1
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
  WS="$(pwd)"
  echo "=== No workspace provided. Using current directory as workspace: $WS ==="
fi
echo ""

#############################################
# Path Setup
#############################################

SRCML="$WS/srcML"
BUILDDIR="$WS/srcML-build"
INSTALLDIR="$WS/srcML-install"
DISTDIR="$WS/srcML-dist"

echo "srcML source:      $SRCML"
echo "Build directory:   $BUILDDIR"
echo "Install location:  $INSTALLDIR"
echo "Package location:  $DISTDIR"
echo "CMake preset:      $SRCML_PRESET"
echo ""

#############################################
# Prerequisite checks
#############################################

echo "=== [0/8] Checking required commands ==="
require_cmd git
require_cmd cmake
if [ "$RUN_TESTS" = "1" ]; then
  require_cmd ctest
fi
if [ "$RUN_PACKAGE" = "1" ]; then
  require_cmd cpack
fi
echo "✓ Required commands found"
echo ""

#############################################
# Clone srcML if needed
#############################################

echo "=== [1/8] Checking for srcML repository ==="
if [ -d "$SRCML/.git" ]; then
  echo "↻ srcML repo already exists — skipping clone"
elif [ -f "$SRCML/CMakeLists.txt" ]; then
  echo "↻ srcML source directory already exists without git metadata — skipping clone"
else
  echo "Cloning srcML into: $SRCML"
  git clone https://github.com/srcML/srcML.git "$SRCML"
  echo "✓ srcML repository cloned"
fi
echo ""

#############################################
# Confirm deletion of old build/install
#############################################

echo "=== [2/8] Preparing to reset build/install directories ==="
echo "These directories will be permanently deleted (if they exist):"
echo "  $BUILDDIR"
echo "  $INSTALLDIR"
if [ "$RUN_PACKAGE" = "1" ]; then
  echo "  $DISTDIR"
fi
echo ""
confirm_or_exit
echo "✓ Directory reset confirmed"
echo ""

#############################################
# Clean & Prepare
#############################################

echo "=== [3/8] Resetting build and install directories ==="
rm -rf "$BUILDDIR" "$INSTALLDIR"
if [ "$RUN_PACKAGE" = "1" ]; then
  rm -rf "$DISTDIR"
fi
mkdir -p "$BUILDDIR"
echo "✓ Directories reset"
echo ""

#############################################
# Configure with CMake
#############################################

echo "=== [4/8] Configuring srcML with CMake preset ==="
(
  cd "$SRCML"
  cmake \
    --preset "$SRCML_PRESET" \
    -DCMAKE_INSTALL_PREFIX="$INSTALLDIR" \
    -DCPACK_OUTPUT_FILE_PREFIX="$DISTDIR"
)

echo "✓ CMake configure complete"
echo ""

#############################################
# Build
#############################################

echo "=== [5/8] Building srcML ==="
(
  cd "$SRCML"
  cmake --build --preset "$SRCML_PRESET"
)
echo "✓ Build complete"
echo ""

#############################################
# Test
#############################################

echo "=== [6/8] Testing srcML ==="
if [ "$RUN_TESTS" = "1" ]; then
  SRCML="$BUILDDIR/bin/srcml" ctest --test-dir "$BUILDDIR" --output-on-failure
  echo "✓ Tests complete"
else
  echo "↻ Skipping tests (use --test or --production to enable)"
fi
echo ""

#############################################
# Package
#############################################

echo "=== [7/8] Packaging srcML ==="
if [ "$RUN_PACKAGE" = "1" ]; then
  (
    cd "$SRCML"
    cpack --preset "$SRCML_PRESET"
  )
  echo "✓ Package artifacts written to: $DISTDIR"
else
  echo "↻ Skipping package generation (use --package or --production to enable)"
fi
echo ""

#############################################
# Install
#############################################

echo "=== [8/8] Installing srcML ==="
cmake --install "$BUILDDIR" --component DEVLIBS
cmake --install "$BUILDDIR" --component SRCML
echo "✓ Installation complete"
echo ""

if [ -x "$INSTALLDIR/bin/srcml" ]; then
  echo "srcML binary: $INSTALLDIR/bin/srcml"
else
  echo "⚠ srcML binary not found at $INSTALLDIR/bin/srcml (check build logs)."
fi

if [ "$RUN_PACKAGE" = "1" ]; then
  echo "srcML packages: $DISTDIR"
fi

echo "=== All srcML steps finished successfully ==="
echo ""
