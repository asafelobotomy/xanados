# Error Resolution Checklist

Use this file to track issues reported in [errors1.md](errors1.md).

1. Review `errors1.md` regularly for new problems.
2. Add new items below and keep them unchecked until fixed.
3. Remove any entry that disappears from `errors1.md`.
4. When you resolve an item, check it off and
   add a note under **CHANGELOG** with the date.

## Markdown Lint

- [x] AGENTS.md uses a bare URL (MD034)
- [x] packages/calamares/README.md line 1 exceeds 80 characters (MD013)
- [x] packages/calamares/README.md missing top-level heading (MD041)
- [x] packages/calamares/README.md line 2 exceeds 80 characters (MD013)
- [x] README.md lines 45–47 exceed 80 characters (MD013)

## Proselint

- [x] AGENTS.md line 136 should use curly quotes
- [x] AGENTS.md line 141 has too many exclamation marks

## Build

- [x] CI warnings about unbooted root and journal specifier
- [x] Add static makedepends to calamares PKGBUILD
- [x] Fix write permission for $BUILDDIR in CI
- [x] Create builduser user/group before chown

===

## Changelog

- 2025-06-07: Clarified checklist instructions and formatted with Prettier.
- 2025-06-06: Created machine-id during package build to silence systemd tmpfiles warnings.
- 2025-06-06: Added builduser creation step in CI.
