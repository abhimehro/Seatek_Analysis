---
name: testing-s27-outlier-cli
description: Test the Series 27 outlier analysis CLI (Series_27/Analysis/outlier_analysis_series27.py) end-to-end, including its path-traversal / base-directory validation. Use when verifying changes to that script.
---

# Testing the Series 27 outlier analysis CLI

The app under test is a Python CLI: `Series_27/Analysis/outlier_analysis_series27.py`.
It reads an Excel workbook (`-i`), detects outliers, and writes corrected files + a
`corrections_summary.xlsx` and `outliers_plot.png` into an output dir (`-o`).

## Environment setup (important gotchas)
- The committed venv at `Series_27/Analysis/venv` may be broken on fresh VMs (its
  interpreter symlinks can point at the original author's macOS pyenv path). Do NOT
  rely on it.
- `Series_27/Analysis/requirements.txt` may pin an unreleased pandas (e.g.
  `pandas>=3.0.3`) that pip cannot install on the VM's Python (3.10). If so, create a
  throwaway venv OUTSIDE the repo tree so you don't churn the tracked venv, and install
  a compatible stack:
  ```bash
  python3 -m venv ~/s27_test_venv
  ~/s27_test_venv/bin/pip install "pandas<3" numpy matplotlib openpyxl defusedxml
  ```
  Using an external venv avoids the `git checkout -- Series_27/Analysis/venv` cleanup
  dance entirely. If you must recreate the in-repo venv, restore it afterward with
  `git checkout -- Series_27/Analysis/venv` and only stage the real source files.
- Sample workbook to test against: `Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx`.

## Running / demonstrating
Run from the repo root so cwd is the default `--base-dir`. Because it's a CLI, demo it
in a GUI terminal (konsole is available) and record — not shell-only.

Legitimate run (should succeed):
```bash
~/s27_test_venv/bin/python Series_27/Analysis/outlier_analysis_series27.py \
  -i Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx -o s27_demo_out
```
Expect: "Detected N outliers", and `s27_demo_out/corrections_summary.xlsx` +
`s27_demo_out/outliers_plot.png` created.

## Path-traversal / base-dir validation (the security behavior)
`main()` validates `--input` and `--output` against `--base-dir` (default cwd) using
pathlib `is_relative_to`. To prove the guard works, a broken implementation would look
visibly different (it would read the file / create the dir):
- Out-of-base input is rejected: `-i /etc/hostname` → logs
  `ERROR: Input path '...' is outside the allowed base directory '...'. Refusing to proceed.`
  and does NOT process.
- Out-of-base output is rejected: `-o /tmp/<name>` (when cwd is the repo) → same style
  error, and the dir is NOT created (verify with `ls`).

## Unit tests
```bash
~/s27_test_venv/bin/python -m pytest Series_27/Analysis/test_outlier_analysis_series27.py -v
```
Some tests skip if pandas isn't importable — that's why installing a working pandas
matters. Covers `detect_outliers`, `secure_filename`, `_resolve_within_base`,
`_is_safe_path`, and `apply_corrections` traversal defense.

## Cleanup
Remove any `s27_demo_out/` you created (it's untracked). Leave the tracked venv alone.

## Devin Secrets Needed
None. No credentials or logins are required to test this CLI.
