🎯 **What:** The testing gap for the `write_year_sheet` function inside `Updated_Seatek_Analysis.R` has been addressed. The function was completely missing dedicated test coverage.

📊 **Coverage:** The new tests in `tests/testthat/test-write_year_sheet.R` cover:
- Correct insertion of a newly created sheet into the workbook instance.
- Matching dimensions (row/column counts) of inserted mocked `data.table` against retrieved Excel sheet.
- Exact content match of specific vectors between the provided mock and parsed outputs.
- Resilience checks ensuring functionality without error when specific formatting styles (e.g. `highlight_style_yearly=NULL`) are omitted.
- Resilience checks ensuring functionality without error when the `within_diff` column itself is omitted from the parsed subset.

✨ **Result:** A significant improvement in test coverage has been achieved, ensuring robust, deterministic regressions tracking moving forward, verifying `data.table` native compatibility mapping to `openxlsx` outputs without breaking functionality. All 64 tests in the R suite have successfully passed.
