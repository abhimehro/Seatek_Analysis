🧪 [testing improvement description]

🎯 **What:** The testing gap addressed
The `write_year_sheet` function in `Updated_Seatek_Analysis.R` was previously untested. This function is responsible for writing a single year's data to a specific sheet in an `openxlsx` workbook, applying header styles, freezing panes, and conditionally highlighting the row with the largest `within_diff` value. The lack of tests meant that regressions in formatting or data writing could go unnoticed.

📊 **Coverage:** What scenarios are now tested
Added a comprehensive test suite in `tests/testthat/test-write_year_sheet.R` covering:
- Correct creation of a new sheet in the workbook with the specified year name.
- Accurate writing of all data rows and columns, verified by reading the data back from a temporary Excel file.
- The correct application of the conditional highlight style for the row with the maximum absolute `within_diff` value by inspecting the `wb$styleObjects`.
- Edge cases where the highlight style is provided as `NULL`.
- Edge cases where the `within_diff` column is absent from the dataset (ensuring no errors occur).

✨ **Result:** The improvement in test coverage
The test coverage has significantly improved by formally validating the behavior of the `write_year_sheet` function. This ensures that the generated Excel reports remain correctly formatted and that the data is accurately transferred, allowing for more confident refactoring in the future.
