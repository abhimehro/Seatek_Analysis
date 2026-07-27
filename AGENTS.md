# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

Seatek Analysis is an R-based data analysis pipeline for processing Seatek sensor data. See `README.md` for full details.

### Services

| Service                 | Purpose                                | How to run                                                                                              |
| ----------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| R analysis script       | Core data processing                   | `Rscript Updated_Seatek_Analysis.R`                                                                     |
| Python outlier analysis | Series 27 outlier detection (optional) | Recreate local venv then `Series_27/Analysis/venv/bin/python Series_27/Analysis/outlier_analysis_series27.py -i <workbook.xlsx>` |

### Key Commands

- **Lint:** `Rscript -e "library(lintr); lint_dir('.', exclusions = list('renv/', 'backups/', 'Series_27/Analysis/venv/', 'implementation/'))"`
- **Tests:** `Rscript -e "library(testthat); source('Updated_Seatek_Analysis.R'); test_dir('tests/testthat', reporter = 'summary')"`
- **Run analysis:** `Rscript Updated_Seatek_Analysis.R`

### Non-obvious Caveats

- R 4.3.3 is required (matches `renv.lock`). Ubuntu Noble's `r-base` package provides this version.
- System libraries `libgit2-dev`, `pandoc`, `libcurl4-openssl-dev`, `libxml2-dev`, `libssl-dev`, `libfontconfig1-dev`, `libharfbuzz-dev`, `libfribidi-dev`, and `libuv1-dev` must be installed before `renv::restore()` succeeds. `libuv1-dev` in particular is required to build `fs` (and therefore `testthat`/`lintr`); without it those package installs fail with `fatal error: uv.h: No such file or directory`.
- `renv::restore()` installs packages from the lockfile. Additional packages for linting/testing (`testthat`, `lintr`, `logger`, etc.) must be installed separately if not fully captured in `renv.lock`.
- The full lockfile currently tracks **94** packages and is oriented around a **devtools/pkgdown/testthat** graph — it does **not** list top-level analysis packages such as `data.table`, `openxlsx`, `lintr`, `zoo`, or `here`. Prefer a fast Posit-binary bootstrap for agents/CI, and plan a `renv::snapshot()` refresh so the lockfile matches `requirements.R` / real runtime deps. The main analysis script only needs `data.table` and `openxlsx` (plus base-R `parallel`/`tools`); tests need `testthat` + `openxlsx` + `data.table`; lint needs `lintr`. Fast setup: `Rscript -e 'options(repos=c(CRAN="https://packagemanager.posit.co/cran/__linux__/noble/latest")); install.packages(c("data.table","openxlsx","zoo","here","testthat","lintr"), Ncpus=4)'`. Note the project `.Rprofile` auto-activates `renv`, so package installs land in `renv/library/` for this repo.
- Running `Rscript Updated_Seatek_Analysis.R` regenerates committed outputs under `Data/` (`Seatek_Summary*.csv/.xlsx`). Run `git checkout -- Data/` afterward to keep the working tree clean.
- The `lintr` `object_usage_linter` warnings for `Timestamp` and `..sensor_names` in `Updated_Seatek_Analysis.R` are known false positives caused by `data.table` non-standard evaluation.
- When running in CI (e.g., GitHub Actions) with manual `install.packages()`, set `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` to prevent renv from interfering.
- Some existing tests have pre-existing failures due to mismatched error message patterns; these are not environment issues.
- The optional Series 27 Python outlier CLI lives under `Series_27/Analysis/`. Do **not** commit a local `venv/` (gitignored). Create one when needed: `python3 -m venv Series_27/Analysis/venv && Series_27/Analysis/venv/bin/pip install -r Series_27/Analysis/requirements.txt`. Run with an input workbook via `-i`, e.g. `Series_27/Analysis/venv/bin/python Series_27/Analysis/outlier_analysis_series27.py -i Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx -o <output_dir>`.
- Phase0 full-repo snapshots under `backups/` should not be tracked in git; store them as release assets or external archives if retained.