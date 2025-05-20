library(testthat)
library(data.table) # process_all_data likely uses data.table indirectly via read_sensor_data
# library(openxlsx) # process_all_data uses openxlsx for writing, ensure it's noted if tests require it explicitly

# The process_all_data function is expected to be in the global environment
# as Updated_Seatek_Analysis.R should be sourced by the testthat.R helper.

context("Testing process_all_data function")

test_that("process_all_data correctly processes valid data", {
  temp_dir_name <- "temp_valid_data_for_process"
  # temp_dir_path is relative to tests/testthat
  # testthat runs tests with the working directory set to the directory containing the test file.
  # So getwd() inside tests/testthat/test-process_all_data.R will be tests/testthat
  temp_dir_path <- file.path(getwd(), temp_dir_name)

  # Clean up before test, in case of previous failed run
  if (dir.exists(temp_dir_path)) {
    unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir_path, recursive = TRUE, showWarnings = FALSE)

  # Path to the source data file, assuming getwd() is tests/testthat/
  source_data_file <- file.path(getwd(), "data", "SS_Y01_valid.txt")
  # Check if source data file exists, for robust testing
  if (!file.exists(source_data_file)) {
    stop(paste("Test setup error: Source data file not found at", source_data_file))
  }
  file.copy(source_data_file, file.path(temp_dir_path, "SS_Y01_valid.txt"))

  results <- process_all_data(temp_dir_path)

  expect_true(is.list(results), info = "Results should be a list")
  expect_equal(length(results), 1, info = "Results list should have 1 element for SS_Y01_valid.txt")
  expect_true("1995" %in% names(results), info = "Year '1995' should be a name in the results list")

  year_data <- results[["1995"]]
  expect_true(is.data.frame(year_data), info = "Element for '1995' should be a data.frame")
  expect_equal(nrow(year_data), 32, info = "Data.frame should have 32 rows (Sensor01 to Sensor32)")
  expect_equal(ncol(year_data), 4, info = "Data.frame should have 4 columns")
  expect_equal(colnames(year_data), c("first10", "last5", "full", "within_diff"), info = "Column names mismatch")
  expect_equal(rownames(year_data)[1], "Sensor01", info = "First row name should be 'Sensor01'")

  # Values for Sensor01 in SS_Y01_valid.txt are 10.1, 10.2, 10.3
  # The clean_vals function (called by process_sensor_data) filters for > 0, which these are.
  # For SS_Y01_valid.txt (3 data points):
  # first10: uses all 3 points as 3 < 10
  # last5: uses all 3 points as 3 < 5
  # full: uses all 3 points
  expected_mean_val <- mean(c(10.1, 10.2, 10.3)) # This is 10.2

  expect_equal(year_data["Sensor01", "first10"], expected_mean_val, info = "Mismatch in 'first10' for Sensor01")
  expect_equal(year_data["Sensor01", "last5"], expected_mean_val, info = "Mismatch in 'last5' for Sensor01")
  expect_equal(year_data["Sensor01", "full"], expected_mean_val, info = "Mismatch in 'full' for Sensor01")
  expect_equal(year_data["Sensor01", "within_diff"], expected_mean_val - expected_mean_val, info = "Mismatch in 'within_diff' for Sensor01") # Should be 0

  # Check for Excel file creation
  expected_excel_file <- file.path(temp_dir_path, "SS_Y01_valid.xlsx")
  expect_true(file.exists(expected_excel_file), info = paste("Excel file not found at:", expected_excel_file))

  # Cleanup after test
  unlink(temp_dir_path, recursive = TRUE, force = TRUE)
})

test_that("process_all_data handles no matching files", {
  temp_dir_name <- "temp_empty_data_for_process"
  temp_dir_path <- file.path(getwd(), temp_dir_name)

  if (dir.exists(temp_dir_path)) {
    unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir_path, recursive = TRUE, showWarnings = FALSE)

  # Expect an error if no files matching "SS_Y*.txt" are found
  expect_error(process_all_data(temp_dir_path), regexp = "No sensor files found matching")

  unlink(temp_dir_path, recursive = TRUE, force = TRUE)
})

test_that("process_all_data handles non-existent data directory", {
  non_existent_dir_path <- file.path(getwd(), "non_existent_dir_for_process_test")

  # Ensure the directory does not exist before the test
  if (dir.exists(non_existent_dir_path)) {
    unlink(non_existent_dir_path, recursive = TRUE, force = TRUE)
  }

  expect_error(process_all_data(non_existent_dir_path), regexp = "Data directory not found:")
})
