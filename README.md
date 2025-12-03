# They’re more what you’d call Guidelines than actual Code

I had trouble getting the **official** srcML and srcDiff build instructions to behave on my machines, so I wrote this script instead.

Think of it as a *friendly guideline* for installing srcML and srcDiff on a normal Debian/Ubuntu Linux setup. Use at your own risk, but it worked on my machine.

## Usage

2. Make the scripts executable:

   ```bash
   chmod +x build_srcML.sh build_srcDiff.sh test_src_tools.sh
   ```

3. Build srcML:

   ```bash
   ./build_srcML.sh
   ```

   This uses the upstream `ci-ubuntu` preset, recompiles,
   and installs srcML locally into:

   ```
   $HOME/Projects/srcWorkspace/srcML-install
   ```

   (So no sudo required.)

4. Build srcDiff:

   ```bash
   ./build_srcDiff.sh
   ```

   This automatically points CMake at your locally installed srcML
   using `-DsrcML_DIR=.../srcML-install/share/cmake/srcml`.

5. Test both tools:

   ```bash
   ./test_src_tools.sh
   ```

   If everything works, you’ll see:

   ```
   [OK] srcml converted a.cpp to XML
   [OK] srcdiff produced diff output
   === All tests passed ===
   ```

## What this script actually does

* Builds srcML using its official preset (ci-ubuntu)
* Redirects the install prefix to a local directory you own
* Builds srcDiff against that local install
* Avoids the need for sudo or system-wide installs
* Runs a small sanity test to ensure both tools work end-to-end

## Optional (if you want global commands)

Add these to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/Projects/srcWorkspace/srcML-install/bin:$PATH"
export PATH="$HOME/Projects/srcWorkspace/srcDiff/build/bin:$PATH"
```

Then you can run:

```bash
srcml --version
srcdiff --help
```

from anywhere.

---

If you want, I can also:

* bundle these steps into a single `ci_build_srcML_srcdiff.sh`
* generate a Makefile
* add colorized output
* create a “one command rebuild both projects” wrapper

Just say the word.
