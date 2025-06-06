# High-Level Build Review for `asafelobotomy/xanados`

Last updated: 2025-06-06

---

## Summary

This report covers the most recent build and lint runs for the repository.
It details critical and recurring issues in the CI/CD pipeline,
markdown/documentation and system permissions.
The information is based on the 10 latest failed workflow runs out of a total of
177.
For a full history of results, visit the
[GitHub Actions page][gha-runs].

---

## Major Build & Lint Issues

### 1. **Build Directory Permissions**

**Error Message:**

```text
==> ERROR: You do not have write permission for the directory $BUILDDIR (/__w/xanados/xanados/packages/bats).
Aborting...
Process completed with exit code 11.
```sh

**Implications:**

- The build process is aborted before completion, leading to incomplete builds
  and failed CI checks.
- This error appears in every recent build run, indicating a persistent
  misconfiguration in the workflow environment.

**Root Cause:**

- The runner user does not have write access to the `$BUILDDIR`
  (specifically, `/__w/xanados/xanados/packages/bats`).

**Solution Steps:**

1. **Check Workflow File**: In `.github/workflows/build.yml`, ensure that before
   starting the build, the runner user either owns or has write permission to
   `$BUILDDIR`.
1. **Add a Step to Fix Permissions** (Example for a typical Ubuntu runner):

   ```yaml
   - name: Ensure write access to build directory
     run: sudo chown -R $(whoami) $__w/xanados/xanados/packages/bats
   ```

   Or, for a more generic fix:

   ```yaml
   - name: Fix build directory permissions
     run: sudo chmod -R u+w $__w/xanados/xanados/packages
   ```

1. **Verify Directory Creation**: If the directory does not exist beforehand,
   add a step to create it.

**Potential Future Risks:**

- If permissions are not consistently set across all jobs/steps,
  future contributors may encounter the same error.
- Directory paths hardcoded in workflows may break if the repo or runner setup changes.

---

### 2. **Markdown Lint Errors**

**Summary:**

- All recent runs of the `Markdown Lint` workflow are failing due to multiple
  markdown style violations. Issues include line length, invalid link fragments,
  missing blank lines and improper code block formatting.
- Errors are found in various files, including:
  - `.github/workflows/README.md`
  - `AGENTS.md`
  - `CONTRIBUTING.md`
  - `docs/README.md`
  - `failed_checks_and_errors/Checklist.md`
  - `failed_checks_and_errors/errors1.md`
  - `xanados-iso/docs/suggestions.md`

**Common Error Types & Examples:**

- **Line length exceeded (MD013)**: Lines longer than 80 characters.
- **Invalid link fragments (MD051)**: Incorrect anchor links (e.g., case mismatch).
- **Missing blank lines around headings/lists (MD022/MD032)**.
- **No blank lines around code fences (MD031)**.
- **First line not top-level heading (MD041)**.
- **Multiple consecutive blank lines (MD012)**.

**Solution Steps:**

1. **Automated Fixing**:
   - Use `markdownlint-cli2` auto-fix if possible:

    ```sh
    npx markdownlint-cli2 "**/*.md" --fix
    ```

2. **Manual Fixes**:
   - Review the specific errors in the workflow logs to determine which lines
     and files need attention.
   - Ensure all lines are ≤ 80 characters, except where readability is compromised.
   - Update heading anchors to match expected formats and cases.
   - Surround all headings, lists, and code fences with the required blank lines.
   - Make sure the first line in every markdown file is a top-level heading (`#`).

**Potential Future Risks:**

- New documentation or contributors may introduce violations if no pre-commit
  or CI lint is enforced.
- Inconsistent markdown style can lower documentation quality and accessibility.

---

### 3. **System/Runner Environment Issues**

**Observed Messages:**

- `Skipped: Current root is not booted.`
- `/usr/lib/tmpfiles.d/journal-nocow.conf:26: Failed to resolve specifier:
  uninitialized /etc/ detected, skipping. All rules containing unresolvable
  specifiers will be skipped.`

**Implications:**

- These warnings indicate the runner is in a minimal or containerized
  environment.
  They do not directly cause the build to fail but may hint at deeper system
  configuration issues.

**Solution Steps:**

- **Generally Safe to Ignore** unless your build explicitly requires systemd or
  writes to those parts of the filesystem.
- If you need more complex system services, consider using a VM-based runner or
  a Docker container with additional privileges.

---

## Incomplete Results Notice

- **Only 10 out of 177 failed workflow runs are included here.**
- For a complete picture, review all failures and history in the
  [GitHub Actions UI][gha-runs].

---

## Recommendations

1. **Fix Directory Permissions in CI** immediately to unblock builds.
2. **Enforce Markdown Lint Checks** locally before PRs (add instructions to `CONTRIBUTING.md`).
3. **Automate Lint Fixes** where possible.
4. **Review System Environment** only if your build needs full systemd or
   persistent system-level changes.

---

## Useful Links

- [Latest Failed Build Run][build-run]
- [Latest Failed Markdown Lint Run][lint-run]
- [All Failed Workflow Runs][all-runs]

---

## Appendix: Example Errors

### Permission Error

```sh
==> ERROR: You do not have write permission for the directory $BUILDDIR (/__w/xanados/xanados/packages/bats).
Aborting...
```text

### Markdown Lint Error

```text
AGENTS.md:15:4 MD051/link-fragments Link fragments should be valid
  [Expected: #-pre-task-checks-to-perform; Actual: #-Pre-task-checks-to-perform]
CONTRIBUTING.md:3:81 MD013/line-length Line length [Expected: 80; Actual: 116]
```

---

Prepared by Copilot Build Review

[build-run]: https://github.com/asafelobotomy/xanados/actions/runs/15493406563
[lint-run]: https://github.com/asafelobotomy/xanados/actions/runs/15493241229
[all-runs]: https://github.com/asafelobotomy/xanados/actions
[gha-runs]: https://github.com/asafelobotomy/xanados/actions
