library(testthat)
library(openxlsx)
library(data.table)

# Use the global variables if needed, assuming the testthat.R setup has loaded them.
# The `Updated_Seatek_Analysis.R` contains the `write_year_sheet` function.
# To make it available here reliably, let's also source it.
if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R")
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R")
}

test_that("write_year_sheet works correctly", {
  # Create a new workbook
  wb <- createWorkbook()

  # Create some mock data
  mock_data <- data.table(
    Sensor = c("Sensor01", "Sensor02"),
    first10 = c(10.5, 12.3),
    last5 = c(11.0, 11.5),
    full = c(10.8, 12.0),
    within_diff = c(0.5, -0.8)
  )

  # Create mock styles
  header_style <- createStyle(textDecoration = "Bold", border = "Bottom")
  highlight_style_yearly <- createStyle(fontColour = "#006100", bgFill = "#C6EFCE")

  # Call the function
  year <- "2023"
  write_year_sheet(wb, year, mock_data, header_style, highlight_style_yearly)

  # 1. Check if sheet was added
  expect_true(year %in% names(wb), label = "Sheet should be added to the workbook.")

  # 2. Check if freeze pane is applied correctly
  ws <- wb$worksheets[[1]]
  expect_false(is.null(ws$freezePane), label = "Freeze pane should be applied to the worksheet.")
  expect_match(ws$freezePane, "state=\"frozen\"", label = "Freeze pane state should be frozen.")
  expect_match(ws$freezePane, "ySplit=\"1\"", label = "Freeze pane should split at the first row.")

  # 3. Check if highlight style is applied to the correct cell
  highlight_col <- which(colnames(mock_data) == "within_diff")
  highlight_row <- which.max(abs(mock_data$within_diff)) + 1

  styles <- wb$styleObjects
  has_highlight <- FALSE
  for (s in styles) {
    if (s$sheet == year && length(s$rows) == 1 && s$rows == highlight_row && s$cols == highlight_col) {
      has_highlight <- TRUE
    }
  }
  expect_true(has_highlight, label = "Highlight style should be applied to the maximum absolute within_diff value.")

  # 4. Read data back and verify
  temp_file <- tempfile(fileext = ".xlsx")
  saveWorkbook(wb, temp_file, overwrite = TRUE)

  read_data <- read.xlsx(temp_file, sheet = year)

  # Verify dimensions
  expect_equal(nrow(read_data), nrow(mock_data), label = "Number of rows should match.")
  expect_equal(ncol(read_data), ncol(mock_data), label = "Number of columns should match.")

  # Verify specific values
  expect_equal(read_data$Sensor, mock_data$Sensor, label = "Sensor column should match.")
  expect_equal(read_data$within_diff, mock_data$within_diff, label = "within_diff column should match.")

  # 5. Test without highlight style (should not fail)
  wb2 <- createWorkbook()
  write_year_sheet(wb2, "2024", mock_data, header_style, NULL)
  expect_true("2024" %in% names(wb2), label = "Sheet should be added even without highlight style.")

  # 6. Test without 'within_diff' column (should not fail and shouldn't try to highlight)
  wb3 <- createWorkbook()
  mock_data_no_diff <- mock_data[, -c("within_diff")]
  write_year_sheet(wb3, "2025", mock_data_no_diff, header_style, highlight_style_yearly)
  expect_true("2025" %in% names(wb3), label = "Sheet should be added even without within_diff column.")

  # Cleanup
  if (file.exists(temp_file)) file.remove(temp_file)
})
