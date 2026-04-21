## 2024-05-18 - [Title] Prevent GH_TOKEN exfiltration in repository automation shell scripts
**Vulnerability:** Third-party CLI tools (e.g., test runners, linters) executed via `subprocess` within GitHub Actions automation scripts could potentially exfiltrate the highly privileged `GH_TOKEN` environment variable if compromised.
**Learning:** Shell commands executed by `run_shell_command` inherited all environment variables by default via `command_env()`, including secrets needed by the wrapper script but not by the third-party tools themselves.
**Prevention:** Explicitly implement the principle of least privilege by stripping sensitive credentials (like `GH_TOKEN`) from the environment dictionary passed to `subprocess.run` when executing arbitrary shell commands or external tools.
