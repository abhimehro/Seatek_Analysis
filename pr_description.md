🎯 **What:**
The test coverage for `write_year_sheet` in `tests/testthat/test-write_year_sheet.R` was enhanced. Previously, tests primarily verified that a worksheet was added and the raw data was correctly dumped using temporary files. The tests lacked assertions on workbook-level properties, such as style applications and layout configurations like freeze panes.

📊 **Coverage:**
- **Freeze Panes:** Assertions were added to interrogate `wb$worksheets[[1]]$freezePane` to ensure that `state="frozen"` and `ySplit="1"` are correctly set on the year sheet.
- **Dynamic Cell Styling:** Logic was introduced to parse `wb$styleObjects` and verify that the `highlight_style_yearly` object is applied strictly to the correct row and column (representing the maximum absolute `within_diff` value).

✨ **Result:**
The tests now deterministically validate `openxlsx` workbook object mutations entirely in memory without solely relying on writing out temp files. This increases test robustness and confidence when refactoring presentation logic inside `write_year_sheet`.
