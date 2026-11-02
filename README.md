# SrcMLBuildTemplate

Workspace scaffold for building srcML, srcReader, srcDiff and srcMove in Ubuntu
Docker, with srcDiffVisual and a separate private thesis workspace alongside.

The source repositories are independent Git checkouts. Committing this scaffold
saves its setup scripts and documentation; it does not save their contents.
[Workspace Layout](docs/workspace.md) is the canonical directory and dependency
reference.

## Recover this workspace on another Mac

Install Git, Python 3.9+ and Docker Desktop, start Docker, and restore GitHub SSH
access. Run these commands on the Mac host:

```bash
git clone git@github.com:NickStafford2/SrcMLBuildTemplate.git SrcMLBuildTemplate
cd SrcMLBuildTemplate
./bin/workspace-recover --include-thesis          # preview missing clones
./bin/workspace-recover --include-thesis --apply  # requires private thesis access
./bin/workspace-recover --include-thesis --verify
make build
./bin/srcml-dev-shell ./test_src_tools.sh
```

Omit `--include-thesis` for the public software environment. The helper uses the
tracked [recovery snapshot](workspace.recovery.json), pins newly cloned source
trees, and leaves existing directories unchanged. It does not install packages,
build tools, restore ignored evidence, or run analyses. Read the complete
[recovery procedure](docs/workspace.md#recover-on-another-mac) for evidence
restoration, optional viewer startup, limitations, and historical locked builds.

## Daily commands

Edit on the Mac; run native builds and tests in Docker:

```bash
make shell              # interactive Ubuntu development shell
make build              # release toolchain; recreates native build directories
make build-dev          # debug toolchain
make test               # srcMove correctness suite
make docker-rebuild     # after workspace Docker dependency changes
./bin/srcml-dev-shell srcMove --help
```

The first Docker command builds the development image. Generated files remain
visible in the mounted workspace. The build scripts' `--yes` option permits
cleaning their generated build directories, not source repositories. Do not
store irreplaceable files in build trees.

## Contents

| Location | Purpose |
| --- | --- |
| `Dockerfile`, `Makefile`, `bin/srcml-dev-*` | Linux environment and build/test entry points |
| `build_src*.sh`, `utils.sh` | Dependency-specific build scripts; see [build modes](docs/workspace.md#build-modes) |
| `bin/build-*` | Launch already-built native tools; these do not build them |
| `bin/history-workflow`, `bin/srcdiffvisual-history-refresh` | Workspace history-analysis and evidence-export commands |
| `workspace.recovery.json`, `bin/workspace-recover` | Observed multi-repository source snapshot and missing-checkout recovery |
| `workspace.lock.json`, `bin/workspace-lock` | Older four-tool revision lock and its inspection/capture interface |
| `docs/` | Canonical workspace documentation and command examples |
| `tests/` | Host-side recovery safety checks: `python3 -m unittest discover -s tests` |
| `sample_debug_tools/`, `setup-clangd.sh` | Optional editor/debugger examples; adapt to your editor and paths |
| `prereq_install_ubuntu.sh` | Native Ubuntu setup alternative; do not run this on macOS |

The optional `build_srcDiffVisual.sh` is a Python/npm environment installer,
not the recommended Docker viewer startup. The root development image does not
supply its npm/venv prerequisites. Follow the viewer's
[own setup guide](srcDiffVisual/README.md#run-locally-with-docker).
`build_srcDispatch.sh` is an explicit placeholder outside the supported build
chain. srcSAX and srcDispatch are optional reference projects.

After committing and pushing changes in the independent repos, run
`./bin/workspace-recover --capture`, then commit the root setup and updated
snapshot. See the [recovery guide](docs/workspace.md#recover-on-another-mac).

## Documentation

- [Workspace layout, recovery, build modes and runtime paths](docs/workspace.md)
- [Build command entry points](docs/build_commands.md)
- [Tool usage examples](docs/example_commands.md)
- [Documentation policy](docs/documentation_policy.md)
- [Agent operating instructions](AGENTS.md)

## Recovery limits

The snapshot records observed sources, not a newly tested clean-machine build.
Docker base images, OS packages and external services are not frozen to those
source commits. Rebuild binaries and check outcomes; source recovery alone does
not establish identical executable bytes or experimental timings. Benchmark
inputs, retained results, Git stashes and ignored local files need their own
preservation decisions. The private thesis guide describes the evidence already
retained; old live history analyses can be rerun.
