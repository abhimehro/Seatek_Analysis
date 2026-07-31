---
name: testing-s27-outlier-cli
description: Test the Series 27 outlier analysis CLI (Series_27/Analysis/outlier_analysis_series27.py) end-to-end, including its output-path validation. Use when verifying changes to that script.
---

# Testing the Series 27 outlier analysis CLI

The app under test is a Python CLI:
`Series_27/Analysis/outlier_analysis_series27.py`. It reads an Excel workbook
(`-i`), detects outliers, and writes per-sheet corrected workbooks,
`corrections_summary.xlsx`, and `outliers_plot.png` into an output dir (`-o`).

## Environment setup

- Do NOT use the committed `Series_27/Analysis/venv`; it may be broken.
- Create a fresh Python 3.11+ venv.
- Install from the dependency manifests (the second install also provides
  `pytest`, `ruff`, etc.):
  ```bash
  python3.11 -m venv ~/s27_test_venv
  ~/s27_test_venv/bin/python -m pip install -r Series_27/Analysis/requirements.txt
  ~/s27_test_venv/bin/python -m pip install -r requirements-dev.txt
  ```
- Sample workbook: `Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx`.

## Running / demonstrating

Run from the repo root and record the terminal session.

Legitimate run:

```bash
~/s27_test_venv/bin/python Series_27/Analysis/outlier_analysis_series27.py \
  -i Series_27/Analysis/Seatek_Comprehensive_Analysis.xlsx -o s27_demo_out
```

Expect: "Detected N outliers", and `s27_demo_out/corrections_summary.xlsx`,
`s27_demo_out/outliers_plot.png`, plus per-sheet `corrected_*.xlsx` files
created.

## Output-path validation

`outlier_analysis_series27.py` uses `_is_safe_path` to ensure generated
corrected-file paths stay inside the output directory. It does not currently
implement a top-level `--base-dir` / `is_relative_to` check on `--input` or
`--output` in `main()`, so do not fail the test if `-i /etc/hostname` is
rejected for a different reason.

## Unit tests

```bash
~/s27_test_venv/bin/python -m pytest Series_27/Analysis/test_outlier_analysis_series27.py -v
```

Some tests skip if pandas isn't importable. There is a known pre-existing
failure in `test_apply_corrections_path_traversal` due to a fixture/mock issue;
that failure is not a dependency-pinning regression. The remaining tests should
pass.

## Cleanup

Remove any `s27_demo_out/` you created. Leave the tracked venv alone.

## Devin Secrets Needed

None. No credentials or logins are required to test this CLI.
