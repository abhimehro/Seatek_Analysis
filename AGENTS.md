# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

Seatek Analysis is an R-based data analysis pipeline for processing Seatek
sensor data. See `README.md` for full details.

### Services

| Service                 | Purpose                                | How to run                                                                                              |
| ----------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| R analysis script       | Core data processing                   | `Rscript Updated_Seatek_Analysis.R`                                                                     |
| Python outlier analysis | Series 27 outlier detection (optional) | `source Series_27/Analysis/venv/bin/activate && python Series_27/Analysis/outlier_analysis_series27.py` |

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
- `Seatek_Analysis_project_code.txt` concatenates repository code for external
  review or LLM context. It is untracked and ignored, safe to delete locally,
  and regenerable from the source tree; neither the application nor CI reads it.
- The `lintr` `object_usage_linter` warnings for `Timestamp` and
  `..sensor_names` in `Updated_Seatek_Analysis.R` are known false positives
  caused by `data.table` non-standard evaluation.
- When running in CI (e.g., GitHub Actions) with manual `install.packages()`,
  set `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` to prevent renv from interfering.
- Some existing tests have pre-existing failures due to mismatched error message
  patterns; these are not environment issues.
- The Python venv at `Series_27/Analysis/venv/` is for the optional Series 27
  outlier analysis script only. It requires **Python 3.11 or 3.12** (the pinned
  `numpy==1.26.0` only ships wheels for those versions); recreate it with a
  3.11/3.12 interpreter if necessary:
  `rm -rf Series_27/Analysis/venv && python3.11 -m venv Series_27/Analysis/venv && Series_27/Analysis/venv/bin/pip install -r Series_27/Analysis/requirements.txt`.
  Recreating overwrites tracked files, so
  `git checkout -- Series_27/Analysis/venv` afterward to keep the tree clean.
  The script requires an input workbook via `-i`, e.g.
  `Series_27/Analysis/venv/bin/python Series_27/Analysis/outlier_analysis_series27.py -i Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx -o <output_dir>`.

<!-- gitnexus:start -->

# GitNexus — Code Intelligence

This project is indexed by GitNexus as **Seatek_Analysis** (442 symbols, 501
relationships, 3 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the
> project root — it auto-selects an available runner. No `.gitnexus/run.cjs`
> yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g.
> `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact analysis before editing.** Use
  `impact({target: "symbolName", direction: "upstream"})` (MCP) or
  `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .`
  (CLI fallback); report callers, processes, and risk. Never substitute grep for
  graph analysis.
- **MUST analyze graph changes before committing.** Use
  `detect_changes({scope: "all"})` (MCP) or
  `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback).
  `partial: true` or `truncated: true` is not a clean check — a zero means
  unseen, not unaffected; re-run it. For regression review:
  `detect_changes({scope: "compare", base_ref: "main"})` or
  `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before
  proceeding with edits.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set
  is not evidence the symbol is unused — it can also mean the callers are not
  resolvable by the index (plain-object property access, dynamic dispatch,
  cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so.
  Confirm with a text search before treating the symbol as safe to change or
  delete; do not proceed on the strength of a zero.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find
  execution flows instead of grepping. It returns process-grouped results ranked
  by relevance.
- When you need full context on a specific symbol — callers, callees, which
  execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings
  (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never
  read `UNKNOWN` as an all-clear — it means the walk could not answer, which is
  the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands
  the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource                                         | Use for                                  |
| ------------------------------------------------ | ---------------------------------------- |
| `gitnexus://repo/Seatek_Analysis/context`        | Codebase overview, check index freshness |
| `gitnexus://repo/Seatek_Analysis/clusters`       | All functional areas                     |
| `gitnexus://repo/Seatek_Analysis/processes`      | All execution flows                      |
| `gitnexus://repo/Seatek_Analysis/process/{name}` | Step-by-step execution trace             |

## CLI

| Task                                         | Read this skill file                               |
| -------------------------------------------- | -------------------------------------------------- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md`       |
| Blast radius / "What breaks if I change X?"  | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?"             | `.claude/skills/gitnexus-debugging/SKILL.md`       |
| Rename / extract / split / refactor          | `.claude/skills/gitnexus-refactoring/SKILL.md`     |
| Tools, resources, schema reference           | `.claude/skills/gitnexus-guide/SKILL.md`           |
| Index, status, clean, wiki CLI commands      | `.claude/skills/gitnexus-cli/SKILL.md`             |
| Work in the Analysis area (24 symbols)       | `.claude/skills/gitnexus-area-analysis/SKILL.md`   |
| Work in the Tests area (22 symbols)          | `.claude/skills/gitnexus-area-tests/SKILL.md`      |

<!-- gitnexus:end -->
