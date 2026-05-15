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

## 2025-08-05 - Git Option Injection in Shell Scripts

**Vulnerability:** Constructing `git` commands with untrusted branch names (e.g., `git push origin --delete "$branch"`) is vulnerable to option injection. An attacker could create a branch with a name starting with a dash (e.g., `-f`). Even when the variable is quoted, some Git commands may interpret this as an option (`--force`) instead of a branch name. This can cause the command to fail or behave in unexpected ways, such as applying the option to other arguments in the command.
**Learning:** Even if the variable is double-quoted, command-line utilities will interpret strings starting with `-` as options.
**Prevention:** Always use the `--` double-dash operator to separate options from positional arguments (e.g., `git log -1 --format=%ct -- "origin/$branch"`). For `git push`, use explicit refspecs to prevent ambiguous parsing (e.g., `git push origin --delete "refs/heads/$branch"`).

## 2025-08-06 - Path Traversal Prevention in R

**Vulnerability:** A user-supplied directory path (`data_dir`) was normalized and checked for existence, but not constrained to the current working directory, allowing path traversal (e.g., `../../../etc`).
**Learning:** `normalizePath` resolves `../` segments, but does not inherently enforce a sandbox boundary.
**Prevention:** Always compare the normalized target directory against the normalized working directory. To prevent directory prefix bypass (e.g., matching `/workspace_secrets` when the root is `/workspace`), ensure a trailing slash is appended to both paths before using `startsWith()`.

## 2025-08-07 - Out-Of-Memory (OOM) / Denial of Service (DoS) Risk with File Reads

**Vulnerability:** A file scanning utility (`read_file_safe`) used `f.readlines()` to load the entire contents of a user-supplied file into memory without any size constraints.
**Learning:** Loading unbounded file contents into memory creates a trivial vector for Denial of Service (DoS) attacks via memory exhaustion (OOM), even if path traversal is prevented. This is especially risky in automation tools like code scanners that blindly iterate over files.
**Prevention:** Always check `os.path.getsize(filepath)` against a safe maximum threshold (e.g., `MAX_FILE_SIZE = 10 * 1024 * 1024` for 10MB) before opening and reading a file into memory.

## 2025-08-08 - Generic Exception Handling Data Leakage

**Vulnerability:** Generic exception handlers (`except Exception as e:`) that print or log the raw exception object (`e`) can unintentionally leak sensitive internal application paths, state, or database queries depending on the underlying error.
**Learning:** While swallowing exceptions completely hinders debugging, logging the full exception string to stdout/stderr or an insecure log sink is an information disclosure risk.
**Prevention:** Fail securely by logging a generic user-facing message, but include the exception type (e.g., `type(e).__name__`) to preserve debuggability without exposing sensitive string contents.

## 2025-08-09 - Out-Of-Memory (OOM) Risk with Pandas Excel Parsing

**Vulnerability:** A data analysis script (`outlier_analysis_series27.py`) used `pd.read_excel()` to load user-supplied Excel files without first checking the file size.
**Learning:** Loading arbitrarily large Excel files into memory using Pandas can cause severe memory exhaustion, leading to Denial of Service (DoS) attacks or unpredictable application crashes.
**Prevention:** Always check `os.path.getsize(filepath)` against a safe maximum threshold (e.g., `MAX_FILE_SIZE = 50 * 1024 * 1024` for 50MB) before parsing files with `pandas`.

## 2025-08-10 - Time-of-Check to Time-of-Use (TOCTOU) Vulnerability in File Reading
**Vulnerability:** A code scanning script used `os.path.getsize(filepath)` to check if a file was under a maximum size limit before opening and reading it with `open()` and `f.readlines()`.
**Learning:** Checking a file's size and then opening it creates a race condition known as Time-of-Check to Time-of-Use (TOCTOU). An attacker could swap the file for a much larger one between the size check and the read operation, leading to a Denial of Service via memory exhaustion.
**Prevention:** Avoid separate check and use steps when dealing with files. Instead, open the file and read up to `MAX_FILE_SIZE + 1` bytes. If the length of the read content exceeds `MAX_FILE_SIZE`, you know the file is too large and can reject it safely without TOCTOU risks.

## 2025-08-11 - CLI Option Injection via printf format strings

**Vulnerability:** When using `printf` to output environment variables that contain untrusted text (like user-supplied GitHub Issue titles or AI-generated output), the content can be mistakenly parsed as an option flag if the string starts with a hyphen (e.g. `printf "%s\n" "$VAR"`).
**Learning:** `printf` commands that output variable content can be vulnerable to option injection even when properly quoted, which could cause build failures or unintended behavior in shell scripts.
**Prevention:** Always use the `--` separator with `printf` when formatting variables to ensure everything that follows is treated as the format string or positional arguments, preventing option injection (e.g., `printf -- "%s\n" "$VAR" > output.txt`).

## 2025-08-11 - Information Leakage via exc_info in Generic Exception Handlers

**Vulnerability:** Using `exc_info=True` in generic exception handlers (`except Exception as exc:`) logs the full stack trace and exception details, which can unintentionally leak sensitive internal application paths, state, environment variables, or database queries depending on the underlying error.
**Learning:** While `exc_info=True` aids debugging, its use in high-level generic exception blocks constitutes an information disclosure risk, particularly when logs are accessible to less privileged users or centralized logging systems.
**Prevention:** Avoid `exc_info=True` in broad exception handlers. Fail securely by logging a generic user-facing message, and include only the exception type (e.g., `type(exc).__name__`) to preserve debuggability without exposing sensitive string contents or stack traces.

## 2025-08-12 - Dependency Credential Exfiltration Risk in Automated Shell Environments

**Vulnerability:** When executing external or third-party CLI tools (e.g., linters, formatters, test runners) via `subprocess` in automated pipelines, the default behavior of passing the entire current environment `os.environ` can inadvertently expose sensitive credentials, such as `GH_TOKEN`, to potentially compromised third-party dependencies executing in the shell.
**Learning:** The principle of least privilege should be enforced not only for the application code but also for the environment variables passed to any invoked sub-processes. Third-party tools do not need access to the repository's GitHub token unless explicitly required for their function.
**Prevention:** Always explicitly strip sensitive environment variables (e.g., `env.pop("GH_TOKEN", None)`) from the environment dictionary before passing it to `subprocess.run` or `subprocess.Popen` when invoking third-party CLI tools.
## 2024-05-14 - Fix Path Traversal in Excel Parser
**Vulnerability:** Path traversal in `apply_corrections` due to insufficient sanitization of Excel sheet names (`str.replace("/", "_")`).
**Learning:** Blacklisting path separators (`/`, `\`) is insufficient. Attackers can leverage other characters, encodings, or use `..` relative path tricks depending on how `os.path.join` resolves.
**Prevention:** Use an aggressive allowlist regex (`[^A-Za-z0-9_ \-\.]`) for filenames, strip leading dots/dashes, and always verify the final resolved path stays within the base directory using `os.path.commonpath([base, target]) == base`.
