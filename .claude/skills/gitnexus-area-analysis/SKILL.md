---
name: gitnexus-area-analysis
description: "Skill for the Analysis area of Seatek_Analysis. 24 symbols across 2 files."
---

# Analysis

24 symbols | 2 files | Cohesion: 87%

## When to Use

- Working with code in `Series_27/`
- Understanding how detect_outliers, test_detect_outliers_abs_mock,
  test_detect_outliers_abs_real work
- Modifying analysis-related functionality

## Key Files

| File                                                   | Symbols                                                                                                                                                              |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Series_27/Analysis/outlier_analysis_series27.py`      | detect_outliers, _apply_corrections_to_sheets, _get_safe_output_path, _is_safe_path, _process_single_sheet (+10)                                                     |
| `Series_27/Analysis/test_outlier_analysis_series27.py` | test_detect_outliers_abs_mock, test_detect_outliers_abs_real, test_detect_outliers_invalid_method, test_detect_outliers_iqr_mock, test_detect_outliers_iqr_real (+4) |

## Entry Points

Start here when exploring this area:

- **`detect_outliers`** (Function) —
  `Series_27/Analysis/outlier_analysis_series27.py:94`
- **`test_detect_outliers_abs_mock`** (Function) —
  `Series_27/Analysis/test_outlier_analysis_series27.py:81`
- **`test_detect_outliers_abs_real`** (Function) —
  `Series_27/Analysis/test_outlier_analysis_series27.py:36`
- **`test_detect_outliers_invalid_method`** (Function) —
  `Series_27/Analysis/test_outlier_analysis_series27.py:71`
- **`test_detect_outliers_iqr_mock`** (Function) —
  `Series_27/Analysis/test_outlier_analysis_series27.py:128`

## Key Symbols

| Symbol                                  | Type     | File                                                   | Line |
| --------------------------------------- | -------- | ------------------------------------------------------ | ---- |
| `detect_outliers`                       | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 94   |
| `test_detect_outliers_abs_mock`         | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 81   |
| `test_detect_outliers_abs_real`         | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 36   |
| `test_detect_outliers_invalid_method`   | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 71   |
| `test_detect_outliers_iqr_mock`         | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 128  |
| `test_detect_outliers_iqr_real`         | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 61   |
| `test_detect_outliers_zscore_mock`      | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 102  |
| `test_detect_outliers_zscore_real`      | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 47   |
| `secure_filename`                       | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 76   |
| `test_secure_filename`                  | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 161  |
| `main`                                  | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 371  |
| `parse_args`                            | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 14   |
| `plot_outliers`                         | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 313  |
| `prepare_outliers_df`                   | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 126  |
| `apply_corrections`                     | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 289  |
| `test_apply_corrections_path_traversal` | Function | `Series_27/Analysis/test_outlier_analysis_series27.py` | 175  |
| `_apply_corrections_to_sheets`          | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 239  |
| `_get_safe_output_path`                 | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 181  |
| `_is_safe_path`                         | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 159  |
| `_process_single_sheet`                 | Function | `Series_27/Analysis/outlier_analysis_series27.py`      | 197  |

## Execution Flows

| Flow                                          | Type            | Steps |
| --------------------------------------------- | --------------- | ----- |
| `Apply_corrections → _is_safe_path`           | cross_community | 6     |
| `Apply_corrections → Secure_filename`         | cross_community | 6     |
| `Apply_corrections → _bulk_read_excel_sheets` | intra_community | 3     |

## How to Explore

1. `context({name: "detect_outliers"})` — see callers and callees
2. `query({search_query: "analysis"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings
   (source→sink data flows), when indexed with `--pdg`
