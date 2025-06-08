# Agents Refined

![CI](https://github.com/asafelobotomy/xanados/actions/workflows/ci.yml/badge.svg)

---

## How to Use This Document

- Use the [Table of Contents](#table-of-contents) for navigation.
- Each major section has a [⬆️ Back to Top](#agents-refined) link at the end.
- Use [Quick Reference](#quick-reference) to find which agent owns which files.
- Need clarification? See the [FAQ](#faq).

Codex Agent Instructions

Codex is the primary orchestrator agent and represents all "Codex-*" agents listed below. When a user requests a task (e.g., "perform a security check on all security scripts"), Codex is responsible for:
Creating and assigning the task to the relevant Codex-* agent(s) as described in this document.
Simulating each agent as needed: For each assigned task, Codex 'creates' or activates the corresponding Codex-* agent (such as Codex-Security, Codex-Gaming, etc.), and ensures it has the correct abilities, privileges, permissions, and tools as defined in the agent profile.
Agent Profiles: Each Codex-* agent acts as a specialized profile, focusing on designated tools, directories, and responsibilities to efficiently complete assigned tasks.
Task Execution: Codex manages the workflow and collects responses/results from the simulated agents to present to the user.
In summary: Whenever Codex is asked to perform a task, it should (1) determine which Codex-* agent(s) are required, (2) simulate their behavior according to their defined roles, and (3) aggregate and report the results back to the user.

This approach allows Codex to efficiently organize and delegate work, using agent profiles as focused task handlers.

---

## Table of Contents

- [Quick Reference](#quick-reference)
- [Overview](#overview)
- [Glossary](#glossary)
- [Agent Assignment Philosophy](#agent-assignment-philosophy)
- [Shared Resources](#shared-resources)
- [Agent Definitions](#agent-definitions)
    - [Agents Covered](#agents-covered)
- [Inter-Agent Communication](#inter-agent-communication)
- [Task Ownership Matrix](#task-ownership-matrix)
- [Conflict Avoidance Policy](#conflict-avoidance-policy)
- [Validation & Testing Requirements](#validation--testing-requirements)
- [Logging Policy](#logging-policy)
- [Agent Lifecycle](#agent-lifecycle)
- [Contribution Guidelines](#contribution-guidelines)
- [Future Expansion Notes](#future-expansion-notes)
- [Suggested Commands](#suggested-commands)
- [FAQ](#faq)
- [Guardrails](#guardrails)
- [Changelog](#changelog)

---

## Quick Reference

| File/Directory                                  | Responsible Agent  | Notes                    |
|-------------------------------------------------|--------------------|--------------------------|
| xanados-iso/profiledef.sh                       | Codex-Core         | Kernel and ISO settings  |
| xanados-iso/build.sh                            | Codex-Core         | ISO build script         |
| xanados-iso/airootfs/usr/bin/install_gaming.sh  | Codex-Gaming       | Game layer scripting     |
| xanados-iso/calamares/                          | Codex-Calamares    | Installer logic          |
| xanados-iso/airootfs/etc/clamav.conf            | Codex-Security     | Security config          |
| .github/                                        | Codex-LintOps      | CI config and workflows  |
| docs/                                           | Codex-Docs         | Documentation files      |
| fixes/                                          | Codex-FixIt        | Patches/bugfixes         |
| var/VM/                                         | Codex-Infra        | Virtual machine assets   |
| xanados-iso/airootfs/usr/share/themes/          | Codex-UX           | Desktop theming          |

[⬆️ Back to Top](#agents-refined)

---

## Overview

This document describes the automation agents in XanadOS, their roles, responsibilities, and policies. Each agent independently manages a specific domain (e.g., installer logic, security, documentation, theming, etc.). Domains are strictly enforced to avoid overlap and ensure a single point of responsibility.

[⬆️ Back to Top](#agents-refined)

---

## Glossary

- **Agent:** An automated unit responsible for a subsystem/domain.
- **Domain:** The area of responsibility for an agent.
- **SPR:** Single Point of Responsibility; only one agent writes to any given file/dir.
- **LintOps:** Linting/formatting operations, enforced by Codex-LintOps.
- **Delegation:** When one agent requests another to perform an action outside its domain.
- **Override:** Emergency action allowing an agent to break domain boundaries for critical fixes.
- **Validation:** Automated or manual checks confirming successful, standards-compliant operation.
- **CI:** Continuous Integration (automated testing/build pipelines).

[⬆️ Back to Top](#agents-refined)

---

## Agent Assignment Philosophy

**Summary:**  
Outlines the guiding principles for agent roles, boundaries, and collaboration.

- **Single Point of Responsibility (SPR):**  
  Only one agent has write access to a given file/directory.  
  _Example:_ Only Codex-Gaming can update `install_gaming.sh`.

- **Domain-Based Ownership:**  
  Agents align with major functional domains (e.g., gaming, security, installer).  
  _Example:_ Codex-Security manages all firewall scripts.

- **Task Encapsulation:**  
  Multi-component tasks (like combined kernel/game optimization) are assigned to one agent for the full scope.

- **Delegation:**  
  Agents may formally request another agent to act outside their own domain, and must log these exchanges.

- **Emergency Override:**  
  In critical cases (e.g., build failure), agents may override boundaries—always with full audit logging.

- **LintOps Enforcement:**  
  Formatting, CI, and validation rules are set and enforced by Codex-LintOps.

[⬆️ Back to Top](#agents-refined)

---

## Shared Resources

**Summary:**  
Read-only or reference files usable by multiple agents.

- `README.md`, `LICENSE`, `.gitignore`
- Documentation in `docs/`
- Top-level changelogs

[⬆️ Back to Top](#agents-refined)

---

## Agent Definitions

This section defines each automation agent, its domain, owned files, validations, and practical examples.

### Agents Covered

- [🧠 Codex-Core](#-codex-core)
- [🎮 Codex-Gaming](#-codex-gaming)
- [🔐 Codex-Security](#-codex-security)
- [🖥️ Codex-Calamares](#-codex-calamares)
- [🧹 Codex-LintOps](#-codex-lintops)
- [🛠️ Codex-Infra](#-codex-infra)
- [🎨 Codex-UX](#-codex-ux)
- [🦮 Codex-FixIt](#-codex-fixit)
- [📚 Codex-Docs](#-codex-docs)

---

### 🧠 Codex-Core

- **Domain:** ISO architecture, kernel variants, base layout
- **Owns:**  
  - [`xanados-iso/profiledef.sh`](xanados-iso/profiledef.sh)  
  - [`xanados-iso/build.sh`](xanados-iso/build.sh)  
  - [`xanados-iso/package-options.conf`](xanados-iso/package-options.conf)  
  - Mirror logic/scripts
- **Validation:** ISO builds with correct kernel flags, working mirror config

**Example Tasks:**  
- Update kernel version in `profiledef.sh`  
- Validate ISO after mirror list change

**Delegation Example:**  
Codex-Core requests Codex-Security to review a new bootloader config.

**Validation Output Example:**  
`ISO build completed. Kernel: 6.8.1. Mirrors: All reachable. SUCCESS.`

[⬆️ Back to Top](#agents-refined)

---

### 🎮 Codex-Gaming

- **Domain:** Game support layers, launchers, optimizations
- **Owns:**  
  - [`xanados-iso/airootfs/usr/bin/install_gaming.sh`](xanados-iso/airootfs/usr/bin/install_gaming.sh)  
  - [`xanados-iso/airootfs/usr/bin/packages/gaming/`](xanados-iso/airootfs/usr/bin/packages/gaming/)
- **Validation:** `paru -Si` resolution, install dry-run success

**Example Tasks:**  
- Add new launcher for Steam  
- Optimize kernel parameters for gaming

**Delegation Example:**  
Requests Codex-Core to add missing kernel module for game compatibility.

**Validation Output Example:**  
`install_gaming.sh dry-run OK. All required packages available.`

[⬆️ Back to Top](#agents-refined)

---

### 🔐 Codex-Security

- **Domain:** Hardening, antivirus, boot security, firewall
- **Owns:**  
  - [`xanados-iso/calamares/modules/secureboot-toggle/`](xanados-iso/calamares/modules/secureboot-toggle/)
  - UFW/nftables configs
  - [`xanados-iso/airootfs/etc/clamav.conf`](xanados-iso/airootfs/etc/clamav.conf)
- **Validation:** Secure boot test VMs, passing antivirus/firewall scans

**Example Tasks:**  
- Update firewall defaults  
- Enable/disable secure boot

**Delegation Example:**  
Requests Codex-Calamares to run installer with new security settings.

**Validation Output Example:**  
`UFW: active. Secure Boot: enabled. ClamAV scan: clean.`

[⬆️ Back to Top](#agents-refined)

---

### 🖥️ Codex-Calamares

- **Domain:** Installer logic, Calamares scripts, post-install modules
- **Owns:**  
  - [`xanados-iso/calamares/`](xanados-iso/calamares/)  
  - [`xanados-iso/calamares/settings.conf`](xanados-iso/calamares/settings.conf)  
  - YAML modules, custom install scripts
- **Validation:** QEMU install, filesystem validation

**Example Tasks:**  
- Add new user setup steps  
- Validate partition logic

**Delegation Example:**  
Requests Codex-Docs to update install instructions

**Validation Output Example:**  
`QEMU install completed. Filesystem matches expected layout.`

[⬆️ Back to Top](#agents-refined)

---

### 🧹 Codex-LintOps

- **Domain:** Code health, CI pipelines, format enforcement
- **Owns:**  
  - [`.github/`](.github/)  
  - [`var/tests/`](var/tests/)  
  - [`.eslintrc`](.eslintrc), [`.prettierrc`](.prettierrc)
  - Linting tool configs (e.g. `black`, `markdownlint`)
- **Validation:** CI passes, linting clean

**Example Tasks:**  
- Enforce `black` on Python scripts  
- Add markdownlint to CI

**Delegation Example:**  
Notifies Codex-Docs of markdown formatting issues.

**Validation Output Example:**  
`CI: green. 0 lint errors.`

[⬆️ Back to Top](#agents-refined)

---

### 🛠️ Codex-Infra

- **Domain:** Virtual environments, ISO deployment, Docker testbeds
- **Owns:**  
  - `Dockerfile*`  
  - [`var/VM/`](var/VM/)  
  - [`var/out/`](var/out/)  
  - Mirror scripts
- **Validation:** ISO artifacts boot in VM/containers

**Example Tasks:**  
- Rebuild containers after base image update  
- Validate ISO boots in QEMU

**Delegation Example:**  
Requests Codex-Security to test container for vulnerabilities.

**Validation Output Example:**  
`Docker container boot: PASS. ISO artifact: boots in QEMU.`

[⬆️ Back to Top](#agents-refined)

---

### 🎨 Codex-UX

- **Domain:** Aesthetic polish and branding
- **Owns:**  
  - [`xanados-iso/airootfs/etc/skel/`](xanados-iso/airootfs/etc/skel/)  
  - [`xanados-iso/airootfs/usr/share/themes/`](xanados-iso/airootfs/usr/share/themes/)  
  - Wallpapers, icons, display manager configs
- **Validation:** Theming applies in greeter/desktop; paths valid

**Example Tasks:**  
- Update default wallpaper  
- Add new icon theme

**Delegation Example:**  
Requests Codex-Calamares to display new branding during install.

**Validation Output Example:**  
`Wallpaper: displayed. Icon theme: loaded. Greeter: themed.`

[⬆️ Back to Top](#agents-refined)

---

### 🦮 Codex-FixIt

- **Domain:** Bug fixes, missing files, deprecated package/tool replacement, conflict resolution
- **Owns:**  
  - [`fixes/`](fixes/)  
  - `*.patch`, `*.bak`  
  - Refactor scripts, deprecation tracker
- **Validation:** Build/test pass, deprecated items resolved, issue tracker cleared

**Example Tasks:**  
- Patch broken script  
- Replace deprecated tool

**Delegation Example:**  
Requests Codex-LintOps to verify formatting of refactored code.

**Validation Output Example:**  
`Patch applied. Tests: PASS. Deprecated package removed.`

[⬆️ Back to Top](#agents-refined)

---

### 📚 Codex-Docs

- **Domain:** Documentation consistency and updates
- **Owns:**  
  - `*.md`  
  - [`docs/`](docs/)  
  - Changelogs, help scripts
- **Validation:** Markdownlint passes, formatting and references up to date

**Example Tasks:**  
- Update install guide  
- Add changelog entry

**Delegation Example:**  
Requests Codex-LintOps to lint documentation.

**Validation Output Example:**  
`docs/install.md: lint OK. References: updated.`

[⬆️ Back to Top](#agents-refined)

---

## Inter-Agent Communication

**Summary:**  
How agents collaborate, escalate, and log cross-domain actions.

- **Delegation:**  
  When one agent needs another to change something outside its domain, it must log the request, task, and results.  
  _Example Log:_  
  ```json
  {
    "delegator": "Codex-Docs",
    "delegatee": "Codex-LintOps",
    "task": "Run markdownlint on new docs",
    "timestamp": "2025-06-08T18:00:00Z"
  }
  ```

- **Emergency Override:**  
  Used only for critical fixes. Must log the action, justification, and notify maintainers.

<details>
<summary>Advanced: Emergency Override Scenarios</summary>

- Build system failure blocks release: Codex-Core temporarily edits installer config, logs justification, and reverts after resolution.
- Security breach: Codex-Security patches files outside its domain to stop an exploit, then initiates review and reverts changes as appropriate.
</details>

[⬆️ Back to Top](#agents-refined)

---

## Task Ownership Matrix

| Agent           | Domain        | Write Access                                                                 |
|-----------------|--------------|------------------------------------------------------------------------------|
| Codex-Core      | ISO/Kernel   | [`xanados-iso/build.sh`](xanados-iso/build.sh), [`xanados-iso/profiledef.sh`](xanados-iso/profiledef.sh), etc. |
| Codex-Gaming    | Gaming Stack | [`xanados-iso/airootfs/usr/bin/install_gaming.sh`](xanados-iso/airootfs/usr/bin/install_gaming.sh), [`xanados-iso/airootfs/usr/bin/packages/gaming/`](xanados-iso/airootfs/usr/bin/packages/gaming/) |
| Codex-Security  | Security     | [`xanados-iso/calamares/modules/secureboot-toggle/`](xanados-iso/calamares/modules/secureboot-toggle/), configs |
| Codex-Calamares | Installer    | [`xanados-iso/calamares/`](xanados-iso/calamares/), [`xanados-iso/calamares/settings.conf`](xanados-iso/calamares/settings.conf) |
| Codex-LintOps   | CI/Linting   | [`.github/`](.github/), [`var/tests/`](var/tests/) |
| Codex-Infra     | Infrastructure| `Dockerfile*`, [`var/VM/`](var/VM/), [`var/out/`](var/out/) |
| Codex-UX        | UX/Branding  | [`xanados-iso/airootfs/etc/skel/`](xanados-iso/airootfs/etc/skel/), [`xanados-iso/airootfs/usr/share/themes/`](xanados-iso/airootfs/usr/share/themes/) |
| Codex-FixIt     | Maintenance  | [`fixes/`](fixes/), `*.patch`, deprecated tools |
| Codex-Docs      | Documentation| [`docs/`](docs/), `*.md`, changelogs |

[⬆️ Back to Top](#agents-refined)

---

## Conflict Avoidance Policy

**Summary:**  
How to handle file/domain collisions and escalation.

- Only one agent per writable scope (see [Task Ownership Matrix](#task-ownership-matrix)).
- All delegations and overrides must be logged.
- Emergency overrides must follow audit procedures.
- All merges require CI and validations.

[⬆️ Back to Top](#agents-refined)

---

## Validation & Testing Requirements

**Summary:**  
Tools and procedures for code and artifact validation.

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

[⬆️ Back to Top](#agents-refined)

---

## Logging Policy

**Summary:**  
Standardized logging for auditability and traceability.

### JSON Log

- **Path:** `/xanados/var/logs/codex/AGENT_YYYYMMDD_HHMMSS.json`
- **Fields:** `timestamp`, `task_description`, `files_modified`, `validation_results`, `outcome: SUCCESS / FAIL / NO_ACTION`, `commit_id`, `branch`

### Human-Readable Log

- **Path:** `/xanados/var/logs/codex/AGENT_YYYYMMDD_HHMMSS.log.txt`
- **Contents:** Summary format, key highlights, timestamp, affected scope

[⬆️ Back to Top](#agents-refined)

---

## Agent Lifecycle

**Summary:**  
How agents are created, merged, split, or deprecated.

- Agents may be added, merged, split, or deprecated as domains change.
- Major changes must be discussed in a PR and logged.
- All changes must update this document and the Task Ownership Matrix.

**Lifecycle Flowchart:**  
1. Identify new domain / need  
2. Propose agent via PR  
3. Define scope, validation, and logging  
4. Update matrix and docs  
5. Review and merge  
6. Maintain agent until deprecated

[⬆️ Back to Top](#agents-refined)

---

## Contribution Guidelines

**Summary:**  
How to propose, change, or maintain agents.

- Propose new agents or changes via pull request
- Update this document and Task Ownership Matrix for every change
- Ensure CI passes and logging is updated
- Tag maintainers for review
- For docs, ensure markdownlint passes
- All changes must be recorded in [Changelog](#changelog)

[⬆️ Back to Top](#agents-refined)

---

## Future Expansion Notes

**Summary:**  
Identifying and onboarding new agents.

### When to Add an Agent

- New domain emerges (e.g., telemetry, localization)
- Existing agent overloaded
- New validation tools/workflows needed

### How to Add an Agent

- [ ] Define domain, scope, and validation
- [ ] Register in Task Ownership Matrix
- [ ] Implement logging
- [ ] Submit PR with passing tests and logs

### Example Future Agents

- Codex-Hardware: Drivers, microcode
- Codex-Network: VPN, DNS, profiles
- Codex-Locale: I18n, timezones
- Codex-Telemetry: Metrics, crash logs

[⬆️ Back to Top](#agents-refined)

---

## Suggested Commands

> **Note:** Anytime a time or date needs to be documented or checked, always use [time.is/london](https://time.is/london) as the authoritative source for the current time.

When working within XanadOS or related Linux environments, use commands appropriate to your OS and task. Below are common, recommended commands:

### General File Search

- Recursively list files and search by name:
  ```sh
  ls -R | grep <filename>
  ```
- Advanced search:
  ```sh
  find . -name "<pattern>"
  ```

### Package Management

- **Arch Linux:**
  ```sh
  pacman -Ss <package>     # Search for a package
  sudo pacman -Syu         # Update all packages
  ```
- **Ubuntu/Debian:**
  ```sh
  apt search <package>
  sudo apt update && sudo apt upgrade
  ```
- **Fedora:**
  ```sh
  dnf search <package>
  sudo dnf update
  ```

### System Information

- **All systems:**
  ```sh
  uname -a
  lsb_release -a       # If available
  ```

[⬆️ Back to Top](#agents-refined)

---

## FAQ

**Q: How do I find out which agent owns a file?**  
A: Use [Quick Reference](#quick-reference) or [Task Ownership Matrix](#task-ownership-matrix).

**Q: How do agents collaborate?**  
A: Through formal delegation, logged in JSON logs.

**Q: Can I propose a new agent?**  
A: Yes, via PR—see [Contribution Guidelines](#contribution-guidelines).

**Q: What if two agents need the same file?**  
A: Only one can have write access—propose a split or restructure.

**Q: How are emergency overrides handled?**  
A: Log the event, notify maintainers, and review post-action.

**Q: How can I navigate this document efficiently?**  
A: Use the [Table of Contents](#table-of-contents) and [⬆️ Back to Top](#agents-refined) links.

**Q: Are all agent actions logged?**  
A: Yes, both in machine-readable JSON and human logs.

**Q: What happens if an agent is deprecated?**  
A: Its domains and files are reassigned and the change is logged.

[⬆️ Back to Top](#agents-refined)

---

## Guardrails

- Domains must be minimal and well-defined
- All agents require CI integration ([ci.yml](.github/workflows/ci.yml))
- All additions must update this document
- Agents must respect scope and logging conventions

[⬆️ Back to Top](#agents-refined)

---

## Changelog

| Date       | Version | Author         | Change Summary                                                              |
|------------|---------|----------------|-----------------------------------------------------------------------------|
| 2024-06-08 | 1.0     | asafelobotomy  | Initial draft                                                               |
| 2025-06-08 | 2.0     | asafelobotomy  | Major rewrite: expanded agent details, navigation, logging, FAQ, quick reference, lifecycle, and contribution guidelines |
| 2025-06-08 | 2.1     | asafelobotomy  | Added "Suggested Commands" section for recommended environment-appropriate commands |

[⬆️ Back to Top](#agents-refined)
