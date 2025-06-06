# Error Resolution Checklist

Use this file to track issues reported in [errors1.md](errors1.md).

1. Review `errors1.md` regularly for new problems.
2. Add new items below and keep them unchecked until fixed.
3. Remove any entry that is marked as completed [x]
4. When you resolve an item, check it off and
   add a note under **CHANGELOG** with todays date.

## Build

- [ ] Install `debugedit` and `fakeroot` packages in the CI workflow.
- [ ] Investigate warnings about an unbooted root and journal specifier.

## Markdown Lint

- [ ] Break long lines at 80 characters or update `.markdownlint.yml`.
- [ ] Ensure all files start with a top‑level heading.
- [ ] Replace bare URLs with proper Markdown links.

===

## Changelog

- 2025-06-06: Clarified checklist instructions and formatted with Prettier.
- 2025-06-06: Created machine-id during package build to silence systemd
  tmpfiles warnings.
- 2025-06-06: Added builduser creation step in CI.
- 2025-06-06: Added tasks for package permissions, markdown lint cleanup and
  systemd warning review.
- 2025-06-06: Reset checklist with new build and markdown lint issues.
