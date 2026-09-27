# AGENTS.md

Guidance for Codex and other AI agents working in this workspace.

## Immediate Priority

The master's thesis is the primary workspace objective. As of 2026-09-26, it
is due in seven days. Prioritize work that directly improves the thesis,
validates its claims, completes required experiments, or prepares professional
review material. Defer unrelated cleanup and speculative features unless they
unblock the thesis.

Urgency does not relax the evidence standard. Do not invent results,
citations, implementation behavior, novelty claims, or conclusions. Keep
exploratory results visibly separate from final evidence.

## Workspace Model

This repository is a workspace scaffold, not a monorepo. The sibling
directories `srcML/`, `srcDiff/`, `srcReader/`, `srcMove/`, `srcDispatch/`,
`srcSAX/`, and `srcDiffVisual/` are separate source checkouts and are ignored by the
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

`build_srcML.sh`, `build_srcReader.sh`, `build_srcDiff.sh`, and
`build_srcMove.sh` can clone their source repositories if missing.

## Editing Rules

- Do not commit generated build/install/dist directories.
- Do not treat sibling source checkouts as part of the top-level git repo.
- Do not revert user changes in sibling repos or generated docs unless the user
  explicitly asks.
- Keep durable workspace facts in [docs/workspace.md](docs/workspace.md) and
  link to that doc instead of duplicating layout details.
- Follow [the documentation policy](docs/documentation_policy.md) when creating
  or reorganizing documentation across the workspace repositories.

## srcMove

`srcMove` also has its own agent guidance at [srcMove/AGENTS.md](srcMove/AGENTS.md).
When working inside `srcMove`, follow both this file and the nested guidance.

## Thesis and Repository Roles

- `thesis-workspace/` is the private thesis repository and the default location
  for current thesis work. The AI reference draft lives in
  `thesis-workspace/thesis-draft-ai/`; Nicholas's working outline and drafts
  live in `thesis-workspace/thesis-draft-final/`. Bibliography data, references,
  notes, and research evidence remain in their corresponding private directories.
- `thesis-workspace/references/decker/DeckerDissertation.docx` is the immutable
  Word formatting authority. Michael Decker explicitly instructed the user to
  use his dissertation as the starting point.
- `thesis-workspace/thesis-final/` is a separate public Git repository visible
  to professors. Only polished `Thesis.docx`, its matching Word-exported
  `Thesis.pdf`, and minimal professional guidance belong there.
- `srcMove/` is the principal thesis subject and the user's primary research
  contribution. Most implementation, evaluation, and technical verification
  work should focus here.
- `srcDiffVisual/` is a companion visualization system created by the user. It
  supports inspection and explanation of srcDiff and srcMove results.
- `srcReader/` is a supporting library that the user has modified for the
  srcMove toolchain.
- `srcDiff/` supplies the structured differences consumed by srcMove.
- `srcML/` supplies the source-code XML representation used by srcDiff and the
  downstream tools.

The core research flow is:

```text
source code -> srcML -> srcDiff -> srcMove -> srcDiffVisual
```

Work in the repository that owns the fact or implementation being changed.
Thesis prose belongs in the private thesis workspace; code and canonical
technical documentation belong in the relevant source repository.

## Continuous Improvement

- Proactively suggest improvements that materially strengthen the thesis,
  documentation, experiments, or repository clarity within the deadline.
- Prefer elegant, simple, understandable solutions and established best
  practices.
- Keep one source of truth for each durable fact. Link to canonical documents
  instead of duplicating them.
- Keep guidance brief, fix confusing or stale documentation encountered during
  normal work, and call out blockers early.
