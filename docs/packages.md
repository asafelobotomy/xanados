# Custom Package Workflow

PKGBUILD directories can be placed under `packages/<name>`.
When `scripts/build_iso.sh` runs, it will invoke
`scripts/build_packages.sh` to build these packages if
`packages/repo` does not already contain package archives.
The resulting `*.pkg.tar.zst` files are copied into
`packages/repo` and added to the local repository used by the ISO
build.

Use standard Arch tooling when authoring `PKGBUILD`s. `scripts/build_packages.sh`
installs any missing build dependencies (including `namcap`) using `sudo pacman`
so the script itself can run unprivileged for most operations:

```bash
namcap PKGBUILD
makepkg --verifysource
```

After creating a package directory, simply run the ISO build script and
the package will be built automatically.
