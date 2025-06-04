# AGENTS_SYSTEM.md

> **System Maintenance Agents**  
> _This file documents the system-level agents used by the `system_maint.sh`
script to manage core functionality such as packages, storage, system
monitoring, and cleanup._

---

## 🔧 Package Managers

- **`pacman`**  
  Arch Linux's default package manager. Used to install, upgrade, and remove
  software packages.
  _Used when `paru` is not installed._

- **`paru`**  
  An AUR helper and frontend for `pacman`. Enables seamless access to Arch User
  Repository (AUR) packages.
  _Preferred if installed. Script prompts to install if missing._

---

## 💽 Storage & Filesystem Tools

- **`btrfs-progs`**  
  Provides utilities for Btrfs file system maintenance:
  `scrub`, `balance`, and `defragment` commands are used to keep the filesystem
  healthy.

- **`util-linux`**  
  Supplies essential utilities such as `fstrim` (for SSDs) and `lsblk`
  (for block device inspection).

- **`smartmontools`**  
  Provides `smartctl`, which is used to query and monitor the health of hard
  drives and SSDs via SMART.

---

## 🌐 Platform Tools

- **`flatpak`**  
  Enables support for Flatpak applications. The script uses it to update
  Flatpak-managed apps if installed.

---

## 🧪 Diagnostics & Monitoring

- **`pciutils`**  
  Includes `lspci`, used for identifying connected PCI devices such as GPUs and
  network cards.

- **`lm_sensors`**  
  Used to detect and report CPU and GPU temperatures and voltages via the
  `sensors` command.

---

## 🧹 System Cleanup

- **`paccache`**  
  Part of the `pacman-contrib` package. Used to clean outdated package versions
  from the local cache.

- **`journalctl`**  
  Systemd log viewer. Used to rotate logs older than 7 days and display
  critical error messages.

- **`systemctl`**  
  Core systemd utility for managing system services. The script checks for
  failed services.

---

## 📡 Network Operations

- **`reflector`**  
  Updates and ranks Arch mirrorlists by speed and protocol. Ensures fast and
  reliable package downloads.

- **`curl`**  
  Used to retrieve and display recent news from the Arch Linux RSS feed.

---

## Notes

- These agents are considered **essential** for the baseline operation of
  `system_maint.sh`.
- The script attempts to detect and use each tool. If a tool is missing and
  required, it will prompt for installation or skip the related functionality.

---
