library(testthat)
library(openxlsx)
library(data.table)

env <- globalenv()

if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R", local=env)
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R", local=env)
} else {
  stop("Main analysis script not found.")
}

test_that("export_top_sensors_summary works correctly", {
  # Create a new workbook
  wb <- createWorkbook()

  # Create temp directory and files
  temp_dir <- tempdir()
  output_file <- file.path(temp_dir, "test_summary.xlsx")
  csv_file <- file.path(temp_dir, "test_summary_top_sensors.csv")

  # Ensure the CSV file does not exist before test
  if (file.exists(csv_file)) file.remove(csv_file)

  # Create mock data with 8 sensors (so > 5)
  # The top 5 absolute differences should be Sensors 1, 2, 3, 4, 5
  mock_summary_df <- data.table(
    Sensor = paste0("Sensor0", 1:8),
    within_diff_mean = c(10, -9, 8, -7, 6, -5, 4, -3), # Absolute values: 10, 9, 8, 7, 6, 5, 4, 3
    full_mean = runif(8, 10, 20),
    full_sd = runif(8, 0.5, 3.5),
    full_pct_nonmissing = runif(8, 80, 100),
    other_col = 1:8 # This column should be dropped
  )

  # Create mock styles
  header_style <- createStyle(textDecoration = "Bold", border = "Bottom")

  # Call the function
  suppressMessages({
    export_top_sensors_summary(wb, mock_summary_df, output_file, header_style)
  })

  # 1. Check if sheet was added
  expect_true("Summary_Top_Sensors" %in% names(wb), label = "Summary_Top_Sensors sheet should be added to the workbook.")

  # 2. Check if CSV file was created
  expect_true(file.exists(csv_file), label = "CSV file should be created.")

  # 3. Verify the CSV data
  top_csv <- read.csv(csv_file)

  # Check number of rows
  expect_equal(nrow(top_csv), 5, label = "There should be exactly 5 rows in the top sensors summary.")

  # Check columns
  expected_cols <- c("Sensor", "within_diff_mean", "full_mean", "full_sd", "full_pct_nonmissing")
  expect_equal(colnames(top_csv), expected_cols, label = "The columns in top sensors summary should match expected columns.")

  # Check the ordering (highest absolute diff first)
  expected_sensors <- c("Sensor01", "Sensor02", "Sensor03", "Sensor04", "Sensor05")
  expect_equal(top_csv$Sensor, expected_sensors, label = "Sensors should be ordered by absolute within_diff_mean.")

  # 4. Check behavior when 'within_diff_mean' is missing
  wb2 <- createWorkbook()
  mock_summary_no_diff <- mock_summary_df[, -c("within_diff_mean")]
  output_file2 <- file.path(temp_dir, "test_summary2.xlsx")
  csv_file2 <- file.path(temp_dir, "test_summary2_top_sensors.csv")

  if (file.exists(csv_file2)) file.remove(csv_file2)

  suppressMessages({
    export_top_sensors_summary(wb2, mock_summary_no_diff, output_file2, header_style)
  })

  # Sheet should not be added and CSV not created
  expect_false("Summary_Top_Sensors" %in% names(wb2), label = "Sheet should not be added if within_diff_mean is missing.")
  expect_false(file.exists(csv_file2), label = "CSV should not be created if within_diff_mean is missing.")

  # Cleanup
  if (file.exists(csv_file)) file.remove(csv_file)
  if (file.exists(csv_file2)) file.remove(csv_file2)
})
