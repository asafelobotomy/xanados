# AGENTS.md – Guide for AI & Human Contributors

_Last updated: 2025-06-03_

This document defines standards for development, security, packaging, and build workflows for **GitHub Copilot/Codex** and all contributors working on this Arch Linux-based distribution.

> **Audience:** All developers, AI agents, and collaborators.

---

## 📦 Project Scope & Directory Structure

Codex and contributors should interact only with:

- `/packages/`: Custom [`PKGBUILD`](https://wiki.archlinux.org/title/PKGBUILD) packages
- `/iso/`: ISO build configs via [archiso](https://wiki.archlinux.org/title/Archiso)
- `/scripts/`: Bash automation and tooling
- `/configs/`: System settings, pacman hooks, systemd units
- `/docs/`: Markdown docs
- `/logs/`: Build/test/ISO logs
- `/frontend/`: Next.js frontend

**Do not** modify `/public/` or commit `.git`-ignored secrets.

---

## 🚫 Forbidden Actions and Security

- Do not modify files outside the directories above.
- Do not commit or expose secrets, tokens, or private keys.
- Do not execute scripts or commands without explicit review.
- Do not push directly to the `main` branch.
- Do not weaken security settings unless explicitly instructed.

---

## 🧠 Contributor Responsibilities

You may assist with:

- Creating/editing PKGBUILD files
- Writing archiso profiles (e.g., `releng/`, `baseline/`)
- Automating build pipelines (`make`, `build.sh`)
- Writing secure, POSIX-compliant shell scripts
- Managing pacman hooks, mkinitcpio configs, systemd services
- Testing ISO builds (QEMU, VirtualBox, CI)

---

## 📝 Example Workflow: Adding a Package

- [ ] Create `/packages/<pkgname>/PKGBUILD` per [Arch standards](https://wiki.archlinux.org/title/Creating_packages)
- [ ] Add package to `/iso/profile/packages.x86_64`
- [ ] Update `/docs/packages.md` with usage/details
- [ ] Run `namcap` and `makepkg --verifysource`
- [ ] Add/Update tests in `/scripts/tests/`

---

## 🧹 Linting & Formatting

| File Type     | Tool         | Example Command                |
|---------------|--------------|-------------------------------|
| Shell scripts | shellcheck   | `shellcheck script.sh`        |
| Shell scripts | shfmt        | `shfmt -d -i 2 script.sh`     |
| PKGBUILD      | namcap       | `namcap PKGBUILD`             |
| Markdown      | prettier     | `prettier --check file.md`    |

Ensure all code passes relevant linters before submission.

---

## 🔐 Security and Compliance

- Follow [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/) (where applicable)
- Use `sudo` securely; avoid `NOPASSWD`
- Avoid hardcoded passwords/keys/tokens
- Set restrictive file permissions (`umask 027`, `chmod 600+`)
- Harden system configs (`sshd_config`, `journald.conf`, `grub.cfg`)
- Always verify GPG/signatures or SHA256 sums on downloads

### Security Checklist

- [ ] No hardcoded credentials/secrets
- [ ] File permissions set securely (e.g., `chmod 600+`)
- [ ] GPG/signature verification for all downloads
- [ ] No world-writable files/dirs
- [ ] No unnecessary open ports/services

---

## 🛠 PKGBUILD Standards

- Follow [Arch Wiki: Creating packages](https://wiki.archlinux.org/title/Creating_packages)
- Include all mandatory fields
- Use `sha256sums`/`validpgpkeys` for sources
- Pass `namcap`/linting
- Do not vendor precompiled/insecure binaries

**Example PKGBUILD:**
```bash
pkgname=example
pkgver=1.0
pkgrel=1
pkgdesc="An example package"
arch=('x86_64')
url="https://example.com"
license=('GPL3')
source=("https://example.com/download/$pkgname-$pkgver.tar.gz")
sha256sums=('SKIP') # Replace with actual sum!
build() {
    cd "$srcdir/$pkgname-$pkgver"
    make
}
package() {
    cd "$srcdir/$pkgname-$pkgver"
    make DESTDIR="$pkgdir/" install
}
```

---

## 📀 ISO Creation Guidelines

- Must be GRUB/syslinux bootable
- Include `airootfs`, base packages, custom packages
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
- [Optional] Use [`bats-core`](https://github.com/bats-core/bats-core) for shell test coverage

Example QEMU boot test:
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

---

## 💡 Prompting Tips

- Request change summaries before applying
- Ask for test coverage/examples for new scripts
- Request explanations for security-sensitive changes
- When in doubt, consult the Arch Wiki and this document

---

## 🤝 Suggesting Improvements

To propose changes to this document, open a pull request or GitHub issue with your suggestions.

---

## 🗒️ Changelog

- 2025-06-03: Initial version with security, linting, and workflow guidance
# AGENTS.md – Guide for ChatGPT Codex in Arch Linux ISO Projects

Last updated: 2025-06-03

This document defines development, security, packaging, and build rules for
**ChatGPT Codex** when contributing to this Arch Linux-based distribution.
Codex may assist in scripting, packaging, testing, ISO creation, and
documentation — but must follow all guidance in this file for correctness,
reproducibility, and security.

---

## 📦 Project Scope and Directory Structure

Codex will interact with the following areas of the project:

- `/packages/`: Custom `PKGBUILD` packages
- `/iso/`: ISO build configs using `archiso`
- `/scripts/`: Bash scripts for automation and tooling
- `/configs/`: Custom system settings, pacman hooks, systemd units
- `/docs/`: Markdown documentation
- `/logs/`: Build, test, and ISO generation logs
- `/frontend/`: Next.js based web frontend

Codex should **not** modify `/public/` or `.git`-ignored secrets.

---

## 🚫 Forbidden Actions

- Never modify files outside the listed directories above.
- Never commit or expose secrets, tokens, or private keys.
- Never execute scripts or commands without explicit user review.
- Never push directly to the `main` branch.
- Never disable or weaken security settings without explicit instruction.

---

## 🧠 Codex Role in the ArchLinux ISO Workflow

Codex may assist with:

- Creating and editing `PKGBUILD` files
- Writing `archiso` profiles (e.g. `releng/`, `baseline/`)
- Automating build pipelines (`make`, `build.sh`)
- Writing secure, POSIX-compliant shell scripts
- Modifying pacman hooks, mkinitcpio configs, or systemd services
- Testing ISO builds with QEMU, VirtualBox, or CI

---

## 📝 Example Workflow: Adding a New Package

1. Create `/packages/<pkgname>/PKGBUILD` following Arch standards.
2. Add the package to `/iso/profile/packages.x86_64`.
3. Update `/docs/packages.md` with a description and usage.
4. Run `namcap` and `makepkg --verifysource` to lint and verify.
