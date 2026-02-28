## 2025-07-11 - Prevent Command Injection in GitHub Actions
**Vulnerability:** Inline interpolation of untrusted input (`${{ ... }}`) in bash scripts inside GitHub Actions allows command injection.
**Learning:** Even AI-generated output or issue titles/bodies must be treated as untrusted data.
**Prevention:** Pass untrusted inputs via environment variables (`"$VAR"`) rather than direct string interpolation.
