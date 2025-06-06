# Error Resolution Checklist

Use this file to track issues reported in [errors1.md](errors1.md).

Follow these steps whenever you work with this checklist:

1. Review `errors1.md` for new or unresolved issues.
2. Add a corresponding task below for each error you find. Use the same wording
   so both files match.
3. Keep each error entry in `errors1.md` until the task here is checked off.
4. When a task is complete, mark it `[x]` and record the fix under
   **Changelog** with today's date.
5. After logging the resolution, remove the matching entry from `errors1.md`.

## Build

- [ ] Install `debugedit` and `fakeroot` packages in the CI workflow.
- [x] Investigate warnings about an unbooted root and journal specifier.
      These messages appear in CI when `/etc` is not fully initialized and
      can be ignored unless they cause the build to fail.

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
- 2025-06-06: Noted that systemd tmpfiles warnings are safe to ignore in CI.
