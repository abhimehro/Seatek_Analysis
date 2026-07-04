## 2024-07-04 - Renv Testing in Sandbox
**Learning:** Running R scripts/tests inside a sandbox using `renv` might restrict library access.
**Action:** Always bypass sandbox using `export RENV_CONFIG_SANDBOX_ENABLED=FALSE` before running `testthat` or other R script tests.
