# AGENTS_SECURITY.md

> **Security & Backup Agents**  
> _This file documents the tools used by `system_maint.sh` for vulnerability
scanning, rootkit detection, firewall auditing, and backup operations._

---

## 🛡️ Security & Auditing Tools

- **`arch-audit`**  
  A vulnerability scanner that checks installed Arch Linux packages for known
  CVEs (Common Vulnerabilities and Exposures).
  _Used to flag outdated or insecure software._

- **`rkhunter`**  
  Rootkit Hunter scans the system for known rootkits, backdoors, and other
  signs of intrusion.
  _Updates its database and runs a check with log summaries._

- **`ufw`**  
  The Uncomplicated Firewall. Used to check firewall status and rules.  
  _Only queried if installed._

---

## 💾 Backup Agents

- **`timeshift`**  
  Creates system snapshots for rollback. Ideal for backing up system states
  before performing risky operations.
  _Used if installed and available._

- **`snapper`**  
  Btrfs snapshot manager. An alternative to Timeshift for Btrfs-managed
  systems.
  _Only used if Timeshift is not available._

- **`rsync`**  
  Performs a full incremental backup of the root filesystem to a specified
  directory.
  _Optional and manually triggered during script execution._

---

## 🎮 Gaming Enhancements

- **`gamemode`**  
  A runtime daemon that optimizes the system for gaming workloads.  
  _The script checks its status if installed._

- **`nvidia-utils`**  
  Enables `nvidia-smi` for querying NVIDIA GPU status and temperatures.  
  _Optional; included for systems with NVIDIA GPUs._

---

## Notes

- All security-related tools are **optional but recommended**.
- If a tool is not installed, the script prompts the user to install or skip it.
- Skipping an agent disables its corresponding feature gracefully.
- Backups (via Timeshift, Snapper, or rsync) are triggered early to ensure
  recovery is possible.

---
