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
# Replace with your actual build command or script
# Example using archiso:
sudo mkarchiso -v .
# or if you use a custom script:
./build.sh
```

The generated ISO will appear in the `out/` directory by default.

### 3. Test in a VM

```bash
qemu-system-x86_64 -cdrom out/xanados.iso -m 4096
```

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

If no packages are specified, a default gaming package set will be installed:

- steam
- lutris
- heroic-games-launcher
- gamemode
- mangohud
- vkbasalt
- protontricks

> **Tip:** All installer scripts (minimal, recommended, gaming) log to `/tmp/welcome_install.log` for troubleshooting.

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

---

## Screenshots

<!-- If you have images, add them here!
![Welcome App](screenshots/welcome.png)
![Gaming Stack Selection](screenshots/gaming.png)
-->

---

## Community & Support

- [Arch Wiki](https://wiki.archlinux.org/) — For general Arch Linux troubleshooting
- Issues and feature requests: [GitHub Issues](https://github.com/asafelobotomy/xanados/issues)

---

## License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).

---
