==============================
Xanados PR #49: Failed Checks & PKGBUILD Suggestions (Detailed)
==============================

I. Failed Checks Breakdown and Solutions
----------------------------------------

1. Markdown Lint (.github/workflows/markdownlint.yml)
-----------------------------------------------------
Summary of Errors:
- AGENTS.md:207:4 MD034/no-bare-urls: Bare URL used.
- packages/calamares/README.md:1:81 MD013/line-length: Line exceeds 80 characters.
- packages/calamares/README.md:1 MD041/first-line-heading/first-line-h1: First line should be a top-level heading.
- packages/calamares/README.md:2:81 MD013/line-length: Line exceeds 80 characters.
- README.md:45:81, 46:81, 47:81 MD013/line-length: Lines exceed 80 characters.

Detailed Solutions:
- MD034/no-bare-urls (AGENTS.md:207:4):
  - Problem: You have a plain URL in your Markdown file, such as https://wiki.archlinux.org/title/SomePage, rather than using Markdown link syntax.
  - Solution: Use proper Markdown link formatting. Replace the bare URL with [Arch Wiki - SomePage](https://wiki.archlinux.org/title/SomePage). If you do not have link text, you can simply wrap the URL in angle brackets like <https://wiki.archlinux.org/title/SomePage>.
  - Example:
    - Before: https://wiki.archlinux.org/title/SomePage
    - After: [Arch Wiki - SomePage](https://wiki.archlinux.org/title/SomePage)

- MD013/line-length (packages/calamares/README.md and README.md):
  - Problem: Lines in your Markdown files exceed the recommended maximum of 80 characters, making files harder to read and breaking Markdown style conventions.
  - Solution: Break up long lines into multiple shorter ones, ensuring that no line exceeds 80 characters. Wrap sentences at logical points such as after a period or comma, or between phrases.
  - Example:
    - Before: This is a very long line that exceeds the normal 80 character limit for Markdown files and should be wrapped appropriately for better readability.
    - After: This is a very long line that exceeds the normal 80 character limit for Markdown files  
      and should be wrapped appropriately for better readability.

- MD041/first-line-heading/first-line-h1 (packages/calamares/README.md):
  - Problem: The first line of the README is not a top-level heading.
  - Solution: Add a top-level heading at the very top of the file, such as # Calamares or # Calamares Installer, before any other content.
  - Example:
    # Calamares

    Do to the use of the -DFEATURE...

2. Proselint (Docs Linter) (.github/workflows/proselint.yml)
------------------------------------------------------------
Summary of Errors:
- AGENTS.md:136:10 typography.symbols.curly_quotes: Use curly quotes (“ ”) instead of straight quotes (").
- AGENTS.md:141:46 leonard.exclamation.30ppm: Too many exclamation marks.

Detailed Solutions:
- typography.symbols.curly_quotes (AGENTS.md:136:10):
  - Problem: The text uses straight quotation marks (") instead of curly quotes (“”).
  - Solution: Replace all straight quotes with curly quotes. For example, replace "This is quoted" with “This is quoted”.
  - Example:
    - Before: "This is a quote."
    - After: “This is a quote.”

- leonard.exclamation.30ppm (AGENTS.md:141:46):
  - Problem: The text contains too many exclamation marks, making the writing look unprofessional or overly emotional.
  - Solution: Limit yourself to a single exclamation mark per sentence, and use them sparingly. Replace unnecessary exclamation marks with periods or rewrite sentences to reduce their frequency.
  - Example:
    - Before: Wow!!!! This is amazing!!!
    - After: Wow! This is amazing. or Wow, this is amazing.

3. Build (.github/workflows/build.yml)
--------------------------------------
Summary of Errors:
- Skipped: Current root is not booted.
- /usr/lib/tmpfiles.d/journal-nocow.conf:26: Failed to resolve specifier: uninitialized /etc/ detected, skipping.
- PKGBUILD (calamares) E: Split PKGBUILD needs additional makedepends: ['kconfig', 'kconfig5', 'kcoreaddons', 'kcoreaddons5', 'ki18n', 'ki18n5', 'kiconthemes', 'kiconthemes5', 'kio', 'kio5', 'plasma-framework5', 'polkit-qt5', 'polkit-qt6', 'qt5-base', 'qt5-svg', 'qt5-xmlpatterns']
- ERROR: You do not have write permission for the directory $BUILDDIR (/__w/xanados/xanados/packages/calamares).
- Exit code: 11

Detailed Solutions:
- "Current root is not booted" and "Failed to resolve specifier":
  - Problem: These are generally warnings from systemd or post-install scripts expecting a booted system, common in CI environments.
  - Solution: These can often be safely ignored if the build otherwise succeeds. If these warnings cause a failure, patch or disable the affected post-transaction hooks for CI, ensuring scripts that require a running system are skipped in CI.

- PKGBUILD needs additional makedepends:
  - Problem: The PKGBUILD is missing required packages in its global makedepends array. Dynamic, function-based assignment of makedepends does not work with makepkg.
  - Solution: Add all build-time dependencies for both calamares (Qt6) and calamares-qt5 (Qt5) to a top-level, static makedepends array.
  - Example:
    makedepends=(
      'extra-cmake-modules'
      'git'
      'kconfig'
      'kconfig5'
      'kcoreaddons'
      'kcoreaddons5'
      'ki18n'
      'ki18n5'
      'kiconthemes'
      'kiconthemes5'
      'kio'
      'kio5'
      'plasma-framework5'
      'polkit-qt5'
      'polkit-qt6'
      'qt5-base'
      'qt5-svg'
      'qt5-xmlpatterns'
      'qt5-tools'
      'qt5-translations'
      'qt6-base'
      'qt6-svg'
      'qt6-tools'
      'qt6-translations'
    )
  - Remove any dynamic logic (functions that append to makedepends) from your PKGBUILD, as they will be ignored by makepkg.

- Write permission for $BUILDDIR:
  - Problem: The build process user does not have permission to write to the build directory.
  - Solution: Modify your GitHub Actions or CI workflow to ensure the build user owns the build directory and has write permissions.
  - Example for GitHub Actions:
    - name: Fix permissions for build directory
      run: sudo chown -R $(whoami) /__w/xanados/xanados/packages/calamares
  - Alternatively, always build packages as a regular user, not as root, for security and compatibility with packaging standards.

----------------------------------------

II. PKGBUILD Analysis & Suggestions
-----------------------------------

Analysis:
- PKGBUILD currently tries to dynamically append to makedepends using bash functions within prepare(). makepkg only reads the top-level makedepends array.
- Required build-time dependencies for both Qt5 and Qt6 variants are not being installed, causing lint failures and potentially incomplete builds.

Detailed PKGBUILD Suggestions:
1. Replace dynamic makedepends logic with a static array.
   - Remove any bash functions that append to makedepends or attempt to set it dynamically.
   - Define a single, static makedepends array at the top of your PKGBUILD that includes all build dependencies for both split packages.

2. Comprehensive makedepends example for your calamares PKGBUILD:
   makedepends=(
     'extra-cmake-modules'
     'git'
     'kconfig'
     'kconfig5'
     'kcoreaddons'
     'kcoreaddons5'
     'ki18n'
     'ki18n5'
     'kiconthemes'
     'kiconthemes5'
     'kio'
     'kio5'
     'plasma-framework5'
     'polkit-qt5'
     'polkit-qt6'
     'qt5-base'
     'qt5-svg'
     'qt5-xmlpatterns'
     'qt5-tools'
     'qt5-translations'
     'qt6-base'
     'qt6-svg'
     'qt6-tools'
     'qt6-translations'
   )

3. Ensure all other dependencies are correctly listed in the depends arrays for each split package.
   - The depends arrays for package_calamares() and package_calamares-qt5() look appropriate but cross-check them with upstream package requirements if you encounter runtime errors.

4. Permissions:
   - In your CI workflow, make sure the build user (usually runner or github-actions) has ownership and write access to $BUILDDIR before building.
   - Example shell command:
     sudo chown -R $(whoami) /__w/xanados/xanados/packages/calamares

5. General Maintenance:
   - After these changes, review the PKGBUILD for any remaining dynamic or nonstandard logic related to dependencies or build steps.
   - Test the build locally (if possible) before pushing changes to ensure all dependencies are resolved and that the build succeeds.

----------------------------------------

III. General Docs and Build Advice
----------------------------------------
- Markdown and prose lint: Review all Markdown files flagged by linters, wrap lines at 80 characters, use proper link syntax, and replace straight quotes with curly quotes using your editor’s find-and-replace.
- Build permissions: Never build as root. Always ensure your build user has the correct permissions for all build and work directories.
- Dependency maintenance: Periodically review dependencies for both build and runtime, especially after major upstream updates or when adding new features.

==============================
End of Detailed Report
==============================
