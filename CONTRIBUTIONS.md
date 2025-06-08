# Contributing to XanadOS

Thank you for your interest in improving XanadOS! This guide will help you get started as a contributor. Please read it carefully to ensure a smooth collaboration.

---

## Getting Started

- **Read the [README.md](README.md) and [AGENTS.md](AGENTS.md)** for project structure, agent policies, and build instructions.
- **Clone the repository** and set up your build environment as described in the README.

---

## How to Contribute

1. **Fork the repository** and create a new branch for your feature or fix.
2. **Before making changes:**
   - Pull the latest changes from the main repository.
   - For agent-driven or automated changes, follow the [AGENTS.md](AGENTS.md) policies and log reports in `var/logs/codex/`.
   - For manual or policy changes, update relevant documentation and the Task Ownership Matrix.
3. **Write clear, concise commits** with descriptive messages.
4. **Run tests and lint checks**:
   - Run `bats var/tests` for shell unit tests.
   - Run `shellcheck` on all modified shell scripts.
   - Ensure CI passes with your changes.
5. **Open a Pull Request**:
   - Fill out the PR template.
   - Tag appropriate maintainers and reference related issues.
   - Ensure your PR does not introduce merge conflicts.

---

## Code Style

- **Shell scripts**: Use `bash` strict mode, check with `shellcheck`.
- **Markdown docs**: Pass `markdownlint`.
- **Logging**: All agent-driven or automated changes must generate logs in `var/logs/codex/`.

---

## Checklist Before PR Submission

- [ ] PR submitted and reviewed.
- [ ] Repository re-downloaded and checked for conflicts before PR creation.
- [ ] CI passes (green).
- [ ] Documentation updated (for manual/policy changes).
- [ ] Logging implemented (all changes).
- [ ] Changelog entry added (if changelog is reinstated).

---

## Reporting Bugs & Requesting Features

- Use [GitHub Issues](https://github.com/asafelobotomy/xanados/issues) for bugs and feature requests.
- For runtime troubleshooting, see the `var/bugs/` directory.

---

## Community

- For help or discussion, use [GitHub Discussions](https://github.com/asafelobotomy/xanados/discussions) (if enabled) or open an issue.

---

Thank you for contributing!
