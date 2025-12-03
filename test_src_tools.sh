#!/bin/bash
set -euo pipefail

# Adjust these paths if your install locations differ
SRCML_BIN="$HOME/Projects/srcWorkspace/srcML-install/bin/srcml"
SRCDIFF_BIN="$HOME/Projects/srcWorkspace/srcDiff/build/bin/srcdiff"

ok() { echo "[OK] $*"; }
fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

echo "=== Testing srcML and srcDiff ==="

# 1) Check binaries exist
[[ -x "$SRCML_BIN" ]] || fail "srcml binary not found at $SRCML_BIN"
[[ -x "$SRCDIFF_BIN" ]] || fail "srcdiff binary not found at $SRCDIFF_BIN"
ok "Binaries exist"

# temp directory
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"

# 2 test files
cat >a.cpp <<'EOF'
int main() { return 0; }
EOF

cat >b.cpp <<'EOF'
int main() { return 1; }
EOF

# 2) Test srcML version
"$SRCML_BIN" --version >/dev/null 2>&1 || fail "srcml --version failed"
ok "srcml --version works"

# 3) Test srcML XML generation
"$SRCML_BIN" a.cpp >a.xml || fail "srcml a.cpp failed"
grep -q "<unit" a.xml || fail "srcML output does not contain <unit>"
ok "srcML converted a.cpp to XML"

# 4) Test srcDiff help
"$SRCDIFF_BIN" --help >/dev/null 2>&1 || fail "srcdiff --help failed"
ok "srcdiff --help works"

# 5) Test srcDiff diff output
"$SRCDIFF_BIN" a.cpp b.cpp >diff.xml || fail "srcdiff a.cpp b.cpp failed"
# Don't assume exact format—just ensure non-empty
[[ -s diff.xml ]] || fail "srcdiff produced empty output"
ok "srcdiff produced diff output"

echo "=== All tests passed ==="
