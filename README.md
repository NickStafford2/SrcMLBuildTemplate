# srcML & srcDiff Build Template

## They’re more what you’d call Guidelines than actual Code

I had trouble getting the **official** srcML and srcDiff build instructions to behave on my machines, so I wrote this script instead.

Think of it as a *friendly guideline* for installing srcML and srcDiff on a normal Debian/Ubuntu Linux setup. You can download these, run them in sequence, and change them where they don't work. Update these templates if requirements change.

## What this project includes

This repo bundles three small scripts:

* `prereq_install_ubuntu.sh`
  Installs all packages needed to build srcML + srcDiff from source (including Kitware’s CMake).
* `build_srcML.sh`
  Builds srcML using its official `ci-ubuntu` preset and installs it locally into a workspace directory.
* `build_srcDiff.sh`
  Builds srcDiff against the locally-installed srcML and handles the *required* submodule updates.

These scripts are meant to make things **reproducible**, **simple**, and **non-destructive**.
Everything installs into your chosen workspace — *no* system-wide pollution.

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

5. Build srcDiff:

   ```bash
   ./build_srcDiff.sh
   ```

   This script:

   * ensures the srcDiff repo exists
   * pulls/update submodules (**mandatory**)
   * configures using `-DsrcML_DIR=.../srcML-install/share/cmake/srcml`
   * builds using Ninja

## Notes & Expectations

* These scripts intentionally reinstall nothing system-wide except CMake (which Ubuntu often ships outdated).
* If you’re using CI, containers, or want a reproducible local build, this setup removes most friction.
* If something breaks, it’s likely upstream — not here.
  At least now you’ll get a readable error instead of a cryptic one.

## Limitations

* Only tested on Ubuntu 24.04/22.04.
* Requires `sudo` once (for package install + Kitware repo).
* The scripts expect a sane workspace layout, but they don’t enforce it — they just use the directory they’re in unless you pass a path explicitly.

## Final Thoughts

These scripts are “guidelines” — not gospel — but if the official instructions let you down, this should get you from zero to a working srcML/srcDiff setup with far fewer headaches.

If you find a bug, feel free to fix it and pretend I wrote it correctly the first time.
