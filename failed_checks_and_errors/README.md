# Failed Checks and Errors

This directory collects lists of CI failures and script errors.
See **errors1.md** for the initial error report.
Use **Checklist.md** to track each issue as it gets fixed.
When an issue has been fixed, remove it from **Checklist.md**
If a new issue is found in **errors1.md** and not in **Checklist.md**, add it to **Checklist.md**

## Capturing Errors from `/logs/`

1. Inspect the build and workflow logs saved in the `/logs/` directory.
2. Copy any relevant error lines and append them to `errors1.md` so that the failure can be tracked.
   Example:

   ```bash
   tail -n 20 /logs/iso-build.log >> failed_checks_and_errors/errors1.md
   ```

3. Update the `_Last updated:` line at the top of `errors1.md` with the current UTC timestamp.

Codex or CI scripts should automatically update `errors1.md` whenever a workflow fails.
Each entry must include the timestamp, workflow name and commit hash so that issues
can be traced back to a specific run.
