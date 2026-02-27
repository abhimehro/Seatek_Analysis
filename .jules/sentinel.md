## 2025-05-06 - Unsafe R Package Installation
**Vulnerability:** `install.packages()` was called without specifying a secure repository (`repos`), risking MITM attacks and script failures in headless environments.
**Learning:** R scripts often default to insecure or interactive mirrors if not configured, creating a silent security gap.
**Prevention:** Always enforce `repos = "https://cloud.r-project.org"` in `install.packages()` calls within scripts.
