library(testthat)
library(openxlsx)
library(data.table)

# Use the global variables if needed, assuming the testthat.R setup has loaded them.
# The `Updated_Seatek_Analysis.R` contains the `write_year_sheet` function.
env <- globalenv()

if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R", local=env)
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R", local=env)
} else {
  stop("Main analysis script not found.")
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

  # 2. Read data back and verify
  temp_file <- tempfile(fileext = ".xlsx")
  saveWorkbook(wb, temp_file, overwrite = TRUE)

  read_data <- read.xlsx(temp_file, sheet = year)

  # Verify dimensions
  expect_equal(nrow(read_data), nrow(mock_data), label = "Number of rows should match.")
  expect_equal(ncol(read_data), ncol(mock_data), label = "Number of columns should match.")

  # Verify specific values
  expect_equal(read_data$Sensor, mock_data$Sensor, label = "Sensor column should match.")
  expect_equal(read_data$within_diff, mock_data$within_diff, label = "within_diff column should match.")

  # Check that the highlight style was applied correctly
  # Find the style object for the highlight
  # We know the first style object is the header (cols 1:5, row 1)
  # The second style object should be the highlight
  style_objs <- wb$styleObjects
  expect_gt(length(style_objs), 0, label = "Style objects should exist.")

  # Check if any style matches our expected row/col for highlight
  # max_idx is 2 (Sensor02 with -0.8), row offset is +1 for header, so row 3
  # col for within_diff is 5
  found_highlight <- FALSE
  for (obj in style_objs) {
    if (obj$sheet == year && 3 %in% obj$rows && 5 %in% obj$cols) {
       found_highlight <- TRUE
       break
    }
  }
  expect_true(found_highlight, label = "Highlight style should be applied to correct cell (row 3, col 5).")

  # 3. Test without highlight style (should not fail)
  wb2 <- createWorkbook()
  write_year_sheet(wb2, "2024", mock_data, header_style, NULL)
  expect_true("2024" %in% names(wb2), label = "Sheet should be added even without highlight style.")

  # 4. Test without 'within_diff' column (should not fail and shouldn't try to highlight)
  wb3 <- createWorkbook()
  mock_data_no_diff <- mock_data[, -c("within_diff")]
  write_year_sheet(wb3, "2025", mock_data_no_diff, header_style, highlight_style_yearly)
  expect_true("2025" %in% names(wb3), label = "Sheet should be added even without within_diff column.")

  # Cleanup
  if (file.exists(temp_file)) file.remove(temp_file)
})
