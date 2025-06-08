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

Prebuilt AUR packages live under `xanados-iso/packages/repo/`. To add or update
packages:

1. On an Arch-based system, clone the package's PKGBUILD and build it:

   ```bash
   git clone <aur-url>
   cd <package>
   makepkg -s
   ```

2. Copy the resulting `*.pkg.tar.zst` file(s) into `xanados-iso/packages/repo/`.

3. From inside that directory, update the repository database:

   ```bash
   repo-add xanados.db.tar.gz *.pkg.tar.zst
   repo-add xanados.files.tar.gz *.pkg.tar.zst
   ```

4. Commit the new package files and updated database.

Keep the repository small and only include packages required by the ISO or
installer scripts. Remove outdated packages to avoid bloat.
