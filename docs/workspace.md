# Workspace Layout

`srcMLBuildTemplate` is a workspace scaffold, not a monorepo. It keeps the
installer scripts, Docker setup, local install prefixes, build directories, and
several sibling source repositories in one predictable directory.

The sibling source repositories are independent git checkouts. They are ignored
by this repo's `.gitignore` so Codex, Neovim, and normal git commands can work
on each project without accidentally committing another repository into the
installer repo.

## Expected Directory Structure

```text
srcMLBuildTemplate/
  README.md
  Dockerfile
  bin/
    srcml-dev-shell
    srcml-dev-build
  build_srcML.sh
  build_srcDiff.sh
  build_srcReader.sh
  build_srcMove.sh

  srcML/             upstream srcML checkout
  srcML-build/       generated srcML build tree
  srcML-install/     local srcML install prefix used by downstream tools
  srcML-dist/        optional srcML package artifacts

  srcDiff/           upstream srcDiff checkout
  srcDiff-install/   optional local srcDiff install prefix
  srcDiff-dist/      optional srcDiff package artifacts

  srcReader/         srcReader checkout, required by srcMove
  srcMove/           srcMove checkout
  srcDispatch/       optional related checkout
  srcSAX/            optional related checkout
  srcVisual/         optional related checkout
```

## Repository Roles

`srcMLBuildTemplate` owns the workspace scripts and documentation. It should not
own the source code inside `srcML/`, `srcDiff/`, `srcReader/`, `srcMove/`, or the
other sibling repo directories.

`srcML` parses source code into srcML XML. The local install in
`srcML-install/` provides headers, libraries, CMake config files, and the
`srcml` executable for the rest of the workspace.

`srcDiff` compares two source inputs and emits srcDiff XML. `srcMove` consumes
that XML as its input.

`srcReader` is a C++ support library used by `srcMove` for reading srcML/srcDiff
XML streams.

`srcMove` post-processes srcDiff XML and annotates matched
`diff:delete`/`diff:insert` regions with move metadata.

## Clone Behavior

The build scripts do not all clone their source repositories.

`build_srcML.sh` clones `srcML/` from `https://github.com/srcML/srcML.git` if
the directory does not already exist.

`build_srcDiff.sh` clones `srcDiff/` from `https://github.com/srcML/srcDiff.git`
if the directory does not already exist, then updates srcDiff submodules.

`build_srcReader.sh` expects `srcReader/` to already exist and contain a
`CMakeLists.txt`.

`build_srcMove.sh` expects `srcMove/` to already exist and contain a
`CMakeLists.txt`.

If a future agent needs to recreate a full workspace from scratch, it must know
where the `srcReader` and `srcMove` repositories live before those two build
scripts can succeed.

## Build Order

Build in dependency order:

```bash
./build_srcML.sh --yes
./build_srcReader.sh --yes
./build_srcDiff.sh --yes
./build_srcMove.sh --yes
```

The combined Docker helper runs that sequence:

```bash
./bin/srcml-dev-build
```

`srcMove` tests are Python-driven. The Docker image installs `python3` so the
normal `srcMove/build_and_test` and `python3 test/run_all.py` entry points work
inside the container.

## Important Paths

`srcMove` defaults `WORKSPACE_ROOT` to the parent directory of the `srcMove`
checkout. In this workspace, that means `srcMLBuildTemplate/`.

By default, `srcMove` expects:

```text
../srcReader
../srcReader/build
../srcML-install
```

relative to `srcMove/`.

The top-level `build_srcMove.sh` passes these paths explicitly:

```text
-DWORKSPACE_ROOT=<workspace>
-DSRCREADER_BUILD_DIR=<workspace>/srcReader/build
```

For debug builds, `SRCREADER_DEBUG=1` makes `build_srcMove.sh` link against
`srcReader/build-debug` instead.

## macOS Development Model

On macOS, keep this directory on the normal macOS filesystem. Edit with Neovim,
Codex, or any other Mac tool. Use Docker Desktop only as the Ubuntu build and
runtime environment.

Enter the Ubuntu workspace shell:

```bash
./bin/srcml-dev-shell
```

Run a built tool through Docker from macOS:

```bash
./bin/srcml-dev-shell srcml --version
./bin/srcml-dev-shell srcMove --help
```

The Docker container bind-mounts this checkout at `/workspace`, so generated
build outputs remain visible to macOS tools. Those outputs are ignored by git.

For the most accurate C++ language-server diagnostics, run `clangd` inside the
Docker environment. Running macOS `clangd` against Linux-generated
`compile_commands.json` can produce noisy diagnostics because include paths,
library paths, and compiler behavior differ.
