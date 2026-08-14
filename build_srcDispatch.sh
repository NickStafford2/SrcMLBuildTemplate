#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
build_srcDispatch.sh is not implemented yet.

The supported empty-workspace bootstrap path is:

  ./build_srcML.sh --yes
  ./build_srcReader.sh --yes
  ./build_srcDiff.sh --yes
  ./build_srcMove.sh --yes

srcDispatch is an optional related checkout and is not part of the standard
srcMove workspace build.
EOF

exit 2
