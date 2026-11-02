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
  build_srcDiffVisual.sh

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
  srcDiffVisual/         visualization application for srcDiff/srcMove results
  thesis-workspace/  independent private thesis workspace repository
    thesis-final/    independent, public professor-facing thesis checkout
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

`srcDiffVisual` is a downstream inspection application for srcDiff and srcMove. Its
Python backend prepares uploaded srcDiff/srcMove XML and its React frontend
shows synchronized XML, tree, source-code, diff, and move views. It exists
because move results, especially moves across files, are difficult to validate
from XML alone.

`thesis-workspace/` is an independent private Git repository for thesis drafts,
references, scratch notes, formatting work, and research evidence. It is
ignored by this scaffold.

`thesis-workspace/thesis-final/` is the independent public Git checkout used
for professor-facing, review-ready thesis material. Its commits and build
artifacts belong to that checkout, not to either containing repository. Draft
and reference material belongs to the private parent workspace, not to srcMove
or the public final repository.

The main data flow is:

```text
source code -> srcML XML -> srcDiff XML -> srcMove annotations -> srcDiffVisual
```

## Backup and Recovery

Saving this root repository saves the workspace setup, not the entire directory
on disk. A local commit is recoverable from GitHub only after it is pushed.

| Material | Where to save it | Local cleanup |
| --- | --- | --- |
| Root scripts, Docker configuration, Makefile, docs, agent guidance, lockfile | This repository | Commit intentional changes, including new scripts referenced by Make targets. |
| Source changes in independent checkouts | Each owning repository; use a personal GitHub fork if upstream is not writable | Commit and push separately. |
| Thesis drafts, references, notes, research evidence | Private `thesis-workspace` repository or a separately verified private backup for large/restricted files | Review ignored files too; root Git never saves them. |
| Polished public thesis documents | Independent `thesis-workspace/thesis-final` repository | Follow its publication rules. |
| Build/install/dist trees, caches, virtual environments | Recreate from saved source | Usually disposable; first preserve any unique research evidence. |
| Root `build/selection-coverage-map/` | Generated srcMove test diagnostics; retain selected evidence privately if needed | Ignored here; retained locally until reviewed. |

### Before losing access to this computer

For each independent repository listed above, inspect `git status --short`,
`git status --short --ignored`, `git remote -v`, and `git branch -vv` from its
own directory. Review untracked files before committing; ignored files do not
appear in an ordinary status check. Save the chosen remote URL, branch, and full
commit ID (`git rev-parse HEAD`) in the private thesis workspace for recovery.
Review file contents before publishing private material or credentials.

After committing reviewed files, push the intended branch to a writable GitHub
remote. For a branch named `main` and remote named `origin`, for example:

```bash
git push -u origin main
git rev-parse HEAD
git ls-remote origin refs/heads/main
```

The last two commands must show the same commit ID. Substitute the actual
branch and remote for each repository. A cached `origin/main`, a clean working
tree, or a lockfile entry alone does not verify an off-computer backup. Confirm
that important files are tracked and that private repositories can be accessed
from another computer. Save account recovery credentials separately from Git.

Export important history evidence with `make history-export REPO=<repository>`
before saving it in the private thesis repository. Exporting only copies files
locally; it does not commit or upload them. Preserve original analysis state if
needed to resume work: an evidence ZIP is not by itself a verified restoration
of the entire live workspace. Large datasets and ignored experiment archives
need a separate backup decision; do not force-add every generated directory.

### Recover on another Mac

1. Install Git and Docker Desktop, start Docker, and restore GitHub access.
2. Clone the scaffold:

   ```bash
   git clone git@github.com:NickStafford2/SrcMLBuildTemplate.git SrcMLBuildTemplate
   cd SrcMLBuildTemplate
   ```

3. Install Python 3 on the host and preview the saved source recovery:

   ```bash
   ./bin/workspace-recover --include-thesis
   ./bin/workspace-recover --include-thesis --apply
   ./bin/workspace-recover --include-thesis --verify
   ```

   Omit `--include-thesis` to recover only the five software checkouts. Private
   thesis access and access to the public final-document repository are needed
   for the complete recovery. The helper reads `workspace.recovery.json`, clones
   missing directories, and selects the recorded branch and full commit only
   in newly cloned repositories. It restores the srcDiff personal profiler
   branch as well. Existing directories are never switched or overwritten;
   mismatches are reported for review. If a clone is interrupted, review its
   partial directory before retrying. Verification is local: it checks tracked
   cleanliness, origin, branch and commit IDs, not ignored/untracked files or
   live GitHub.
