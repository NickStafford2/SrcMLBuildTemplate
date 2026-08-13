#!/usr/bin/env bash
set -euo pipefail

# load functions/vars into this script
source "$(dirname "$0")/utils.sh"

usage() {
  cat <<'EOF'
Usage: ./build_srcDiff.sh [--yes|-y] [--preset <name>] [--package] [--test] [--production] [workspace]

  --yes, -y      Skip the interactive confirmation before wiping the build directory.
  --preset       CMake configure preset to use. Defaults to debian, or ci-debian with --production.
  --package      Generate CPack artifacts into <workspace>/srcDiff-dist.
  --test         Run ctest after the build. Uses ci-debian unless --preset is supplied.
  --production   Release-oriented build: ci-debian preset + tests + CPack artifacts + local install.
  workspace      Optional workspace directory. Defaults to this script's directory.
EOF
}

AUTO_YES=0
WS_ARG=""
SRCDIFF_PRESET=""
RUN_PACKAGE=0
RUN_TESTS=0
PRESET_EXPLICIT=0

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
    SRCDIFF_PRESET="$2"
    PRESET_EXPLICIT=1
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
    if [ "$PRESET_EXPLICIT" = "0" ]; then
      SRCDIFF_PRESET="ci-debian"
    fi
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

if [ -z "$SRCDIFF_PRESET" ]; then
  if [ "$RUN_TESTS" = "1" ] || [ "$RUN_PACKAGE" = "1" ]; then
    SRCDIFF_PRESET="ci-debian"
  else
    SRCDIFF_PRESET="debian"
  fi
fi

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
INSTALLDIR="$WS/srcDiff-install"
DISTDIR="$WS/srcDiff-dist"

case "${SRCDIFF_DEBUG:-0}" in
0)
  BUILD_TYPE="Release"
  BUILDDIR="$SRCDIFF/build"
  ;;
1)
  BUILD_TYPE="Debug"
  BUILDDIR="$SRCDIFF/build"
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
echo "Install location:       $INSTALLDIR"
echo "Package location:       $DISTDIR"
echo "CMake preset:           $SRCDIFF_PRESET"
echo ""

#############################################
# Clone srcDiff if needed
#############################################
echo "=== [1/9] Checking for srcDiff repository ==="
require_cmd git

if [ -d "$SRCDIFF/.git" ]; then
  echo "↻ srcDiff repo already exists — skipping clone"
elif [ -f "$SRCDIFF/CMakeLists.txt" ]; then
  echo "↻ srcDiff source directory already exists without git metadata — skipping clone"
else
  echo "Cloning srcDiff into: $SRCDIFF"
  git clone https://github.com/srcML/srcDiff.git "$SRCDIFF"
  echo "✓ srcDiff repository cloned"
fi
echo ""

#############################################
# Update submodules
#############################################
echo "=== [2/9] Updating srcDiff submodules ==="
if [ -d "$SRCDIFF/.git" ]; then
  (
    cd "$SRCDIFF"
    git submodule update --init --recursive
  )
  echo "✓ Submodules updated"
else
  echo "↻ No git metadata available — skipping submodule update"
fi
echo ""

#############################################
# Sanity Checks
#############################################
echo "=== [3/9] Checking prerequisites ==="
require_cmd cmake
require_cmd ninja
require_cmd "${SRCDIFF_CC:-clang}"
require_cmd "${SRCDIFF_CXX:-clang++}"
if [ "$RUN_TESTS" = "1" ]; then
  require_cmd ctest
fi
if [ "$RUN_PACKAGE" = "1" ]; then
  require_cmd cpack
fi

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
echo "=== [4/9] Build directory check ==="
if [ -d "$BUILDDIR" ]; then
  echo "Existing build directory detected:"
  echo "  $BUILDDIR"
  echo "  $INSTALLDIR"
  if [ "$RUN_PACKAGE" = "1" ]; then
    echo "  $DISTDIR"
  fi
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
echo "=== [5/9] Preparing build directory ==="
rm -rf "$BUILDDIR" "$INSTALLDIR"
if [ "$RUN_PACKAGE" = "1" ]; then
  rm -rf "$DISTDIR"
fi
mkdir -p "$BUILDDIR"
echo "✓ Build directory ready: $BUILDDIR"
echo ""

#############################################
# Configure with CMake
#############################################
echo "=== [6/9] Configuring srcDiff with CMake preset ==="
(
  cd "$SRCDIFF"
  cmake \
    --preset "$SRCDIFF_PRESET" \
    -DsrcML_DIR="$SRCML_CMAKE_DIR" \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DCMAKE_C_COMPILER="${SRCDIFF_CC:-clang}" \
    -DCMAKE_CXX_COMPILER="${SRCDIFF_CXX:-clang++}" \
    -DCPACK_OUTPUT_FILE_PREFIX="$DISTDIR" \
    -DCMAKE_CXX_SCAN_FOR_MODULES=OFF
)

echo "✓ CMake configure complete"
echo ""

#############################################
# Build srcDiff
#############################################
echo "=== [7/9] Building srcDiff ==="
ninja -C "$BUILDDIR"
echo "✓ Build complete"
echo ""

#############################################
# Test srcDiff
#############################################
echo "=== [8/9] Testing srcDiff ==="
if [ "$RUN_TESTS" = "1" ]; then
  ctest --test-dir "$BUILDDIR" --output-on-failure
  echo "✓ Tests complete"
else
  echo "↻ Skipping tests (use --test or --production to enable)"
fi
echo ""

#############################################
# Package and install srcDiff
#############################################
echo "=== [9/9] Packaging and installing srcDiff ==="
if [ "$RUN_PACKAGE" = "1" ]; then
  cpack --config "$BUILDDIR/CPackConfig.cmake" -D "CPACK_COMPONENTS_ALL=DEVLIBS;SRCDIFF" -B "$DISTDIR"
  echo "✓ Package artifacts written to: $DISTDIR"
else
  echo "↻ Skipping package generation (use --package or --production to enable)"
fi

cmake --install "$BUILDDIR" --prefix "$INSTALLDIR" --component DEVLIBS
cmake --install "$BUILDDIR" --prefix "$INSTALLDIR" --component SRCDIFF
echo "✓ Installation complete"

echo ""
echo "Built $BUILD_TYPE srcDiff at: $BUILDDIR/bin/srcdiff"
echo "Installed srcDiff at: $INSTALLDIR/bin/srcdiff"
if [ "$RUN_PACKAGE" = "1" ]; then
  echo "srcDiff packages: $DISTDIR"
fi
echo "=== All steps finished successfully ==="
