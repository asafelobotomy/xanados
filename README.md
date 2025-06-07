# XanadOS ISO

[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
![Shell](https://img.shields.io/badge/language-shell-brightgreen)
![Python](https://img.shields.io/badge/language-python-yellow)
<!-- Add build status or release badges here if available -->

XanadOS is a gaming, security, and performance-focused Arch Linux build. This repository contains all the build files, scripts, and profiles for generating the XanadOS ISO.

---

## Features

- **Modern Arch-based OS**: Leverages Arch Linux’s rolling release and flexibility.
- **Security Tools Out-of-the-Box**: Includes essential security packages.
- **Performance Tweaks**: Ships with tools to optimize system responsiveness and battery life.
- **Gamer-Ready**: Custom gaming stack installer lets you pick only what you want.
- **AUR Helper Included**: Comes with `paru` for easy package management.

---

## Included Packages

### Security Tools

- `fail2ban` — Intrusion prevention
- `nmap` — Network scanning
- `wireshark-qt` — Network protocol analyzer
- `clamav` — Antivirus
- `rkhunter` — Rootkit detection

### Performance Tools

- `tlp` — Advanced power management
- `thermald` — CPU thermal protection
- `cpupower` — CPU frequency scaling
- `irqbalance` — IRQ distribution
- `preload` — Adaptive readahead daemon
- `earlyoom` — Early Out of Memory killer

### Notable Extras

- `paru` — Pre-installed for AUR and Arch repo package management

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/asafelobotomy/xanados.git
cd xanados/xanados-iso
```

### 2. Build the ISO

> **Requirements:**  
> - Arch Linux-based build host  
> - `archiso` and other build dependencies installed

```bash
# Option A: use mkarchiso directly
sudo mkarchiso -v .

# Option B: use the helper script which sets up work/output dirs
./build.sh
```

The `build.sh` script wraps `mkarchiso` and automatically creates `work/` and
`out/` directories. Set `WORK_DIR` or `OUT_DIR` environment variables to
override their locations if needed.

The generated ISO will appear in the `out/` directory by default.

### 3. Test in a VM

```bash
qemu-system-x86_64 -cdrom out/xanados.iso -m 4096
```
### Node/Next.js Dependencies
The repository previously included a Next.js frontend. These Node.js packages are not required to build the ISO and can be ignored if you only want the installer scripts.

---

## Custom Gaming Installation

When you boot into XanadOS, the welcome application allows you to select individual gaming packages to install. The installer passes your choices to `install_gaming.sh`, which can also be used manually:

```bash
install_gaming.sh steam lutris heroic-games-launcher
```

Or provide a file with package names:

```bash
install_gaming.sh -f /path/to/pkglist.txt
```

The script automatically skips packages that are already installed and prints
the final list before running `paru`. To uninstall gaming packages, use the
`--remove` option (optionally combine with `--dry-run` to preview changes):

```bash
install_gaming.sh --remove steam lutris
```

If no packages are specified, a default gaming package set will be installed:

- steam
- lutris
- heroic-games-launcher
- gamemode
- mangohud
- vkbasalt
- protontricks

> **Tip:** Installer logs are stored in `/var/log/xanados/welcome_install_YYYYMMDD_HHMMSS.log` and the Welcome app shows the latest log automatically.

---

## Build Details

- **Profile Definitions:**  
  Located in `xanados-iso/profiledef.sh`, specifying ISO name, build mode, compression, etc.
- **Installer Scripts:**  
  Found in `xanados-iso/airootfs/etc/xanados/scripts/` for minimal, recommended, and gaming package installs.
- **Calamares Integration:**  
  Custom install logic in `xanados-iso/calamares/scripts/` and modules.
- **Mirror Selection:**
  Handled by `choose-mirror` script for flexible mirror configuration at boot.
### Calamares Customization
Calamares configs live in `xanados-iso/calamares`. Adjust `settings.conf`, modify files under `modules/`, and update `scripts/` to tailor the installer.

## Kernel Options

The installer can install different kernels based on the setting in
`/etc/xanados/package-options.conf` or the option selected in Calamares.
Set the `KERNEL` variable to one of the following values:

- `linux` – the standard Arch kernel
- `zen` – `linux-zen` for desktop performance
- `lts` – `linux-lts` long term support kernel
- `hardened` – `linux-hardened` with extra security features
- `xanmod` – `linux-xanmod` tuned for gaming

During installation the **packagechooser** module installs the chosen kernel
and removes any other kernel packages.

## Security Considerations
XanadOS supports Secure Boot via the `secureboot-toggle` Calamares module. Package signing is handled by pacman and trusted keys. Review `calamares/modules/secureboot-toggle` for details.

## Screenshots

<!-- If you have images, add them here!
![Welcome App](screenshots/welcome.png)
![Gaming Stack Selection](screenshots/gaming.png)
-->

## Testing
Run `shellcheck -x xanados-iso/airootfs/etc/xanados/scripts/*.sh \
  xanados-iso/calamares/scripts/*.sh build.sh` locally before committing.
Unit tests run with `bats tests`. Both checks also execute automatically in CI.
---

## Community & Support

- [Arch Wiki](https://wiki.archlinux.org/) — For general Arch Linux troubleshooting
- Issues and feature requests: [GitHub Issues](https://github.com/asafelobotomy/xanados/issues)

---

## License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).

---
