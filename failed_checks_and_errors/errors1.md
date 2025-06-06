# Failed Workflows Report

_Last updated: 2025-06-06 19:20 UTC_

This report summarizes the recent workflow failures in the repository, their causes, and proposed resolutions.

---

## 1. Build Workflow Failures

**Workflow:** [Build](https://github.com/asafelobotomy/xanados/actions/runs/15494723405)  
**Branch:** `main`  
**Commit:** `4873d39ab276679ce0ff0fb4e23e1c4bbae73832`

### Main Errors

- `ERROR: Cannot find the debugedit binary required for including source files in debug packages.`
- `ERROR: Cannot find the fakeroot binary.`
- Warnings about "Skipped: Current root is not booted." and "Failed to resolve specifier: uninitialized /etc/ detected, skipping."

### Resolution

- **Install Required Binaries:**  
  Add the following step before running your package builds in the workflow:
  ```yaml
  - name: Install required build tools
    run: pacman -Sy --noconfirm debugedit fakeroot
  ```
- The root and tmpfiles warnings are common in CI containers and can typically be ignored unless they cause builds to fail.

---

## 2. Markdown Lint Workflow Failures

**Workflow:** [Markdown Lint](https://github.com/asafelobotomy/xanados/actions/runs/15494723418)  
**Branch:** `main`  
**Commit:** `4873d39ab276679ce0ff0fb4e23e1c4bbae73832`

### Main Errors

- **MD013/line-length:**  
  Many lines in Markdown files exceed the 80-character limit.
- **MD041/first-line-heading/first-line-h1:**  
  Some Markdown files do not start with a top-level heading.
- **MD034/no-bare-urls:**  
  Bare URLs are used instead of Markdown links.

### Resolution

- **Line Length:**  
  Break long lines at 80 characters (or adjust `.markdownlint.yml` if you want to allow longer lines).
- **First Line Heading:**  
  Ensure all Markdown files begin with a `# Heading`.
- **Bare URLs:**  
  Convert bare URLs to `[text](url)` format.

---

## 3. Additional Build Workflow Failures

**Workflow:** [Build](https://github.com/asafelobotomy/xanados/actions/runs/15494717855)  
**Branch:** `codex/review-build-for-errors`  
**Commit:** `87912ae1552e7d28078b719799886589fd91755d`

- Same errors as above with missing `debugedit` and `fakeroot`.

---

## 4. Additional Markdown Lint Failures

**Workflow:** [Markdown Lint](https://github.com/asafelobotomy/xanados/actions/runs/15494717933)  
**Branch:** `codex/review-build-for-errors`  
**Commit:** `87912ae1552e7d28078b719799886589fd91755d`

- Same style/formatting errors as above.

---

## Quick Summary Table

| Workflow      | Main Error(s)                   | Resolution                                               |
| ------------- | ------------------------------- | -------------------------------------------------------- |
| Build         | Missing `debugedit`, `fakeroot` | Install with `pacman -Sy --noconfirm debugedit fakeroot` |
|               | Container/root warnings         | Typically safe to ignore in CI                           |
| Markdown Lint | Line too long (MD013)           | Break lines at 80 characters or adjust config            |
|               | No top-level heading (MD041)    | Add `# Heading` to start of each file                    |
|               | Bare URLs (MD034)               | Use `[text](url)` links                                  |

---

## References

- [Build workflow failure log (main)](https://github.com/asafelobotomy/xanados/actions/runs/15494723405)
- [Markdown lint failure log (main)](https://github.com/asafelobotomy/xanados/actions/runs/15494723418)
- [Build workflow failure log (PR)](https://github.com/asafelobotomy/xanados/actions/runs/15494717855)
- [Markdown lint failure log (PR)](https://github.com/asafelobotomy/xanados/actions/runs/15494717933)

---

**Next Steps:**

1. Update your workflow YAML to ensure all required build tools (`debugedit`, `fakeroot`) are installed before building packages.
2. Refactor Markdown files to comply with lint rules, or update `.markdownlint.yml` if you want to change the policy.
3. Re-run workflows to confirm all issues are resolved.
