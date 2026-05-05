# Example Commands

This file collects the most useful shell commands for working in `srcMLBuildTemplate`.
It assumes the relevant binaries are already available on your `PATH`.

## First-Time Setup

Install Ubuntu prerequisites:

```bash
./prereq_install_ubuntu.sh
```

Build and install `srcML` locally into this workspace:

```bash
./build_srcML.sh
```

Build `srcDiff` against the local `srcML` install:

```bash
./build_srcDiff.sh
```

Build a debug `srcDiff` in `srcDiff/build-debug`:

```bash
SRCDIFF_DEBUG=1 ./build_srcDiff.sh
```

Build `srcReader`:

```bash
./build_srcReader.sh
```

Build `srcMove`:

```bash
./build_srcMove.sh
```

Run a basic sanity test for `srcml` and `srcdiff`:

```bash
./test_src_tools.sh
```
