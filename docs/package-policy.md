# Package Policy

XanadOS relies primarily on Arch Linux's official repositories. AUR packages are
only included when no suitable official package exists or specific features are
required. These packages must be prebuilt and added to the local repository so
they can be installed offline during ISO creation.

## When AUR Packages Are Allowed

- No equivalent package is available in the official repos.
- A package provides essential functionality not offered elsewhere.
- The package is actively maintained and considered stable.

Whenever possible, prefer official or community packages. Avoid unnecessary AUR
packages to keep maintenance overhead low.

## Maintaining the Local Repository

Prebuilt AUR tarballs live under `xanados-iso/packages/repo/`. To add or update
packages:

1. Download the package's AUR tarball (e.g. via `paru -G <package>` or from the
   AUR website) and place the resulting `*.tar.gz` archive in
   `xanados-iso/packages/repo/`.

2. Run `xanados-iso/packages/build_repo.sh` to build the packages and refresh
   the repository database. The script extracts each archive, runs `makepkg`, and
   adds the resulting `*.pkg.tar.zst` files to the repo.

3. Commit the updated package files and repository database.

Keep the repository small and only include packages required by the ISO or
installer scripts. Remove outdated packages to avoid bloat.
