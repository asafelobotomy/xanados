# Contributing to XanadOS

Thank you for your interest in contributing!
This project follows guidelines summarized from
[AGENTS.md](AGENTS.md).

## Project Scope

Work only in the following directories:

- `packages/` – custom PKGBUILD packages
- `xanados-iso/` – ISO build files
- `scripts/` – helper scripts
- `configs/` – system configuration snippets
- `docs/` – additional documentation
- `logs/` – build and test logs
- `frontend/` – Next.js frontend
- `failed_checks_and_errors/` – records of failed tests

Avoid modifying files outside these areas unless specifically reviewed.

## Forbidden Actions

- Do **not** commit secrets or private keys.
- Do **not** disable security controls or modify unrelated directories.
- Do **not** run unreviewed commands or weaken security settings.

## Contributor Responsibilities

- Maintain PKGBUILD files and ISO profiles.
- Automate builds with scripts and Makefiles.
- Write secure, POSIX compliant shell scripts.
- Keep packages up to date and fix bugs promptly.
- Validate text documents and scripts for typos or invalid commands.

## Pre-Task Checklist

1. Review the last 10 commits to understand recent changes.
2. Check formatting with appropriate linters (e.g., `prettier`, `shellcheck`).
3. Confirm the current date and time before starting work.

## Example Workflow

1. Create `packages/<name>/PKGBUILD` following Arch standards.
2. Add the package to `xanados-iso/packages.x86_64`.
3. Document the package in `docs/packages.md`.
4. Run `namcap` and `makepkg --verifysource`.
5. Update tests under `tests/`
6. Open a pull request summarizing your changes.

## Linting and Testing

- Run `prettier --check` on Markdown files.
- Run `shellcheck` and `shfmt` on shell scripts.
- Use `namcap` on PKGBUILD files.
- Execute `bats tests` to ensure scripts exist and are executable.

## Logging and Security

- Log script output to files in `logs/`.
- Include timestamps and rotate logs over 10MB or older than 30 days.
- Follow CIS security practices and verify downloads with checksums or GPG.

## Suggesting Improvements

Open a pull request or GitHub issue with a clear summary and rationale.
Include test results and follow the guidelines above.
