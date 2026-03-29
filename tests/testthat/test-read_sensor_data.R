library(testthat)
library(data.table)

# The read_sensor_data function is expected to be in the global environment
# as Updated_Seatek_Analysis.R should be sourced by the testthat.R helper.

test_that("read_sensor_data successfully reads a valid file", {
  valid_file <- "data/SS_Y01_valid.txt" # Path relative to tests/testthat/
  dt <- read_sensor_data(valid_file)

  expect_true(is.data.table(dt), info = "Return type should be data.table")
  expect_equal(ncol(dt), 33, info = "Should have 32 sensor columns + 1 Timestamp column")
  expect_equal(nrow(dt), 3, info = "Should have 3 rows as per sample data")

  expected_sensor_names <- paste0("Sensor", sprintf("%02d", 1:32))
  expected_names <- c(expected_sensor_names, "Timestamp")
  expect_equal(names(dt), expected_names, info = "Column names should match expected format")

  expect_true("POSIXct" %in% class(dt$Timestamp), info = "Timestamp column should be POSIXct")
  expect_false(any(is.na(dt$Timestamp)), info = "Timestamps should not be NA")
})

test_that("read_sensor_data handles non-existent files", {
  # Assuming read_sensor_data uses a specific error message format
  expect_error(read_sensor_data("data/non_existent_file.txt"),
               "Invalid file: data/non_existent_file.txt",
               fixed = TRUE) # Use fixed = TRUE for exact match of the error message string
})

test_that("read_sensor_data handles files with fewer columns", {
  invalid_cols_file <- "data/SS_Y02_invalid_cols.txt" # Path relative to tests/testthat/

  # Expect a specific warning message from the function
  expected_warning_msg <- "File SS_Y02_invalid_cols.txt has only 11 columns; expected >=33."
  expect_warning(dt <- read_sensor_data(invalid_cols_file),
                 expected_warning_msg,
                 fixed = TRUE)

  expect_true(is.data.table(dt), info = "Return type should be data.table even with fewer columns")
  # The function should read all available columns and name them sequentially
  # In this case, 10 sensor columns + 1 timestamp column = 11 columns
  expect_equal(ncol(dt), 11, info = "Number of columns should match detected columns")
  expect_equal(nrow(dt), 2, info = "Number of rows should match sample data")

  expected_sensor_names <- paste0("Sensor", sprintf("%02d", 1:10))
  expected_names <- c(expected_sensor_names, "Timestamp")
  expect_equal(names(dt), expected_names, info = "Column names should be Sensor01-Sensor10, Timestamp")
  expect_true("POSIXct" %in% class(dt$Timestamp), info = "Timestamp column should be POSIXct")
  expect_false(any(is.na(dt$Timestamp)), info = "Timestamps should not be NA with fewer columns")
})

test_that("read_sensor_data handles empty files", {
  empty_file <- "data/SS_Y03_empty.txt" # Path relative to tests/testthat/
  expect_error(read_sensor_data(empty_file), regexp = "only 0's may be mixed with negative subscripts")
})

test_that("read_sensor_data correctly converts numeric timestamps", {
  valid_file <- "data/SS_Y01_valid.txt" # Path relative to tests/testthat/
  dt <- read_sensor_data(valid_file)

  expect_true("POSIXct" %in% class(dt$Timestamp), info = "Timestamp column should be POSIXct")
  expect_false(any(is.na(dt$Timestamp)), info = "Timestamps should not be NA after conversion")

  # Check if the first timestamp is correctly converted from numeric to POSIXct
  # The sample data uses 1609459200, which is 2021-01-01 00:00:00 UTC
  # R's as.POSIXct default origin is "1970-01-01" UTC.
  # So, as.POSIXct(1609459200, origin = "1970-01-01", tz = "UTC")
  # We should compare the numeric value to avoid timezone printing issues.
  expected_first_timestamp_numeric <- 1609459200
  expect_equal(as.numeric(dt$Timestamp[1]), expected_first_timestamp_numeric,
               info = "First timestamp numeric value should match input")

  # Check all timestamps
  original_timestamps <- c(1609459200, 1609459260, 1609459320)
  expect_equal(as.numeric(dt$Timestamp), original_timestamps,
               info = "All timestamp numeric values should match input")
})

# Example of a more focused test for a specific part, if needed:
# test_that("Timestamp column name is exactly 'Timestamp'", {
#   valid_file <- "data/SS_Y01_valid.txt"
#   dt <- read_sensor_data(valid_file)
#   expect_true("Timestamp" %in% names(dt))
#   expect_equal(names(dt)[33], "Timestamp")
# })
