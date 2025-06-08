# Agents Refined

![CI](https://github.com/asafelobotomy/xanados/actions/workflows/ci.yml/badge.svg)

## Table of Contents

- [Overview](#overview)
- [Glossary](#glossary)
- [Agent Assignment Philosophy](#agent-assignment-philosophy)
  - [Single Point of Responsibility (SPR)](#single-point-of-responsibility-spr)
  - [Domain-Based Ownership](#domain-based-ownership)
  - [Task Encapsulation](#task-encapsulation)
  - [Delegation](#delegation)
  - [Emergency Override](#emergency-override)
  - [LintOps Enforcement](#lintops-enforcement)
- [Shared Resources](#shared-resources)
- [Agent Definitions](#agent-definitions)
  - [🧠 Codex-Core](#-codex-core)
  - [🎮 Codex-Gaming](#-codex-gaming)
  - [🔐 Codex-Security](#-codex-security)
  - [🖥️ Codex-Calamares](#-codex-calamares)
  - [🧹 Codex-LintOps](#-codex-lintops)
  - [🛠️ Codex-Infra](#-codex-infra)
  - [🎨 Codex-UX](#-codex-ux)
  - [🦮 Codex-FixIt (New)](#-codex-fixit-new)
  - [📚 Codex-Docs (New)](#-codex-docs-new)
- [Task Ownership Matrix](#task-ownership-matrix)
- [Conflict Avoidance Policy](#conflict-avoidance-policy)
- [Validation & Testing Requirements](#validation--testing-requirements)
  - [General Tools](#general-tools)
  - [Per-Agent Testing](#per-agent-testing)
- [Logging Policy](#logging-policy)
  - [JSON Log](#json-log)
  - [Human-Readable Log](#human-readable-log)
- [Agent Lifecycle](#agent-lifecycle)
- [Future Expansion Notes](#future-expansion-notes)
  - [When to Add an Agent](#when-to-add-an-agent)
  - [How to Add an Agent](#how-to-add-an-agent)
  - [Examples of Possible Agents](#examples-of-possible-agents)
- [Guardrails](#guardrails)

---

## Overview

Codex agents are intelligent automation units powered by Codex-ChatGPT and GitHub Copilot, tasked with maintaining the XanadOS Arch-based distribution. They ensure the independent and safe upkeep of subsystems like the gaming stack, security tools, installer, UX, CI, and more, leveraging knowledge from the Arch Wiki, forums, and Reddit.

**Each agent:**

- Has read-access to the entire repository and must only use ls -R when searching for full discoverability
- Has exclusive write-access to defined files/directories
- Runs pre-task feasibility checks
- Validates outputs using domain-specific tests and linting
- Logs both machine- and human-readable results
- Timestamps and logs are standardized to London time.

---

## Glossary

- **Agent**: An automation unit responsible for a subsystem or domain.
- **Domain**: The area of responsibility for an agent.
- **SPR**: Single Point of Responsibility; ensures only one agent writes to a file or directory.
- **LintOps**: Linting and formatting operations, enforced by Codex-LintOps.
- **CI**: Continuous Integration.

---

## Agent Assignment Philosophy

### Single Point of Responsibility (SPR)

Each file or directory is writable by **one agent only**. This ensures accountability and prevents conflicting logic.

### Domain-Based Ownership

Agents are assigned by domain (e.g., gaming, installer, core), inspired by Unix modularity and Arch packaging discipline.

### Task Encapsulation

Multi-component tasks (e.g., kernel patch plus gaming optimization) are assigned wholly to one agent.

### Delegation

Agents cannot modify files outside their domain. Delegated tasks must be logged, with both the source and target agent identified.

### Emergency Override

In critical scenarios (e.g., ISO build failure), agents may override domain rules with an explicit audit log.

### LintOps Enforcement

Codex-LintOps defines standards for formatting, linting, CI configuration, and validation enforcement.

---

## Shared Resources

Some files or directories may be shared as **read-only** or used for reference by multiple agents. All such shared resources must be documented here:

- `README.md`
- `LICENSE`
- `.gitignore`
- Documentation in `docs/`
- Top-level changelogs

---

## Agent Definitions

### 🧠 Codex-Core

- **Domain:** ISO architecture, kernel variants, base layout
- **Owns:** [`xanados-iso/profiledef.sh`](xanados-iso/profiledef.sh), [`build.sh`](build.sh), [`xanados-iso/package-options.conf`](xanados-iso/package-options.conf), mirror logic
- **Validation:** ISO builds with correct kernel flags and mirror config

### 🎮 Codex-Gaming

- **Domain:** Game support layers, launchers, optimizations
- **Owns:** [`xanados-iso/airootfs/usr/bin/install_gaming.sh`](xanados-iso/airootfs/usr/bin/install_gaming.sh), [`xanados-iso/airootfs/usr/bin/packages/gaming/`](xanados-iso/airootfs/usr/bin/packages/gaming/), Proton tweaks, MangoHud, and vkBasalt
- **Validation:** `paru -Si` resolution, dry-run install success

### 🔐 Codex-Security

- **Domain:** Hardening, antivirus, boot security, firewall
- **Owns:** [`xanados-iso/calamares/modules/secureboot-toggle/`](xanados-iso/calamares/modules/secureboot-toggle/), UFW/nftables, [`xanados-iso/airootfs/etc/clamav.conf`](xanados-iso/airootfs/etc/clamav.conf), [`xanados-iso/airootfs/etc/rkhunter.conf`](xanados-iso/airootfs/etc/rkhunter.conf)
- **Validation:** Secure boot test VM, passing scans

### 🖥️ Codex-Calamares

- **Domain:** Installer logic, Calamares scripts, post-install modules
- **Owns:** [`xanados-iso/calamares/`](xanados-iso/calamares/), [`xanados-iso/calamares/settings.conf`](xanados-iso/calamares/settings.conf), YAML modules, custom install scripts
- **Validation:** QEMU install success, filesystem validation

### 🧹 Codex-LintOps

- **Domain:** Code health, CI pipelines, format enforcement
- **Owns:** [`.github/`](.github/), [`var/tests/`](var/tests/), [`.eslintrc`](.eslintrc), [`.prettierrc`](.prettierrc), [`black`](https://github.com/psf/black), [`markdownlint`](https://github.com/DavidAnson/markdownlint)
- **Validation:** CI passes, zero linting issues

### 🛠️ Codex-Infra

- **Domain:** Virtual environments, ISO deployment, Docker testbeds
- **Owns:** `Dockerfile*`, [`var/VM/`](var/VM/), [`var/out/`](var/out/), mirror scripts
- **Validation:** ISO artifacts and Docker boot success

### 🎨 Codex-UX

- **Domain:** Aesthetic polish and branding
- **Owns:** [`xanados-iso/airootfs/etc/skel/`](xanados-iso/airootfs/etc/skel/), [`xanados-iso/airootfs/usr/share/themes/`](xanados-iso/airootfs/usr/share/themes/), [`xanados-iso/airootfs/usr/share/plymouth/`](xanados-iso/airootfs/usr/share/plymouth/), [`xanados-iso/airootfs/usr/share/wallpapers/`](xanados-iso/airootfs/usr/share/wallpapers/), login manager themes
- **Validation:** Theming applies correctly to greeter/DE; valid wallpaper paths

### 🦮 Codex-FixIt (New)

- **Domain:** Bug fixes, missing files, deprecated package/tool replacement, conflict resolution
- **Owns:** [`fixes/`](fixes/), `*.patch`, `*.bak`, refactoring scripts, deprecation tracker
- **Validation:** Repo build/test passes, deprecated items resolved, issue tracker cleared

### 📚 Codex-Docs (New)

- **Domain:** Documentation consistency and updates
- **Owns:** `*.md`, [`docs/`](docs/), changelogs, help scripts
- **Validation:** Passes markdownlint, consistent formatting, updated references

---

## Task Ownership Matrix

| Agent           | Domain        | Write Access                                                                 |
|-----------------|--------------|------------------------------------------------------------------------------|
| Codex-Core      | ISO/Kernel   | [`xanados-iso/build.sh`](xanados-iso/build.sh), [`xanados-iso/profiledef.sh`](xanados-iso/profiledef.sh), etc.                    |
| Codex-Gaming    | Gaming Stack | [`xanados-iso/airootfs/usr/bin/install_gaming.sh`](xanados-iso/airootfs/usr/bin/install_gaming.sh), [`xanados-iso/airootfs/usr/bin/packages/gaming/`](xanados-iso/airootfs/usr/bin/packages/gaming/) |
| Codex-Security  | Security     | [`xanados-iso/calamares/modules/secureboot-toggle/`](xanados-iso/calamares/modules/secureboot-toggle/), configs                  |
| Codex-Calamares | Installer    | [`xanados-iso/calamares/`](xanados-iso/calamares/), [`xanados-iso/calamares/modules/*.yaml`](xanados-iso/calamares/modules/), [`xanados-iso/calamares/settings.conf`](xanados-iso/calamares/settings.conf) |
| Codex-LintOps   | CI/Linting   | [`.github/`](.github/), [`var/tests/`](var/tests/), format configs                                     |
| Codex-Infra     | Infrastructure| `Dockerfile*`, [`var/VM/`](var/VM/), [`var/out/`](var/out/), mirror scripts                        |
| Codex-UX        | UX/Branding  | [`xanados-iso/airootfs/etc/skel/`](xanados-iso/airootfs/etc/skel/), [`xanados-iso/airootfs/usr/share/themes/`](xanados-iso/airootfs/usr/share/themes/), wallpapers/ |
| Codex-FixIt     | Maintenance  | [`fixes/`](fixes/), `*.patch`, deprecated tools                                        |
| Codex-Docs      | Documentation| [`docs/`](docs/), `*.md`, changelogs                                                 |

---

## Conflict Avoidance Policy

- One agent per writable scope
- Delegations must be logged
- Overrides allowed only via emergency procedure with audit trail
- All merges require CI and validations

---

## Validation & Testing Requirements

### General Tools

- **Shell:** `shellcheck`, `shfmt`
- **Python:** `black`, `pylint`
- **YAML/JSON:** `yamllint`, `jq`
- **Markdown/Node:** `eslint`, `prettier`, `markdownlint-cli`

### Per-Agent Testing

| Agent           | Validation Requirements                                      |
|-----------------|-------------------------------------------------------------|
| Codex-Core      | ISO builds, kernel configs, mirror validation               |
| Codex-Gaming    | Dry-run pass, package existence, launcher test              |
| Codex-Security  | VM boot, ClamAV and rkhunter validation                     |
| Codex-Calamares | QEMU install, partitioning, user creation                   |
| Codex-LintOps   | CI green, no test/lint failures                             |
| Codex-Infra     | ISO boot, container tests                                   |
| Codex-UX        | Theme validation, greeter test                              |
| Codex-FixIt     | Fixes applied, deprecated tools resolved, tests pass        |
| Codex-Docs      | Formatting consistency, references updated, markdownlint OK  |

---

## Logging Policy

### JSON Log

- **Path:** `/xanados/var/logs/codex/AGENT_YYYYMMDD_HHMMSS.json`
- **Fields:** `timestamp`, `task_description`, `files_modified`, `validation_results`, `outcome: SUCCESS / FAIL / NO_ACTION`, `commit_id`, `branch`

### Human-Readable Log

- **Path:** `/xanados/var/logs/codex/AGENT_YYYYMMDD_HHMMSS.log.txt`
- **Contents:** Summary format, key highlights, timestamp, affected scope

---

## Agent Lifecycle

- Agents may be added, merged, split, or deprecated as domains change.
- Deprecation or major changes must be discussed in a PR and logged in the human-readable log.
- All changes must update this document and the Task Ownership Matrix.

---

## Future Expansion Notes

### When to Add an Agent

- A new domain emerges (e.g., telemetry, localization)
- An existing agent becomes overloaded
- New validation tools or workflows are introduced

### How to Add an Agent

- [ ] Define domain, scope, and validation
- [ ] Register in Task Ownership Matrix
- [ ] Implement JSON and human-readable logging
- [ ] Submit PR with passing tests and logs

### Examples of Possible Agents

- Codex-Hardware: Drivers, detection, microcode
- Codex-Network: VPN, DNS, net profiles
- Codex-Locale: I18n, timezones, keymaps
- Codex-Telemetry: Metrics, crash logs, diagnostics

---

## Guardrails

- Domains must be minimal and well-defined
- All agents require CI integration (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml))
- All additions must update this document
- Agents must respect scope and logging conventions