4. The recovery snapshot records the observed November 2, 2026 sources across
   seven independent repositories. It is separate from the older four-tool
   `workspace.lock.json`; its commits are observations, not a newly validated
   compatibility milestone. Run `make lock-status` to inspect that older lock.
   For an older locked environment, manually check out
   the four commits in `workspace.lock.json` and run `make lock-verify`.
   The lock helper does not clone or check out anything, and does not cover
   srcDiffVisual or either thesis repository. Do not update the lock just to
   hide a recovery mismatch.
   The srcReader builder normally selects `mover`; for a detached historical
   build, create a local branch at the locked srcReader commit and supply its
   name inside Docker, for example
   `./bin/srcml-dev-shell bash -lc 'SRCREADER_BRANCH=locked-reader ./bin/srcml-build-srcmove'`.
   Do not run the default builder after pinning a different reader revision.
5. Run `make build`, then `./bin/srcml-dev-shell ./test_src_tools.sh` from the
   host. Docker recreates the Linux environment and generated native outputs.
   Run `make test` for correctness; preserve and investigate failures rather than
   assuming historical pass counts describe the restored checkout. The build
   scripts clean generated build directories and do not restore old binaries.
6. In the private thesis checkout, follow its README to verify and restore the
   retained evidence archive. Old live `.srcmove*` analysis state is intentionally
   rerunnable. External BigCloneBench/IJaDataset installation is a separate
   prerequisite for new dataset experiments, not for inspecting saved evidence.
