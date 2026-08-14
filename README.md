# srcML & srcDiff Build Template
Installer for srcML, srcDiff, srcReader, and srcMove developer environments.
Easy to configure for your development environment. Manage all your projects
related to srcML in one place.

## They’re more what you’d call Guidelines

The official srcML and srcDiff build instructions can be extremely difficult to set up. Quirks with Cmake, Ninja, and directories paths are all handled automatically.

Think of it as a *friendly guideline* for installing srcML and srcDiff on a normal Debian/Ubuntu Linux setup. You can download these, run them in sequence, and change them where they don't work. Update these templates if requirements change.

This repository is a workspace scaffold, not a monorepo. The sibling
directories such as `srcML/`, `srcDiff/`, `srcReader/`, and `srcMove/` are
separate git checkouts placed under one workspace so the build scripts can find
their dependencies. See [Workspace Layout](docs/workspace.md) before changing
the directory structure or adding new setup scripts.

## Includes

This repo bundles many scripts:

* `prereq_install_ubuntu.sh`
  Installs all packages needed to build srcML + srcDiff from source (including Kitware’s CMake).
* `build_srcML.sh`
  Builds srcML using its official `ci-ubuntu` preset, installs it locally into a workspace directory, and can generate production package artifacts.
* `build_srcDiff.sh`
  Builds srcDiff against the locally-installed srcML, handles the *required* submodule updates, and can generate production package artifacts.
* `build_srcReader.sh`
  Builds the sibling `srcReader` checkout against the local `srcML-install`.
* `build_srcMove.sh`
  Builds the sibling `srcMove` checkout against `srcReader` and `srcML-install`.
  
Includes configuration for debug adapter protocols.

These scripts are meant to make things **reproducible**, **simple**, and **non-destructive**.
Everything installs into your chosen workspace — *no* system-wide pollution.

## macOS + Docker Development

On macOS, keep this checkout on your normal filesystem and edit it with Neovim,
Codex, or any other Mac editor. Use Docker only for the Ubuntu build
environment.

Build and enter the dev container:

```bash
./bin/srcml-dev-shell
```

The first run builds a local Docker image named `srcml-dev:ubuntu24.04`.
After that, it starts an Ubuntu 24.04 shell with this repo mounted at
`/workspace`.

Inside the container, build the tools in order:

```bash
./build_srcML.sh --yes
./build_srcReader.sh --yes
./build_srcDiff.sh --yes
./build_srcMove.sh --yes
```

Or run the full build sequence from macOS:

```bash
./bin/srcml-dev-build
```

The same workflow is available through `make` targets:

```bash
make shell
make srcmove
make build
make build-dev
make build-release
make build-production
make test
```

`make srcmove` builds srcML, srcReader, srcDiff, and srcMove in dependency order
inside Docker. `make build` is an alias for `make build-release`. Use
`make build-dev` when you want debuggable local binaries for development. Use
`make build-production` when you want the slower release/test/package-oriented
path supported by `srcML` and `srcDiff`.

After changing the `Dockerfile`, rebuild the image with:

```bash
make docker-rebuild
```

Run the installed `srcml` from inside the container:

```bash
srcml --version
srcml --text "int main() { return 0; }" -l C++
```

Run a tool from macOS through Docker:

```bash
./bin/srcml-dev-shell srcml --version
./bin/srcml-dev-shell srcMove --help
```

The container PATH includes the local build/install directories:

```text
/workspace/srcML-install/bin
/workspace/srcDiff/build/bin
/workspace/srcReader/build/bin
/workspace/srcMove/build
```

Your source files stay on macOS. Build outputs are written into this checkout,
so they are visible to Codex and Neovim, but ignored by git.

For the full dependency layout, clone behavior, and path assumptions, see
[Workspace Layout](docs/workspace.md).

## Usage

1. Clone this repo anywhere you want:

   ```bash
   git clone git@github.com:NickStafford2/SrcMLBuildTemplate.git
   cd srcMLBuildTemplate
   ```

2. Make all scripts executable:

   ```bash
   chmod +x prereq_install_ubuntu.sh build_srcML.sh build_srcDiff.sh test_src_tools.sh
   ```

3. Install prerequisites (only needed once per system):

   ```bash
   ./prereq_install_ubuntu.sh
   ```

4. Build srcML:

   ```bash
   ./build_srcML.sh
   ```

   This uses the upstream “ci-ubuntu” CMake preset and installs into:

   ```
   ./srcML-install
   ```

   No sudo, nothing system-wide.

   To make a production srcML build from the currently checked-out development branch:

   ```bash
   ./build_srcML.sh --production
   ```

   This uses the same upstream preset, runs tests, installs locally into `./srcML-install`, and writes CPack artifacts to:

   ```
   ./srcML-dist
   ```

5. Build srcDiff:

   ```bash
   ./build_srcDiff.sh
   ```

   To make a production srcDiff build from the currently checked-out development branch:

   ```bash
   ./build_srcDiff.sh --production
   ```

   This uses the upstream `ci-debian` preset, runs tests, installs locally into `./srcDiff-install`, and writes CPack artifacts to:

   ```
   ./srcDiff-dist
   ```

   For a debug build instead:

   ```bash
   SRCDIFF_DEBUG=1 ./build_srcDiff.sh
   ```

   This script:

   * ensures the srcDiff repo exists
   * pulls/update submodules (**mandatory**)
   * configures using `-DsrcML_DIR=.../srcML-install/share/cmake/srcml`
   * builds optimized `Release` by default in `./srcDiff/build`
   * uses `SRCDIFF_DEBUG=1` or `--debug` for a `Debug` build
   * uses `./srcDiff/build` for both Debug and Release because the upstream
     srcDiff preset fixes the build directory

6. Build srcReader:

   ```bash
   ./build_srcReader.sh
   ```

   This clones `./srcReader` if missing and links it against the local
   `./srcML-install`.

7. Build srcMove:

   ```bash
   ./build_srcMove.sh
   ```

   This clones `./srcMove` if missing. It expects `./srcReader` to already be
   built, and links against `./srcReader/build` and `./srcML-install`.

## Notes & Expectations

* These scripts intentionally reinstall nothing system-wide except CMake (which Ubuntu often ships outdated).
* If you’re using CI, containers, or want a reproducible local build, this setup removes most friction.
* If something breaks, it’s likely upstream — not here.
  At least now you’ll get a readable error instead of a cryptic one.

## Limitations

* Only tested on Ubuntu 24.04/22.04.
* Requires `sudo` once (for package install + Kitware repo).
* The scripts expect a sane workspace layout, but they don’t enforce it — they just use the directory they’re in unless you pass a path explicitly.
* `build_srcML.sh`, `build_srcReader.sh`, `build_srcDiff.sh`, and
  `build_srcMove.sh` can clone their source repos if missing.

## Final Thoughts

These scripts are “guidelines” — not gospel — but if the official instructions let you down, this should get you from zero to a working srcML/srcDiff setup with far fewer headaches.

If you find a bug, feel free to fix it and pretend I wrote it correctly the first time.
