# Error Resolution Checklist

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
