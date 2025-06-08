# Agents Refined

![CI](https://github.com/asafelobotomy/xanados/actions/workflows/ci.yml/badge.svg)

---

## How to Use This Document

- Use the [Table of Contents](#table-of-contents) for navigation.
- Each major section has a [⬆️ Back to Top](#agents-refined) link at the end.
- Use [Quick Reference](#quick-reference) to find which agent owns which files.
- Need clarification? See the [FAQ](#faq).

---

## Codex Agent Instructions

Codex is the primary orchestrator agent and represents all "Codex-*" agents listed below.

- **Task Assignment:** When a user requests a task (e.g., "perform a security check on all security scripts"), Codex determines the relevant Codex-* agent(s), creates and assigns the task, and simulates their execution.
- **Agent Profiles:** Each Codex-* agent acts as a specialized profile, focusing on designated tools, directories, and responsibilities to efficiently complete assigned tasks.
- **Task Execution:** Codex manages the workflow and collects responses/results from the simulated agents to present to the user.
- **Summary:** Whenever Codex is asked to perform a task, it should (1) determine which Codex-* agent(s) are required, (2) simulate their behavior according to their defined roles, and (3) aggregate the results.

**Document Maintenance Policy:**  
Codex and all Codex-* agents must log their actions and domain changes to `var/logs/codex/` using the standard JSON and human-readable formats.  
Direct edits to AGENTS.md (including the changelog) are not permitted for automated changes—manual review is required for documentation changes.

This approach allows Codex to efficiently organize and delegate work, using agent profiles as focused task handlers, while maintaining auditability through external logs.

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

---

## Quick Reference

| File/Directory                                  | Responsible Agent  | Notes                    |
|-------------------------------------------------|--------------------|--------------------------|
| xanados-iso/profiledef.sh                       | Codex-Core         | Kernel and ISO settings  |
| xanados-iso/build.sh                            | Codex-Core         | ISO build script         |
| xanados-iso/airootfs/usr/bin/install_gaming.sh  | Codex-Gaming       | Game layer scripting     |
| xanados-iso/airootfs/usr/bin/packages/gaming/   | Codex-Gaming       | Package lists for games  |
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

This document describes the automation agents in XanadOS, their roles, responsibilities, and policies. Each agent independently manages a specific domain (e.g., installer logic, security, documentation), and all agent activity is logged for traceability.

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

- 🧠 Codex-Core
- 🎮 Codex-Gaming
- 🔐 Codex-Security
- 🖥️ Codex-Calamares
- 🧹 Codex-LintOps
- 🛠️ Codex-Infra
- 🎨 Codex-UX
- 🦮 Codex-FixIt
- 📚 Codex-Docs

---

### 🧠 Codex-Core

- **Domain:** ISO architecture, kernel variants, base layout
- **Owns:**  
  - `xanados-iso/profiledef.sh`  
  - `xanados-iso/build.sh`  
  - `xanados-iso/package-options.conf`  
  - Mirror logic/scripts
- **Validation:** ISO builds with correct kernel flags, working mirror config

**Example Tasks:**  
- Update kernel version in `profiledef.sh`  
- Validate ISO after mirror list change
- Troubleshoot bootloader issues and delegate security review

**Delegation Example:**  
Codex-Core requests Codex-Security to review a new bootloader config.

**Validation Output Example:**  
`ISO build completed. Kernel: 6.8.1. Mirrors: All reachable. SUCCESS.`

**Troubleshooting Tip:**  
If a build fails, see build logs in `/xanados/var/logs/codex`.

[⬆️ Back to Top](#agents-refined)

---

### 🎮 Codex-Gaming

- **Domain:** Game support layers, launchers, optimizations
- **Owns:**  
  - `xanados-iso/airootfs/usr/bin/install_gaming.sh`  
  - `xanados-iso/airootfs/usr/bin/packages/gaming/`
- **Validation:** `paru -Si` resolution, install dry-run success

**Example Tasks:**  
- Add new launcher for Steam  
- Optimize kernel parameters for gaming
- Update game-specific dependencies

**Delegation Example:**  
Requests Codex-Core to add missing kernel module for game compatibility.

**Validation Output Example:**  
`install_gaming.sh dry-run OK. All required packages available.`

**Troubleshooting Tip:**  
If a required package is missing, run `paru -Si <package>` to verify repository availability.

[⬆️ Back to Top](#agents-refined)

---

### 🔐 Codex-Security

- **Domain:** Hardening, antivirus, boot security, firewall
- **Owns:**  
  - `xanados-iso/calamares/modules/secureboot-toggle/`
  - UFW/nftables configs
  - `xanados-iso/airootfs/etc/clamav.conf`
- **Validation:** Secure boot test VMs, passing antivirus/firewall scans

**Example Tasks:**  
- Update firewall defaults  
- Enable/disable secure boot
- Patch security vulnerabilities (see FixIt for critical cross-domain fixes)

**Delegation Example:**  
Requests Codex-Calamares to run installer with new security settings.

**Validation Output Example:**  
`UFW: active. Secure Boot: enabled. ClamAV scan: clean.`

**Troubleshooting Tip:**  
For failed antivirus scans, check `/var/log/clamav/clamav.log`.

[⬆️ Back to Top](#agents-refined)

---

### 🖥️ Codex-Calamares

- **Domain:** Installer logic, Calamares scripts, post-install modules
- **Owns:**  
  - `xanados-iso/calamares/`
  - `xanados-iso/calamares/settings.conf`
  - YAML modules, custom install scripts
- **Validation:** QEMU install, filesystem validation

**Example Tasks:**  
- Add new user setup steps  
- Validate partition logic
- Integrate new branding from Codex-UX

**Delegation Example:**  
Requests Codex-Docs to update install instructions

**Validation Output Example:**  
`QEMU install completed. Filesystem matches expected layout.`

**Troubleshooting Tip:**  
Use QEMU logs to diagnose failed install steps.

[⬆️ Back to Top](#agents-refined)

---

### 🧹 Codex-LintOps

- **Domain:** Code health, CI pipelines, format enforcement
- **Owns:**  
  - `.github/`
  - `var/tests/`
  - `.eslintrc`, `.prettierrc`
  - Linting tool configs (e.g. `black`, `markdownlint`)
- **Validation:** CI passes, linting clean

**Example Tasks:**  
- Enforce `black` on Python scripts  
- Add markdownlint to CI
- Audit all agents' formatting rules

**Delegation Example:**  
Notifies Codex-Docs of markdown formatting issues.

**Validation Output Example:**  
`CI: green. 0 lint errors.`

**Troubleshooting Tip:**  
If CI fails, review `.github/workflows/ci.yml` and referenced logs.

[⬆️ Back to Top](#agents-refined)

---

### 🛠️ Codex-Infra

- **Domain:** Virtual environments, ISO deployment, Docker testbeds
- **Owns:**  
  - `Dockerfile*`
  - `var/VM/`
  - `var/out/`
  - Mirror scripts
- **Validation:** ISO artifacts boot in VM/containers

**Example Tasks:**  
- Rebuild containers after base image update  
- Validate ISO boots in QEMU

**Delegation Example:**  
Requests Codex-Security to test container for vulnerabilities.

**Validation Output Example:**  
`Docker container boot: PASS. ISO artifact: boots in QEMU.`

**Troubleshooting Tip:**  
Check Docker or QEMU logs for failed boot attempts.

[⬆️ Back to Top](#agents-refined)

---

### 🎨 Codex-UX

- **Domain:** Aesthetic polish and branding
- **Owns:**  
  - `xanados-iso/airootfs/etc/skel/`
  - `xanados-iso/airootfs/usr/share/themes/`
  - Wallpapers, icons, display manager configs
- **Validation:** Theming applies in greeter/desktop; paths valid

**Example Tasks:**  
- Update default wallpaper  
- Add new icon theme

**Delegation Example:**  
Requests Codex-Calamares to display new branding during install.

**Validation Output Example:**  
`Wallpaper: displayed. Icon theme: loaded. Greeter: themed.`

**Troubleshooting Tip:**  
For theming issues, check .xsession-errors or display manager logs.

[⬆️ Back to Top](#agents-refined)

---

### 🦮 Codex-FixIt

- **Domain:** Bug fixes, missing files, deprecated package/tool replacement, conflict resolution
- **Owns:**  
  - `fixes/`
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

**Troubleshooting Tip:**  
Refer to the issue tracker for unresolved conflicts or deprecated packages.

[⬆️ Back to Top](#agents-refined)

---

### 📚 Codex-Docs

- **Domain:** Documentation consistency and updates
- **Owns:**  
  - `*.md`
  - `docs/`
  - Changelogs, help scripts
- **Validation:** Markdownlint passes, formatting and references up to date

**Example Tasks:**  
- Update install guide  
- Add changelog entry

**Delegation Example:**  
Requests Codex-LintOps to lint documentation.

**Validation Output Example:**  
`docs/install.md: lint OK. References: updated.`

**Troubleshooting Tip:**  
Run `markdownlint-cli` for detailed feedback on formatting.

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

**Visual Flowchart:**
```
[Agent] --> [Delegation Log] --> [Delegatee] --> [Validation Log]
                    |
         [Emergency Override?]
                    |
         [Log & Notify Maintainers]
```

[⬆️ Back to Top](#agents-refined)

---

## Task Ownership Matrix

<details>
<summary>Expand Table</summary>

| Agent           | Domain        | Write Access                                                                 |
|-----------------|--------------|------------------------------------------------------------------------------|
| Codex-Core      | ISO/Kernel   | `xanados-iso/build.sh`, `xanados-iso/profiledef.sh`, etc.                    |
| Codex-Gaming    | Gaming Stack | `xanados-iso/airootfs/usr/bin/install_gaming.sh`, `xanados-iso/airootfs/usr/bin/packages/gaming/` |
| Codex-Security  | Security     | `xanados-iso/calamares/modules/secureboot-toggle/`, configs                  |
| Codex-Calamares | Installer    | `xanados-iso/calamares/`, `xanados-iso/calamares/settings.conf`              |
| Codex-LintOps   | CI/Linting   | `.github/`, `var/tests/`                                                     |
| Codex-Infra     | Infrastructure| `Dockerfile*`, `var/VM/`, `var/out/`                                        |
| Codex-UX        | UX/Branding  | `xanados-iso/airootfs/etc/skel/`, `xanados-iso/airootfs/usr/share/themes/`   |
| Codex-FixIt     | Maintenance  | `fixes/`, `*.patch`, deprecated tools                                        |
| Codex-Docs      | Documentation| `docs/`, `*.md`, changelogs                                                  |
</details>

[⬆️ Back to Top](#agents-refined)

---

## Conflict Avoidance Policy

**Summary:**  
How to handle file/domain collisions and escalation.

- Only one agent per writable scope (see [Task Ownership Matrix](#task-ownership-matrix)).
- All delegations and overrides must be logged.
- Emergency overrides must follow audit procedures.
- All merges require CI and validations.

**Resolution Steps for Violations:**
1. Identify scope violation in logs.
2. Notify maintainers and affected agents.
3. Apply patch via Codex-FixIt or revert change.
4. Log resolution and update documentation if needed.

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

### Validation Checklist Template

```markdown
- [ ] Build/CI passes
- [ ] Domain-specific validation (see matrix)
- [ ] Linting clean
- [ ] Documentation updated
- [ ] Logs recorded
```

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

**All agent and automation-driven changes must be logged exclusively in `var/logs/codex/` and not in AGENTS.md.**

### JSON Log

- **Path:** `/xanados/var/logs/codex/AGENT_YYYYMMDD_HHMMSS.json`
- **Fields:** `timestamp`, `task_description`, `files_modified`, `validation_results`, `outcome: SUCCESS / FAIL / NO_ACTION`, `commit_id`, `branch`

**Example:**
```json
{
  "timestamp": "2025-06-08T19:29:27Z",
  "task_description": "Applied firewall update",
  "files_modified": ["xanados-iso/airootfs/etc/clamav.conf"],
  "validation_results": "ClamAV scan: clean.",
  "outcome": "SUCCESS",
  "commit_id": "abcdef123456",
  "branch": "main"
}
```

### Human-Readable Log

- **Path:** `/xanados/var/logs/codex/AGENT_YYYYMMDD_HHMMSS.log.txt`
- **Contents:** Summary format, key highlights, timestamp, affected scope

**Example:**
```
[2025-06-08 19:29:27] Codex-Security: Applied firewall update. Validation: ClamAV scan clean. Files: xanados-iso/airootfs/etc/clamav.conf. Outcome: SUCCESS.
```

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

- Propose new agents or changes via pull request.
- **Before formulating a pull request, all agents must re-download (fetch/clone) the latest state of the repository and check for conflicts with their proposed changes. If conflicts are detected, agents must omit the conflicting changes from their PR.**
- Update this document and Task Ownership Matrix for every *manual* or *policy* change.
- Ensure CI passes and logging is updated.
- Tag maintainers for review.
- For docs, ensure markdownlint passes.
- **Automated/agent-driven changes:**  
   - Must generate a detailed, timestamped report in `var/logs/codex/`.
   - **Do not update [AGENTS.md](AGENTS.md) or the changelog directly for automated changes.**
- All manual or policy changes must be recorded in version control history.

**Checklist for Contributors:**
- [ ] PR submitted and reviewed
- [ ] Repository re-downloaded and checked for conflicts before PR creation (automated agents must omit conflicting changes)
- [ ] CI green
- [ ] Documentation updated (manual/policy changes only)
- [ ] Logging implemented (all changes)
- [ ] Changelog entry added (manual/policy changes only, if changelog is reinstated)

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

- **Codex-Hardware:** Drivers, microcode (e.g., automate CPU microcode updates and GPU driver selection; impact: hardware compatibility)
- **Codex-Network:** VPN, DNS, profiles (e.g., manage network configuration, profile switching; impact: improved connectivity and security)
- **Codex-Locale:** I18n, timezones (e.g., add localization scripts and region-specific settings; impact: global usability)
- **Codex-Telemetry:** Metrics, crash logs (e.g., collect and submit opt-in crash reports; impact: reliability and analytics)

[⬆️ Back to Top](#agents-refined)

---

## Suggested Commands

> **Note:** Anytime a time or date needs to be documented or checked, always use [time.is/london](https://time.is/london) as the authoritative source for the current time.

When working within XanadOS or related Linux environments, use commands appropriate to your OS and task. Below are common, recommended commands grouped by purpose.

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

### Debugging & Monitoring

- List running services:
  ```sh
  systemctl list-units --type=service
  ```
- View recent logs:
  ```sh
  journalctl -xe
  ```
- Monitor resource usage:
  ```sh
  top
  htop
  ```

### Shortcuts & Aliases

- Add useful aliases to your shell (e.g., in `.bashrc` or `.zshrc`):
  ```sh
  alias ll='ls -alF'
  alias gs='git status'
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

**Q: What do I do if a log file cannot be written?**  
A: Check permissions on `/xanados/var/logs/codex` and retry. Escalate via Codex-FixIt if persistent.

**Q: How do I resolve a conflict between agents?**  
A: Follow the steps in [Conflict Avoidance Policy](#conflict-avoidance-policy) and log the resolution.

[⬆️ Back to Top](#agents-refined)

---

## Guardrails

- Domains must be minimal and well-defined
- All agents require CI integration ([ci.yml](.github/workflows/ci.yml))
- All *manual* or *policy* additions must update this document
- All agent- or automation-driven changes must generate a log report in `var/logs/codex/`.  
- Agents must respect scope and logging conventions
- Violations must be logged and resolved per [Conflict Avoidance Policy](#conflict-avoidance-policy)

[⬆️ Back to Top](#agents-refined)
