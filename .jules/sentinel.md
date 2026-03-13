## 2025-05-06 - Unsafe R Package Installation
**Vulnerability:** `install.packages()` was called without specifying a secure repository (`repos`), risking MITM attacks and script failures in headless environments.
**Learning:** R scripts often default to insecure or interactive mirrors if not configured, creating a silent security gap.
**Prevention:** Always enforce `repos = "https://cloud.r-project.org"` in `install.packages()` calls within scripts.

## 2025-08-01 - GitHub Actions Command Injection
**Vulnerability:** Untrusted AI-generated output was interpolated directly into a bash command (`gh issue comment $ISSUE_NUMBER --body '${{ steps.inference.outputs.response }}'`) in a GitHub Actions workflow.
**Learning:** Using `${{ ... }}` interpolation within `run` blocks in GitHub Actions can lead to command injection if the content is malicious, as the string is evaluated before the script executes. This applies to user input, issue bodies, and AI outputs.
**Prevention:** Always pass untrusted data to shell scripts via environment variables (e.g., `env:` block mapping to `$VARIABLE_NAME`) rather than direct inline string interpolation.

## 2025-08-02 - GitHub Actions Secret Interpolation
**Vulnerability:** A GitHub secret (`${{ secrets.GITHUB_TOKEN }}`) was interpolated directly into a bash command (`--token "${{ secrets.GITHUB_TOKEN }}"`) in a GitHub Actions workflow (`changelog.yml`).
**Learning:** While secrets are not necessarily user-controlled, direct interpolation of secrets within `run` blocks is a dangerous pattern. If a secret contains shell metacharacters or quotes, it could cause syntax errors or unintended command execution. Furthermore, it normalizes an insecure pattern that might be copied for untrusted inputs.
**Prevention:** Always pass secrets to shell scripts securely by mapping them to environment variables (e.g., using an `env:` block `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}`) and referencing the environment variable (`$GITHUB_TOKEN`) in the script.

## 2025-08-03 - CLI Option Injection via Untrusted Variables
**Vulnerability:** Even when untrusted data (like AI-generated responses) is passed to a shell script securely via an environment variable and double-quoted (`gh issue comment $ISSUE_NUMBER --body "$RESPONSE"`), it remains vulnerable to option injection if the content begins with a dash (`-`). The CLI tool may interpret the string as a command flag rather than a positional argument or value.
**Learning:** Double quoting prevents shell execution and globbing, but does not sanitize the content from the perspective of the application receiving it.
**Prevention:** When passing untrusted multi-line text or potential dashed strings to CLIs, prefer using file-based inputs (e.g., `--body-file response.txt`) generated via `printf "%s\n" "$VAR" > file` over direct variable interpolation. While a `--` separator can prevent option injection for positional arguments, it often doesn't apply to option values, making the file-based approach more broadly secure.

## 2025-08-04 - XML External Entity (XXE) Vulnerability in Excel Parsing
**Vulnerability:** Parsing Excel files using `pandas` and `openpyxl` without `defusedxml` installed can leave the application vulnerable to XML External Entity (XXE) and "Billion Laughs" attacks. Excel `.xlsx` files are essentially zipped XML files. If an attacker uploads a maliciously crafted `.xlsx` file, the XML parser could be tricked into disclosing local files, performing SSRF (Server-Side Request Forgery), or causing a Denial of Service via XML bomb expansion.
**Learning:** `openpyxl` inherently uses standard library XML parsers which are known to be vulnerable to XXE. However, `openpyxl` will opportunistically use the `defusedxml` library if it is available in the environment to mitigate these risks.
**Prevention:** Always ensure `defusedxml` is explicitly included in the `requirements.txt` alongside `openpyxl` to secure XML parsing in Excel files.
