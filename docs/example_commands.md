# Example Commands

This file collects the most useful shell commands for working in `srcMLBuildTemplate`.
It assumes the relevant binaries are already available on your `PATH`.

## `srcml` Basics

Convert source code to srcML XML:

```bash
srcml file.cpp -o file.cpp.xml
```

Convert a whole directory into a srcML archive:

```bash
srcml my_project/ -o project.xml
```

Convert a string snippet into srcML:

```bash
srcml --text "int a;" -l C++ -o snippet.xml
```

Add line and column positions to generated XML:

```bash
srcml --position file.cpp -o file.cpp.xml
```

Convert srcML XML back to source code:

```bash
srcml --output-src file.cpp.xml -o file.cpp
```

Convert srcML XML back to source code and print to stdout:

```bash
srcml --output-src file.cpp.xml
```

Extract all source files from a plain srcML archive:

```bash
srcml --output-src --to-dir out_src project.xml
```

Extract one unit from a plain srcML archive:

```bash
srcml --output-src --unit 3 project.xml
```

Show how many units are in an archive:

```bash
srcml --show-unit-count project.xml
```

## `srcdiff` Basics

Generate a diff XML for two files:

```bash
srcdiff original.cpp modified.cpp -o diff.xml
```

Generate a diff XML with position metadata:

```bash
srcdiff --position original.cpp modified.cpp -o diff_pos.xml
```

Generate a diff archive for two directories:

```bash
srcdiff original_dir modified_dir -o diff.xml
```

Generate a colorized unified diff in the terminal:

```bash
srcdiff --unified original.cpp modified.cpp
```

Generate a side-by-side diff in the terminal:

```bash
srcdiff --side-by-side 8 original.cpp modified.cpp
```

Generate an HTML diff view:

```bash
srcdiff --unified --html original.cpp modified.cpp -o diff.html
```

Ignore whitespace while diffing:

```bash
srcdiff --ignore-space original.cpp modified.cpp -o diff.xml
```

Ignore all whitespace while diffing:

```bash
srcdiff --ignore-all-space original.cpp modified.cpp -o diff.xml
```

Ignore comments while diffing:

```bash
srcdiff --ignore-comments original.cpp modified.cpp -o diff.xml
```

Read file pairs from a list:

```bash
srcdiff --files-from pairs.txt -o diff.xml
```

Example `pairs.txt` format:

```text
old/foo.cpp|new/foo.cpp
old/bar.cpp|new/bar.cpp
```

## Converting Existing `srcdiff` XML Back to Source

Important:

- `srcdiff` creates a `srcdiff` XML file.
- `archive_reader` extracts source or srcML from an existing `srcdiff` XML file.
- In this repo's tooling, revisions are numbered `0` and `1`.
- Old docs sometimes call those "revision 1" and "revision 2".

Mapping:

- Old "revision 1" = original = `--revision=0`
- Old "revision 2" = modified = `--revision=1`

### Single-File `srcdiff`

If `foo.srcdiff.xml` contains one unit, extract the original version:

```bash
archive_reader --unit=1 --revision=0 --output-src foo.srcdiff.xml
```

Extract the modified version:

```bash
archive_reader --unit=1 --revision=1 --output-src foo.srcdiff.xml
```

Write those to files:

```bash
archive_reader --unit=1 --revision=0 --output-src foo.srcdiff.xml > foo.rev1.cpp
archive_reader --unit=1 --revision=1 --output-src foo.srcdiff.xml > foo.rev2.cpp
```

### Archive `srcdiff`

Show archive-level info:

```bash
archive_reader --info foo.srcdiff.xml
```

Show unit-level info for a specific file:

```bash
archive_reader --info --unit=3 foo.srcdiff.xml
```

Extract unit 3, original version:

```bash
archive_reader --unit=3 --revision=0 --output-src foo.srcdiff.xml
```

Extract unit 3, modified version:

```bash
archive_reader --unit=3 --revision=1 --output-src foo.srcdiff.xml
```

Loop through an archive and extract the original version of every unit:

```bash
mkdir -p rev1
for i in 1 2 3 4 5; do
  name=$(archive_reader --info --unit="$i" foo.srcdiff.xml | rg '"filename"' | sed 's/.*"filename": "\(.*\)".*/\1/')
  archive_reader --unit="$i" --revision=0 --output-src foo.srcdiff.xml > "rev1/$name"
done
```

Loop through an archive and extract the modified version of every unit:

```bash
mkdir -p rev2
for i in 1 2 3 4 5; do
  name=$(archive_reader --info --unit="$i" foo.srcdiff.xml | rg '"filename"' | sed 's/.*"filename": "\(.*\)".*/\1/')
  archive_reader --unit="$i" --revision=1 --output-src foo.srcdiff.xml > "rev2/$name"
done
```

Note:

- There is no direct `srcdiff` command that takes an existing `foo.srcdiff.xml` and emits "revision 1 source" or "revision 2 source".
- In this workspace, that extraction step is done with `archive_reader`.

## `srcMove` Commands

Run `srcMove` on a `srcdiff` file and write a new annotated XML:

```bash
srcMove/build/srcMove diff.xml diff_new.xml
```

Run `srcMove` and print to stdout:

```bash
srcMove/build/srcMove diff.xml
```

Render `srcdiff` regions in a text-oriented debug format:

```bash
srcMove/build/srcdiff_render diff.xml
```

Highlight `srcdiff` regions in the terminal:

```bash
srcMove/build/srcdiff_highlight diff.xml
```

Highlight `srcdiff` regions using position-aware logic:

```bash
srcMove/build/srcdiff_highlight_pos diff.xml
```

Run the canonical subtree unit test executable:

```bash
srcMove/build/test_canonical_subtree_unit
```

## Frontend Commands

Run the `srcMove` frontend dev server:

```bash
cd srcMove/frontend
npm run dev
```

Build the frontend:

```bash
cd srcMove/frontend
npm run build
```

Preview the production frontend build:

```bash
cd srcMove/frontend
npm run preview
```

## Useful End-to-End Examples

Generate a diff with positions, annotate it with `srcMove`, then inspect it:

```bash
srcdiff --position original.cpp modified.cpp -o diff_pos.xml
srcMove/build/srcMove diff_pos.xml diff_new.xml
srcMove/build/srcdiff_render diff_new.xml
```

Generate a directory diff and inspect the archive contents:

```bash
srcdiff original_dir modified_dir -o project_diff.xml
archive_reader --info project_diff.xml
archive_reader --info --unit=1 project_diff.xml
```

Extract one file's original and modified versions from a directory diff:

```bash
archive_reader --unit=1 --revision=0 --output-src project_diff.xml > original_unit.cpp
archive_reader --unit=1 --revision=1 --output-src project_diff.xml > modified_unit.cpp
```
