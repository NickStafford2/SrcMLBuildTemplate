# srcDiff Debug Wishlist

This document lists debugging tools that would make srcDiff failures easier to
isolate when running srcMove stress tests on large open source repositories.

The immediate motivation is the Notepad++ `v8.9` to `v8.9.5` stress run, where
a rebuilt `srcDiff` `develop` binary emitted `Invalid argument`, produced a
truncated `diff.xml`, and did not reach a usable srcMove input.

## Goals

- Find the exact file or file group that causes srcDiff to fail.
- Separate srcDiff failures from srcMove failures.
- Preserve small, repeatable repro directories.
- Identify whether the root cause is invalid srcML state, malformed srcDiff
  output, algorithmic blowup, or a timeout/hang.

## Wishlist

1. **Single-file replay command**

   Add a helper that runs srcDiff on one original/modified file pair while
   preserving archive-relative paths. This should make it easy to test files
   such as `PowerEditor/src/NppXml.h` and `PowerEditor/src/Parameters.cpp`
   outside the full Notepad++ archive.

2. **Archive bisection script**

   Add a script that takes two exported repository trees and runs srcDiff on
   subsets of files, narrowing the failure to the smallest file group that still
   fails. The script should copy repro files into `/tmp` and print the exact
   srcDiff command.

3. **Timeout and artifact classifier**

   Wrap srcDiff with a classifier that reports one of:

   - `PASS_VALID_XML`
   - `EXIT_NONZERO`
   - `TIMEOUT`
   - `MALFORMED_XML`
   - `FATAL_ERROR`
   - `INVALID_ARGUMENT`

   The classifier should validate XML instead of relying only on process exit
   status.

4. **Machine-readable progress log**

   srcDiff should print structured progress lines for each file:

   ```text
   SRCDIFF_FILE_START index=15 path=PowerEditor/src/Parameters.cpp
   SRCDIFF_FILE_DONE index=15 path=PowerEditor/src/Parameters.cpp seconds=12.34
   ```

   This would identify the file being processed when output stalls or becomes
   malformed.

5. **Per-file timing report**

   Emit a timing table for archive runs. This would identify pathological files
   even when the run eventually succeeds.

6. **Invariant failure dump**

   When srcDiff reaches an internal "should never happen" path, dump:

   - current filename
   - original and modified node indices
   - node types and names
   - short text snippets
   - surrounding construct stack, if available

   This is especially useful for diagnosing common-region mismatches in
   `common_stream`.

7. **srcML/node dump tool**

   For a single file pair, write:

   - `original.srcml.xml`
   - `modified.srcml.xml`
   - `original.nodes.txt`
   - `modified.nodes.txt`

   This would show whether srcML conversion produced an unexpected node stream
   before srcDiff matching begins.

8. **srcDiff-only stress mode**

   Add a stress-runner mode that stops after srcDiff and validates `diff.xml`.
   This avoids waiting on srcMove while debugging upstream diff generation.

## First Tool To Build

Build `scripts/srcdiff_probe_repo.py` in `srcMove` or the workspace root.

Minimum behavior:

- accept `original/` and `modified/` repository trees
- run srcDiff with `--position --archive --src-encoding UTF-8`
- validate the output XML
- classify failures using the categories above
- bisect file subsets when the full tree fails
- write the minimized repro under `/tmp`
- print the exact command needed to reproduce the failure
