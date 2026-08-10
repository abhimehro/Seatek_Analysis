# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

Seatek Analysis is an R-based data analysis pipeline for processing Seatek
sensor data. See `README.md` for full details.

### Services

| Service                 | Purpose                                | How to run                                                                                              |
| ----------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| R analysis script       | Core data processing                   | `Rscript Updated_Seatek_Analysis.R`                                                                     |
| Python outlier analysis | Series 27 outlier detection (optional) | `Series_27/Analysis/venv/bin/python Series_27/Analysis/outlier_analysis_series27.py -i <workbook.xlsx> -o <out_dir>` |

### Key Commands

- **Lint:**
  `Rscript -e "library(lintr); lint_dir('.', exclusions = list('renv/', 'backups/', 'Series_27/Analysis/venv/', 'implementation/'))"`
- **Tests:**
  `Rscript -e "renv::restore(); library(testthat); source('Updated_Seatek_Analysis.R', local = TRUE); testthat::test_dir('tests/testthat', reporter = 'summary')"`
- **Run analysis:** `Rscript Updated_Seatek_Analysis.R`

### Non-obvious Caveats

- R 4.3.3 is required (matches `renv.lock`). The `.devin/blueprint.yaml`
  installs it from Posit's r-builds CDN for Ubuntu 22.04 (jammy) under
  `/opt/R/4.3.3` and symlinks `R`/`Rscript` into `/usr/local/bin`.
- System libraries `libgit2-dev`, `pandoc`, `libcurl4-openssl-dev`,
  `libxml2-dev`, `libssl-dev`, `libfontconfig1-dev`, `libharfbuzz-dev`,
  `libfribidi-dev`, and `libuv1-dev` must be installed before `renv::restore()`
  succeeds. `libuv1-dev` in particular is required to build `fs` (and therefore
  `testthat`/`lintr`); without it those package installs fail with
  `fatal error: uv.h: No such file or directory`.
- `renv::restore()` installs the exact packages recorded in `renv.lock`. The
  lockfile now contains `data.table`, `openxlsx`, `testthat`, `lintr`, and their
  transitive dependencies.
- The lockfile is intentionally lean (runtime + test + lint).
  `Updated_Seatek_Analysis.R` only needs `data.table` and `openxlsx` (plus
  base-R `parallel`/`tools`); tests need `testthat` + `openxlsx` + `data.table`;
  lint needs `lintr`. For a fast local setup on Linux, use the Posit binary
  mirror:
  `Rscript -e 'options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest")); install.packages(c("data.table", "openxlsx", "testthat", "lintr"), Ncpus = 4)'`.
  The project `.Rprofile` auto-activates `renv`, so package installs land in
  `renv/library/` for this repo.
- Running `Rscript Updated_Seatek_Analysis.R` regenerates outputs under `Data/`
  (`*.xlsx`, `Seatek_Summary*.csv/.xlsx`). These outputs are gitignored;
  regenerate them locally instead of committing.
- The `lintr` `object_usage_linter` warnings for `Timestamp` and
  `..sensor_names` in `Updated_Seatek_Analysis.R` are known false positives
  caused by `data.table` non-standard evaluation.
- When running in CI (e.g., GitHub Actions) with manual `install.packages()`,
  set `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` to prevent renv from interfering.
- The optional Series 27 outlier script uses a **local** Python venv (gitignored;
  do not commit). Prefer Python **3.11 or 3.12** (`numpy==1.26.0` wheels). Example:
  `python3.11 -m venv Series_27/Analysis/venv && Series_27/Analysis/venv/bin/pip install -r Series_27/Analysis/requirements.txt`.
  Run with `-i`, e.g.
  `Series_27/Analysis/venv/bin/python Series_27/Analysis/outlier_analysis_series27.py -i Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx -o <output_dir>`.
