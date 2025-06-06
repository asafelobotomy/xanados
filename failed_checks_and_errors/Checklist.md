# Error Resolution Checklist

Mark each item as you resolve the issues listed in [errors1.md](errors1.md).

## Markdown Lint

- [ ] AGENTS.md uses a bare URL (MD034)
- [ ] packages/calamares/README.md line 1 exceeds 80 characters (MD013)
- [ ] packages/calamares/README.md missing top-level heading (MD041)
- [ ] packages/calamares/README.md line 2 exceeds 80 characters (MD013)
- [ ] README.md lines 45–47 exceed 80 characters (MD013)

## Proselint

- [ ] AGENTS.md line 136 should use curly quotes
- [ ] AGENTS.md line 141 has too many exclamation marks

## Build

- [ ] CI warnings about unbooted root and journal specifier
- [ ] Add static makedepends to calamares PKGBUILD
- [ ] Fix write permission for $BUILDDIR in CI
