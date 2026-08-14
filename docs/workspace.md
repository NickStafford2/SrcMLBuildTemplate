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
  build_srcVisual.sh

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
  srcVisual/         visualization application for srcDiff/srcMove results
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

`srcVisual` is a downstream inspection application for srcDiff and srcMove. Its
Python backend prepares uploaded srcDiff/srcMove XML and its React frontend
shows synchronized XML, tree, source-code, diff, and move views. It exists
because move results, especially moves across files, are difficult to validate
from XML alone.

The main data flow is:

```text
source code -> srcML XML -> srcDiff XML -> srcMove annotations -> srcVisual
```

`srcMove` is the primary research project and master's thesis deliverable.
`srcVisual` supports that research by making its results understandable and
inspectable; it may also evolve into a separately hosted application.

## Clone Behavior

The standard bootstrap scripts clone their source repositories when the expected
directory is missing.

`build_srcML.sh` clones `srcML/` from `https://github.com/srcML/srcML.git` if
the directory does not already exist.

`build_srcDiff.sh` clones `srcDiff/` from `https://github.com/srcML/srcDiff.git`
if the directory does not already exist, then updates srcDiff submodules.

`build_srcReader.sh` clones `srcReader/` from
`https://github.com/srcML/srcReader.git` if the directory does not already
exist. Until the pending upstream changes are merged, it checks out the
`mover` branch. Override the source or branch with `SRCREADER_REPO_URL` or
`SRCREADER_BRANCH` when needed.

`build_srcMove.sh` clones `srcMove/` from
`https://github.com/NickStafford2/srcMove.git` if the directory does not already
exist. Override with `SRCMOVE_REPO_URL` when needed.

`build_srcVisual.sh` clones `srcVisual/` from
`https://github.com/NickStafford2/srcVisual.git` if the directory does not
already exist. Override with `SRCVISUAL_REPO_URL` when needed. It installs the
Python backend into `srcVisual/.venv` and builds the React frontend into
`srcVisual/frontend/dist`.

`build_srcDispatch.sh` is intentionally not part of the standard bootstrap path
yet. It exits with a clear message instead of sourcing missing placeholder
files.

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

`srcMove` owns its build and test interface as an independent repository. The
workspace-level `make test` enters Docker and delegates to `make test` inside
srcMove. Its Makefile builds with CMake and invokes the Python test runner.

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

The root Docker environment exists specifically to isolate the complete srcML
toolchain from macOS while keeping every checkout and generated artifact
accessible to host-side editors and Codex. Builds, tests, and Linux-specific
diagnostics should run inside that environment rather than using host-native
CMake, compilers, Python environments, or Node installations.

Codex normally cannot attach to an interactive shell that a developer already
opened. For repeatable testing and diagnosis, it should invoke non-interactive
commands through `bin/srcml-dev-shell` or use the top-level `make` targets.

Enter the Ubuntu workspace shell:

```bash
./bin/srcml-dev-shell
```

The `Makefile` provides easier-to-remember aliases:

```bash
make shell           # enter Docker
make build           # alias for make build-release
make build-dev       # debuggable development build
make build-release   # optimized local build
make build-production # release/test/package path where supported
make test            # run srcMove tests in Docker
make docker-rebuild  # rebuild image after Dockerfile changes
```

Use `make docker-rebuild` after editing `Dockerfile` or changing system-level
dependencies such as compilers, libraries, or Python packages.

## Build Modes

Use `make build-dev` for day-to-day debugging. It builds `srcReader`,
`srcDiff`, and `srcMove` with `CMAKE_BUILD_TYPE=Debug` where the local scripts
support it. `srcMove` links against `srcReader/build-debug` in this mode.

Use `make build-release` or `make build` for the normal optimized local build.
This is the default path and writes the binaries used by the workspace PATH.

Use `make build-production` when you want the release-oriented path that runs
tests and generates package artifacts where supported. Today, `srcML` and
`srcDiff` support production package/test behavior; `srcReader` and `srcMove`
are built as release dependencies.

`srcDiff` is an exception to the separate-directory convention: its upstream
CMake preset uses `srcDiff/build` as the build directory, so Debug and Release
srcDiff builds overwrite that same directory.

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
