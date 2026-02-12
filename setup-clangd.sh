#!/usr/bin/env sh
# setup-clangd.sh
#
# Generates compile_commands.json for CMake + Ninja projects so clangd works
# correctly (Neovim, VSCode, CLion, etc).
#
# Usage:
#   ./setup-clangd.sh
#
# Then restart clangd in your editor (:LspRestart in Neovim).

set -eu

BUILD_DIR="${BUILD_DIR:-build}"

say() { printf '%s\n' "$*"; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v cmake >/dev/null || die "cmake not found"
command -v ninja >/dev/null || die "ninja not found"

say "== clangd setup =="
say "Build directory: $BUILD_DIR"
say ""

if [ ! -f CMakeLists.txt ]; then
  die "CMakeLists.txt not found. Run this from the project root."
fi

# Generate compile_commands.json via CMake
say "Configuring CMake with compile_commands.json enabled..."
cmake -S . -B "$BUILD_DIR" -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

say "Building with Ninja..."
ninja -C "$BUILD_DIR"

# Symlink into project root so clangd finds it reliably
if [ -f "$BUILD_DIR/compile_commands.json" ]; then
  say ""
  say "Linking $BUILD_DIR/compile_commands.json -> ./compile_commands.json"
  ln -sf "$BUILD_DIR/compile_commands.json" ./compile_commands.json
else
  die "compile_commands.json not generated"
fi

say ""
say "Done."
say ""
say "Restart clangd in your editor (:LspRestart for Neovim)."
