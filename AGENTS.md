# AGENTS.md

Guidance for Codex and other AI agents working in this workspace.

## Workspace Model

This repository is a workspace scaffold, not a monorepo. The sibling
directories `srcML/`, `srcDiff/`, `srcReader/`, `srcMove/`, `srcDispatch/`,
`srcSAX/`, and `srcVisual/` are separate source checkouts and are ignored by the
top-level git repo.

Read [docs/workspace.md](docs/workspace.md) before changing setup scripts,
Docker configuration, build paths, or documentation about repository layout.

## Docker Execution

The intended macOS workflow is:

- edit files on the macOS host with Codex, Neovim, or another editor
- run builds and tests inside the Ubuntu Docker environment
- use the top-level `Makefile` or `bin/srcml-dev-shell` wrapper rather than
  running host-native CMake/Ninja commands

Preferred commands from the workspace root:

```bash
make shell           # enter the Docker workspace manually
make build           # build srcML, srcReader, srcDiff, and srcMove in Docker
make test            # run srcMove tests in Docker
make docker-rebuild  # rebuild the image after Dockerfile changes
```

For one-off commands inside Docker:

```bash
./bin/srcml-dev-shell bash -lc '<command>'
```

Codex usually cannot attach to an already-open interactive Docker shell started
by the user. Use repeatable non-interactive Docker commands for verification.

## Build Order

When building manually inside Docker, use dependency order:

```bash
./build_srcML.sh --yes
./build_srcReader.sh --yes
./build_srcDiff.sh --yes
./build_srcMove.sh --yes
```

`build_srcML.sh` and `build_srcDiff.sh` can clone their upstream repositories if
missing. `build_srcReader.sh` and `build_srcMove.sh` require existing sibling
checkouts.

## Editing Rules

- Do not commit generated build/install/dist directories.
- Do not treat sibling source checkouts as part of the top-level git repo.
- Do not revert user changes in sibling repos or generated docs unless the user
  explicitly asks.
- Keep durable workspace facts in [docs/workspace.md](docs/workspace.md) and
  link to that doc instead of duplicating layout details.

## srcMove

`srcMove` also has its own agent guidance at [srcMove/AGENTS.md](srcMove/AGENTS.md).
When working inside `srcMove`, follow both this file and the nested guidance.
