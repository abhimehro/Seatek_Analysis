## 2025-05-06 - Unsafe R Package Installation
**Vulnerability:** `install.packages()` was called without specifying a secure repository (`repos`), risking MITM attacks and script failures in headless environments.
**Learning:** R scripts often default to insecure or interactive mirrors if not configured, creating a silent security gap.
**Prevention:** Always enforce `repos = "https://cloud.r-project.org"` in `install.packages()` calls within scripts.

## 2025-08-01 - GitHub Actions Command Injection
**Vulnerability:** Untrusted AI-generated output was interpolated directly into a bash command (`gh issue comment $ISSUE_NUMBER --body '${{ steps.inference.outputs.response }}'`) in a GitHub Actions workflow.
**Learning:** Using `${{ ... }}` interpolation within `run` blocks in GitHub Actions can lead to command injection if the content is malicious, as the string is evaluated before the script executes. This applies to user input, issue bodies, and AI outputs.
**Prevention:** Always pass untrusted data to shell scripts via environment variables (e.g., `env:` block mapping to `$VARIABLE_NAME`) rather than direct inline string interpolation.
