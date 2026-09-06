## 2025-05-06 - CI GitHub Action Failure
**Learning:** If the `github-advanced-security` check run fails with the error `Model "gpt-5.3-codex" is not available` or similar during `session.create`, this indicates an upstream infrastructure issue with GitHub's Copilot Autofix or agentic backend, rather than a bug in the repository's codebase. The failure can be safely ignored as long as all other local and CI tests pass.
**Action:** Ignore this CI error since it's an infrastructure failure.
