# Error Resolution Checklist

Review [errors1.md](errors1.md) for new errors
Update [Checklist.md](Checklist.md) with all new errors and failed checks
Document a summary of errors and failed checks resolved in [Checklist.md](Checklist.md) below CHANGELOG with time and date
Remove resolved errors and failed checks no longer present in [errors1.md](errors1.md) from [Checklist.md](Checklist.md)
Mark each item as you resolve the issues listed in [errors1.md](errors1.md).

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

- [ ] CI warnings about unbooted root and journal specifier
- [x] Add static makedepends to calamares PKGBUILD
- [x] Fix write permission for $BUILDDIR in CI

===
# CHANGELOG