7. Follow [srcDiffVisual's setup guide](../srcDiffVisual/README.md#run-locally-with-docker)
   to prepare reference clones and mounts before starting the viewer. Its
   Compose services require the workspace-built `srcMove/build/srcMove` file;
   building the application image alone does not create that host bind source.
   Frontend/backend dependencies belong to the viewer's Docker stages, not the
   root development image. The viewer can start fresh and analyses can be rerun.

To establish a newer recovery baseline, commit and push changes in the source
and thesis repos, then run `./bin/workspace-recover --capture` and commit the
updated snapshot with the root setup. Capture requires clean tracked files and
named branches in all seven checkouts; it does not check remote availability or
save untracked files. Do not move the historical four-tool lock simply to match
it. GitHub SSH keys live on the host; Docker does
not inherit the host's SSH agent. Cloning these checkouts on the host avoids
requiring private-repository credentials in build containers.

The build scripts can clone missing dependencies, but do not restore recorded
revisions automatically. Use the recovery helper before building a saved setup.

## Locked Source Revisions

The tracked `workspace.lock.json` records an older set of exact srcML, srcDiff,
srcReader and srcMove revisions. It does not match the current observed recovery
snapshot or prove a fresh build. It coordinates the independent
repositories without making them part of the top-level Git repository.

Use the top-level Make targets to inspect or update it:

```bash
make lock-status  # report differences without failing
make lock-verify  # fail unless every checkout matches
make lock-update  # capture the current revisions; refuses tracked changes
```

Commit hashes are authoritative. Branch names and tool `--version` output are
not sufficient because branches move and displayed versions may lag development
commits. Verification compares the full commit, the `origin` repository, and
tracked working-tree changes. Equivalent GitHub SSH and HTTPS origins compare as
the same repository.

The lockfile describes source checkouts, not generated binaries. A run-time
snapshot of the lockfile, checkout, and binary checksum still cannot prove that
the binary was built from those sources. Benchmark runs should use a receipt
emitted by the build when a verified source-to-binary binding is required, and
otherwise label that binding as unverified. Run manifests should preserve the
lockfile checksum, observed binary checksums, and provenance status so stale
build artifacts cannot be mistaken for locked builds.

`srcMove` is the primary research project and master's thesis deliverable.
`srcDiffVisual` supports that research by making its results understandable and
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

`build_srcDiffVisual.sh` clones `srcDiffVisual/` from
`https://github.com/NickStafford2/srcVisual.git` if the directory does not
already exist. Override with `SRCDIFFVISUAL_REPO_URL` when needed. It installs the
Python backend into `srcDiffVisual/.venv` and builds the React frontend into
`srcDiffVisual/frontend/dist`.

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

The workspace image includes `python3-lxml` for full XPath evaluation of
srcReader locators in benchmark consumers. Rebuild the image after updating
this dependency; JSON-only results admission uses the Python standard library.

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
make srcmove         # build srcMove and its dependency chain
make build           # alias for make build-release
make build-dev       # debuggable development build
make build-release   # optimized local build
make build-production # release/test/package path where supported
make test            # run srcMove tests in Docker
make history-scaling \
  CASE=sqlite START=<commit> COUNT=300 JOBS=1,2,4 # benchmark history scaling
make srcdiffvisual-eval-check # verify the build/mount path without an analysis
make srcdiffvisual-eval-fast  # develop against 10 Notepad++ pairs by default
make srcdiffvisual-eval-400   # run the fixed research evaluation
make docker-rebuild  # rebuild image after Dockerfile changes
```

For a repeatable repository-history study, use:

```bash
make history-new REPO=notepadpp COUNT=100  # rebuild, archive old state, recreate
make history-more REPO=notepadpp COUNT=100 # add another 100 using frozen tools
make history-status REPO=notepadpp         # inspect coverage and failures
make history-export REPO=notepadpp         # save an immutable thesis snapshot
```

Run these targets from the workspace root on the macOS host. `history-more`,
`history-status`, and `history-export` also work inside the Linux development
shell, from either `/workspace` or `/workspace/srcMove`. In that shell they call
the local Python CLI directly; Docker is not needed inside Docker. `history-new`
requires the host because it rebuilds the viewer image and restarts services.
The viewer's Compose environment trusts only its configured Git worktree
mounts, allowing the viewer and development shell to share them under different
Linux users.

`REPO=sqlite`, `REPO=opencv`, or `REPO=linux` selects another configured reference
repository. Linux retains its configured `kernel/` scope when recreated. `HISTORY_JOBS=4`
is the default parallelism. A recreation keeps the previous starting commit;
`START=<full-commit>` deliberately changes it. `history-new` forces a native
srcMove rebuild and rebuilds the viewer image, preserves old state in a dated
`.srcmove-archive-*` directory, and starts the viewer at
<http://127.0.0.1:5000>. Finish other history commands before recreating state.
`history-more` never rebuilds or changes admitted tool copies. Interrupted work
is checkpointed; use the CLI's absolute `run --pairs N` target to finish the
original target before requesting another increment.

The History screen also provides an **Analyze 100 more** action and a
**Save thesis snapshot** action. Recreation, completed browser extensions, and completed
command-line extensions publish snapshots to
`thesis-workspace/data/srcMove-history/<repository>/`. Browser downloads contain
the same bytes. Snapshot contents and evidence limits are documented in
[srcMove history runtime](../srcMove/srcmove_history/docs/runtime.md), and the
viewer workflow in [History browser](../srcDiffVisual/docs/history-browser.md).

Both services bind-mount the workspace native srcMove and its Python history
and runtime modules. Recreate the analysis after changing these modules or the
algorithm; rebuild the viewer image after backend or frontend changes.
Generated `srcDiff/profile-build` output is excluded from the Docker context.

After changing the srcMove algorithm, `make srcdiffvisual-eval-fast` incrementally
rebuilds the Linux `srcMove/build/srcMove` target in the workspace development
container. srcDiffVisual bind-mounts that exact executable into both Compose
services and Compose one-off containers, avoiding a rebuild of the complete
application image. The command prints the srcMove checkout state, build receipt,
and mounted srcMove/srcDiff checksums before doing work. Override the small
sample with `SRCDIFFVISUAL_FAST_PAIRS=...` and worker count with
`SRCDIFFVISUAL_JOBS=...`.

`make srcdiffvisual-eval-400` always requests exactly the newest 400 adjacent
Notepad++ commit pairs. An existing analysis is reused only when its admitted
srcMove and srcDiff checksums match the current mounted tools. Otherwise it is
moved to a checksum- and timestamp-labeled `.srcmove-archive-*` directory and a
new `.srcmove` analysis retains the prior configuration. Archives are never
deleted or overwritten. The shorter `make srcdiffvisual-history-refresh` target
is an alias for this fixed evaluation.

Use `make srcdiffvisual-eval-check` to build and verify both service mounts without
starting services or an analysis. Use `make srcdiffvisual-image-rebuild`, or add
`FULL_REBUILD=1` to an evaluation command, after changing srcDiffVisual application
code, `srcmove_history` Python code, the Dockerfile, or native dependencies.
The evaluation leaves srcDiffVisual running at <http://127.0.0.1:5000>.

The controlled study and its saved artifact layout are documented in the
[srcMove History scaling guide](../srcMove/srcmove_history/benchmarks/README.md).

`make srcmove` is the focused installation path for srcMove. It builds srcML,
srcReader, srcDiff, and srcMove in dependency order inside Docker without
requiring those tools to be installed directly on macOS.

Use `make docker-rebuild` after editing `Dockerfile` or changing system-level
dependencies such as compilers, libraries, or Python packages.

## srcDiff Runtime Linking

Use `srcDiff/build/bin/srcdiff` for local Docker development and benchmarks. It
retains a RUNPATH to `srcML-install/lib` and is the srcDiff executable placed on
the container `PATH`.

The optional `srcDiff-install/bin/srcdiff` loses that RUNPATH during
`cmake --install`. The development container therefore configures the local
srcML library prefix explicitly:

```bash
LD_LIBRARY_PATH=/workspace/srcML-install/lib
```

This makes locally installed workspace tools runnable without embedding an
absolute `/workspace` RUNPATH in production packages. It is workspace runtime
configuration, not a workaround for an srcML library failure.

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
