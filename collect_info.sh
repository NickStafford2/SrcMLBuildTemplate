#!/bin/bash
# Collect a bunch of information about the build process and output to a temp file.
# Helps me see it all in one place.
# Output will be saved to buildProcessDump.txt

OUT="buildProcessDump.txt"
BASE="$HOME/Projects/srcWorkspace"

SRCML="$BASE/srcML"
SRCDIFF="$BASE/srcDiff"

echo "Collecting information..." >"$OUT"

echo "=== SRCML: CMakePresets.json ===" >>"$OUT"
if [ -f "$SRCML/CMakePresets.json" ]; then
  sed -n '1,200p' "$SRCML/CMakePresets.json" >>"$OUT"
else
  echo "Not found: $SRCML/CMakePresets.json" >>"$OUT"
fi
echo "" >>"$OUT"

echo "=== SRCML: Installed CMake package directory (if exists) ===" >>"$OUT"
if [ -d "$SRCML/install/share/cmake/srcml" ]; then
  ls -R "$SRCML/install/share/cmake/srcml" >>"$OUT"
else
  echo "Not found: $SRCML/install/share/cmake/srcml" >>"$OUT"
fi
echo "" >>"$OUT"

echo "=== SRCML: Build tree targets files ===" >>"$OUT"
find "$SRCML/build" -maxdepth 3 -name "*targets.cmake" 2>/dev/null >>"$OUT"
echo "" >>"$OUT"

echo "=== SRCML: Top-level CMakeLists.txt (first 200 lines) ===" >>"$OUT"
sed -n '1,200p' "$SRCML/CMakeLists.txt" >>"$OUT"
echo "" >>"$OUT"

echo "=== SRCDIFF: src/client/CMakeLists.txt ===" >>"$OUT"
sed -n '1,200p' "$SRCDIFF/src/client/CMakeLists.txt" >>"$OUT"
echo "" >>"$OUT"

echo "=== SRCDIFF: Top-level CMakeLists.txt ===" >>"$OUT"
sed -n '1,200p' "$SRCDIFF/CMakeLists.txt" >>"$OUT"
echo "" >>"$OUT"

echo "=== SRCDIFF: Directory tree (src/) depth 2 ===" >>"$OUT"
if command -v tree >/dev/null 2>&1; then
  tree -L 2 "$SRCDIFF/src" >>"$OUT"
else
  echo "(tree not installed — using fallback)" >>"$OUT"
  find "$SRCDIFF/src" -maxdepth 2 | sed 's/^/    /' >>"$OUT"
fi

echo "" >>"$OUT"
echo "Done! Output saved to $OUT"
