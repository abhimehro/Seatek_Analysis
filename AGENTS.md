# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview
Seatek Analysis is an R-based data analysis pipeline for processing Seatek sensor data. See `README.md` for full details.

### Services
| Service | Purpose | How to run |
|---------|---------|------------|
| R analysis script | Core data processing | `Rscript Updated_Seatek_Analysis.R` |
| Python outlier analysis | Series 27 outlier detection (optional) | `source Series_27/Analysis/venv/bin/activate && python Series_27/Analysis/outlier_analysis_series27.py` |

### Key Commands
- **Lint:** `Rscript -e "library(lintr); lint_dir('.', exclusions = list('renv/', 'backups/', 'Series_27/Analysis/venv/', 'implementation/'))"`
- **Tests:** `Rscript -e "library(testthat); source('Updated_Seatek_Analysis.R'); test_dir('tests/testthat', reporter = 'summary')"`
- **Run analysis:** `Rscript Updated_Seatek_Analysis.R`

### Non-obvious Caveats
- R 4.3.3 is required (matches `renv.lock`). Ubuntu Noble's `r-base` package provides this version.
- System libraries `libgit2-dev`, `pandoc`, `libcurl4-openssl-dev`, `libxml2-dev`, `libssl-dev`, `libfontconfig1-dev`, `libharfbuzz-dev`, `libfribidi-dev` must be installed before `renv::restore()` succeeds.
- `renv::restore()` installs packages from the lockfile. Additional packages for linting/testing (`testthat`, `lintr`, `logger`, etc.) must be installed separately if not fully captured in `renv.lock`.
- The `lintr` `object_usage_linter` warnings for `Timestamp` and `..sensor_names` in `Updated_Seatek_Analysis.R` are known false positives caused by `data.table` non-standard evaluation.
- When running in CI (e.g., GitHub Actions) with manual `install.packages()`, set `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` to prevent renv from interfering.
- Some existing tests have pre-existing failures due to mismatched error message patterns; these are not environment issues.
- The Python venv at `Series_27/Analysis/venv/` is for the optional Series 27 outlier analysis script only.
