# Build Commands

Run these commands from the workspace root on the macOS host after installing
Git and Docker Desktop and starting Docker. See [Workspace Layout](workspace.md)
for repository restoration, branch selection, dependencies, and build paths;
[Backup and Recovery](workspace.md#backup-and-recovery) covers a new computer.

## Build and Test

```bash
make build           # optimized srcML, srcReader, srcDiff, and srcMove in Docker
make test            # srcMove test suite in Docker
make build-dev       # debug development build
make build-production # tests/packages where supported
```

The build helpers can clone missing native-tool repositories. They do not
restore a saved revision automatically; restore the intended checkouts before
building. srcDiff uses `srcDiff/build` for both Debug and Release. srcReader
and srcMove use `build-debug` for Debug and `build` for Release. Consult
[Build Modes](workspace.md#build-modes) before mixing configurations.

Check that the built tools start:

```bash
./bin/srcml-dev-shell srcml --version
./bin/srcml-dev-shell srcdiff --help
./bin/srcml-dev-shell srcMove --help
```

For manual native-tool commands, enter `make shell` and use the dependency-order
commands in [Build Order](workspace.md#build-order). The Ubuntu prerequisite
installer is for native Ubuntu setup; it is not a macOS setup step.

## Viewer

The viewer belongs to `srcDiffVisual/`. Follow its
[Docker quick start](../srcDiffVisual/README.md#run-locally-with-docker), including
frontend development instructions. Its Compose environment supplies the frontend
and Python dependencies separately from the root native-tool development image.
