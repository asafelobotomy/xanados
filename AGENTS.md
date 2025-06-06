# AGENTS.md – Guide for AI & Human Contributors

## Last Updated: 2025-06-05

> **Audience:** All developers, AI agents (Copilot, Codex, ChatGPT),
> and collaborators.

---

## 📖 Table of Contents

1. [Project Scope & Directory Structure](#-project-scope--directory-structure)
2. [Forbidden Actions & Security](#-forbidden-actions--security)
3. [Contributor Responsibilities](#-contributor-responsibilities)
4. [Pre-task checks to perform](#-pre-task-checks-to-perform)
5. [Example Workflow: Adding a Package](#-example-workflow-adding-a-package)
6. [Linting & Formatting](#-linting--formatting)
7. [Security and Compliance](#-security-and-compliance)
8. [PKGBUILD Standards](#-pkgbuild-standards)
9. [ISO Creation Guidelines](#-iso-creation-guidelines)
10. [Logging](#-logging)
11. [System & Script Testing](#-system--script-testing)
12. [References](#-references)
13. [Prompting Tips](#-prompting-tips)
14. [Suggesting Improvements](#-suggesting-improvements)
15. [Changelog](#-changelog)

---

## 📦 Project Scope & Directory Structure

Interact only with:

- `/packages/`: Custom
  [`PKGBUILD`](https://wiki.archlinux.org/title/PKGBUILD) packages
- `/xanados-iso/`: ISO build configs
  ([archiso](https://wiki.archlinux.org/title/Archiso))
- `/scripts/`: Bash automation/tooling
- `/configs/`: System settings, pacman hooks, systemd units
- `/docs/`: Markdown docs
- `/logs/`: Build/test/ISO logs
- `/frontend/`: Next.js frontend
- `/failed_checks_and_errors/`: list of failed script checks and errors

**Do not** modify `/public/` or commit `.git`-ignored secrets.

---

## 🚫 Forbidden Actions & Security

- Do not modify files outside the above directories without explicit review.
- Do not commit/expose secrets, tokens, or private keys.
- Do not execute scripts/commands without explicit review.
- Do not weaken security settings unless explicitly instructed.
- Never disable security controls (pre-commit, git-secrets, etc).

---

## 🧠 Contributor Responsibilities

You must always:

- Assist with creating/editing PKGBUILD files
- Assist with writing archiso profiles (e.g., `releng/`, `baseline/`)
- Automate build pipelines (`make`, `build.sh`)
- Write secure, POSIX-compliant shell scripts
- Manage pacman hooks, mkinitcpio configs, systemd services
- Test ISO builds (QEMU, VirtualBox, CI) where possible
- Troubleshoot bugs, fix errors and remove conflicts
  whenever they are found
- Check packages to make sure that they are up-to-date and stable
- Validate all text documents and scripts, checking for typos and
  invalid references/commands

## 🤖 Using Codex

Codex (or other AI assistants) should automatically run the following commands for debugging and formatting before opening a Pull Request:

```bash
npm list --depth=0
bats tests
prettier --check .
atom --check **/*.md
shellcheck scripts/*.sh
```

Install Python requirements with `pip install -r requirements.txt` before running `scripts/check_packages.py`.

---

## 📝 Pre-task checks to perform

- Review the last 10 previous commits of this build
  to get a full understanding of the project
- Check formatting and syntax throughout all documents
  to provide consistency in future changes and updates
- Confirm today's date and time as a reference for
  future queries

---

## 📝 Example Workflow: Adding a Package

- [ ] Create `/packages/<pkgname>/PKGBUILD` per
      [Arch standards](https://wiki.archlinux.org/title/Creating_packages)
- [ ] Add package to `xanados-iso/packages.x86_64`
- [ ] Update `/docs/packages.md` with usage/details
- [ ] Run `namcap` and `makepkg --verifysource`
- [ ] Add/update tests in `/scripts/tests/`
- [ ] Open a Pull Request summarizing changes (see
      [Suggesting Improvements](#-suggesting-improvements))

---

## 🧹 Linting & Formatting

| File Type     | Tool       | Example Command            |
| ------------- | ---------- | -------------------------- |
| Shell scripts | shellcheck | `shellcheck script.sh`     |
| Shell scripts | shfmt      | `shfmt -d -i 2 script.sh`  |
| PKGBUILD      | namcap     | `namcap PKGBUILD`          |
| Markdown      | prettier   | `prettier --check file.md` |
| Markdown      | atom       | `atom --check file.md`     |
| Python        | black      | `black file.py`            |
| JavaScript    | eslint     | `eslint file.js`           |

Ensure all code passes relevant linters before submission.

### Node tooling

The project relies on several Node packages:

- `express` for a lightweight test server
- `karma` to run JavaScript unit tests (`npx karma start`)
- `lint-staged` to lint staged files before commit (`npx lint-staged`)
- `lodash` as a general utility library
- `markdown-magic` to update documentation macros (`npx markdown-magic`)
- `ngx-markdown` for Markdown display in the frontend
- `npm-package-json-lint` to validate `package.json` (`npx npmPkgJsonLint .`)

---

## 🔒 Security and Compliance

- Follow [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
  where applicable.
- Use `sudo` securely; avoid `NOPASSWD` when possible
- Avoid hardcoded passwords/keys/tokens.
- Set restrictive file permissions (`umask 027`, `chmod 600+`).
- Harden system configs (`sshd_config`, `journald.conf`, `grub.cfg`).
- Always verify GPG/signatures or SHA256 sums on downloads.
- Use [git-secrets](https://github.com/awslabs/git-secrets) or similar
  to guard against committing secrets.

### Security Checklist

- [ ] No hardcoded credentials/secrets
- [ ] File permissions set securely (e.g., `chmod 600+`)
- [ ] GPG/signature verification for all downloads
- [ ] No world-writable files/dirs
- [ ] No unnecessary open ports/services

---

## 🛠 PKGBUILD Standards

- Follow the Arch Wiki guidelines on [Creating packages](https://wiki.archlinux.org/title/Creating_packages)
- Use `sha256sums`/`validpgpkeys` for sources
- Pass `namcap`/linting
- Do not vendor precompiled/insecure binaries

**Example PKGBUILD:**

<!-- proselint-disable -->

```bash

pkgname=example
pkgver=1.0
pkgrel=1
pkgdesc=“An example package”
arch=('x86_64')
url="https://example.com"
license=('GPL3')
source=("https://example.com/download/$pkgname-$pkgver.tar.gz")
sha256sums=('SKIP') # Replace with actual sum.
build() {
    cd "$srcdir/$pkgname-$pkgver"
    make
}
package() {
    cd "$srcdir/$pkgname-$pkgver"
    make DESTDIR="$pkgdir/" install
}

```

<!-- proselint-enable -->

---

## 🗂 ISO Creation Guidelines

- Must be GRUB/syslinux bootable
- Include `airootfs`, base and custom packages
- Build metadata in `/etc/os-release` and `/etc/issue`
- Ensure reproducibility (`SOURCE_DATE_EPOCH`, fixed timestamps)
- Build via `build.sh` or `Makefile`, log to `/logs/iso-build.log`
- Validate bootability, package list, network, shell

---

## 📝 Logging

All build scripts must:

- Log to `/logs/`
- Include timestamp, command, and result in logs
- Rotate logs if >10MB or older than 30 days

**Example logging snippet (bash):**

```bash

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a /logs/build.log
}

```

---

## 🧪 System & Script Testing

- All scripts must pass `shellcheck`
- All systemd units enabled/disabled as intended
- System must boot to expected state (QEMU/CI)
- [Optional] Use [`bats-core`](https://github.com/bats-core/bats-core)
  for shell test coverage

**Example QEMU boot test:**

```bash

qemu-system-x86_64 -cdrom out/archlinux-custom.iso -m 2048 -nographic

```

---

## 📚 References

- [Arch Wiki: Creating packages](https://wiki.archlinux.org/title/Creating_packages)
- [Arch Wiki: archiso](https://wiki.archlinux.org/title/Archiso)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [shellcheck](https://www.shellcheck.net/)
- [shfmt](https://github.com/mvdan/sh)
- [namcap](https://archlinux.org/packages/community/any/namcap/)
- [prettier](https://prettier.io/)
- [bats-core](https://github.com/bats-core/bats-core)
- [git-secrets](https://github.com/awslabs/git-secrets)
- [Python Black](https://black.readthedocs.io/en/stable/)
- [ESLint](https://eslint.org/)

---

## 💡 Prompting Tips

- Request change summaries before applying
- Ask for test coverage/examples for new scripts
- Request explanations for security-sensitive changes
- When in doubt, consult the Arch Wiki and this document

---

## 🤝 Suggesting Improvements

To propose changes,
[open a Pull Request](https://github.com/asafelobotomy/xanados/compare)
or [GitHub Issue](https://github.com/asafelobotomy/xanados/issues/new)
with your suggestions. Include a summary and rationale.

---

## 📝 Changelog

- 2025-06-05: Improved formatting, added ToC,
  expanded security & workflow sections.

---
