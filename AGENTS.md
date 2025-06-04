# AGENTS.md – Guide for ChatGPT Codex in Arch Linux ISO Projects

_Last updated: 2025-06-03_

This document defines development, security, packaging, and build rules for **ChatGPT Codex** when contributing to this Arch Linux-based distribution. Codex may assist in scripting, packaging, testing, ISO creation, and documentation — but must follow all guidance in this file for correctness, reproducibility, and security.

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
5. Add or update relevant tests in `/scripts/tests/`.

---

## 🧹 Linting and Formatting Requirements

| File Type      | Linter/Formatter      | Command Example                |
|----------------|----------------------|-------------------------------|
| Shell scripts  | shellcheck, shfmt     | `shellcheck script.sh`        |
| PKGBUILD       | namcap                | `namcap PKGBUILD`             |
| Markdown       | prettier              | `prettier --check file.md`    |

All code must pass the relevant linters before submission.

---

## 🔐 Security and Compliance (Arch Linux Focus)

Codex must:

- Follow the **CIS Benchmarks** (where Arch equivalents exist)
- Use `sudo` securely — avoid `NOPASSWD` unless explicitly configured
- Avoid hardcoded passwords, SSH keys, or tokens
- Set restrictive file permissions (`umask 027`, `chmod 600+`)
- Harden system settings: `sshd_config`, `journald.conf`, `grub.cfg`
- Always verify GPG signatures or SHA256 sums on downloaded files

### 🔒 Security Checklist

- [ ] No hardcoded credentials or secrets
- [ ] File permissions set securely (`chmod 600+`)
- [ ] GPG/signature verification for all downloads
- [ ] No world-writable files or directories
- [ ] No unnecessary open ports or services

---

## 🛠 PKGBUILD and Package Management

Codex-generated PKGBUILD files must:

- Follow Arch packaging standards:  
  [Arch Wiki: Creating packages](https://wiki.archlinux.org/title/Creating_packages)
- Include all mandatory fields: `pkgname`, `pkgver`, `pkgrel`, `license`, etc.
- Use `sha256sums` or `validpgpkeys` for source verification
- Be linted using `namcap` or similar tools
- Avoid vendoring binaries or insecure precompiled software

---

## 📀 ISO Creation Guidelines

Codex may assist with Arch ISO generation via `archiso`.

ISO requirements:

- GRUB or syslinux bootable
- Includes `airootfs` with minimal base packages and any custom packages
- Includes build metadata in `/etc/os-release` and `/etc/issue`
- Built with reproducibility (`SOURCE_DATE_EPOCH`, fixed timestamps)

Build process:

- Codex must write or extend a `build.sh` or `Makefile` for ISO generation
- ISO builds must log to:  
  `/logs/iso-build.log`
- ISO must be validated for:
  - Bootability in QEMU
  - Correct package list
  - Functional network and shell

---

## 📝 Logging

- All build scripts must log to `/logs/`
- Logs must include timestamp, command, and result
- Rotate logs if they exceed 10MB or 30 days

---

## 🧪 System and Script Testing

Codex must ensure:

- All scripts pass `shellcheck`
- All systemd services are enabled/disabled correctly
- System boots to expected state (via QEMU automated tests)
- Optional: Use `bats-core` for shell script test coverage

Virtualized test flows:

```bash
# QEMU boot test
qemu-system-x86_64 -cdrom out/archlinux-custom.iso -m 2048 -nographic

# Validate services
systemctl list-units --type=service --state=failed
```

---

## 📚 References

- [Arch Wiki: Creating packages](https://wiki.archlinux.org/title/Creating_packages)
- [Arch Wiki: archiso](https://wiki.archlinux.org/title/Archiso)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

---

## 💡 Prompting Tips for Codex/Co-Pilot

- Always request a summary of changes before applying.
- Ask for test coverage or example test cases with new scripts.
- Request explanations for any security-sensitive changes.
- When in doubt, refer to the Arch Wiki or this document.

---

## 🗒️ Changelog

- 2025-06-03: Initial version with expanded security, linting, and workflow guidance.
