library(testthat)
library(data.table)

# The read_sensor_data function is expected to be in the global environment
# as Updated_Seatek_Analysis.R should be sourced by the testthat.R helper.

context("Testing read_sensor_data function")

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
               "Invalid file: data/non_existent_file.txt. Does not exist or is not a file.",
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

  # As per the reasoning in the task description:
  # fread on an empty file returns 0 columns.
  # read_sensor_data calculates sensor_cols = min(ncol(dt)-1, 32).
  # If ncol(dt) is 0, sensor_cols = min(-1, 32) = -1.
  # Then, setnames(dt, 1:sensor_cols, ...) becomes setnames(dt, 1:-1, ...), which errors.
  # The error message from setnames for `j = 1:-1` is "Can't assign to column -1 because it doesn't exist."
  # or similar depending on data.table version.
  # A more generic error from base R could be "invalid column type" or about negative subscripts.
  # Let's expect a generic error first, then refine if a specific one is known.
  # The function itself might also have checks for ncol(dt) == 0 after fread.
  # The current function logs a warning if ncol(dt) < 33. If ncol(dt) is 0, it logs warning and proceeds.
  # The setnames call `setnames(dt, 1:sensor_cols, sensor_names)` where `sensor_cols` is `min(ncol(dt) - 1, 32)`.
  # If `ncol(dt)` is 0, `sensor_cols` is -1. `1:sensor_cols` is `c(1,0,-1)`. This will error.
  expect_error(read_sensor_data(empty_file),
               regexp = "Can't assign to column(s) 0, -1 because they don't exist|invalid column type|attempt to set 'names' on an object with no dimensions|subscript out of bounds")
  # The regexp covers a few possible errors from data.table or base R when indices are problematic.
  # A more specific error based on `data.table` behavior with `1:-1` might be `j` must be a vector of names or positive unique integer numbers.
  # For `setnames(data.table(), 1:-1, "foo")` the error is "Error in 1:sensor_cols: result would be too long a vector"
  # This is because 1:-1 is c(1,0,-1)
  # Let's try to be more specific about the error:
  # The actual error from `setnames(data.table(0), 1:-1, c("S1","S0","S-1"))` is
  # "Supplied 3 columns to be assigned but j isn't a list of 3 columns".
  # If `sensor_names` is shorter, it might be different.
  # If `sensor_cols` is -1, then `sensor_names` will be `character(0)`.
  # `setnames(data.table(0), 1:-1, character(0))` -> "Error in 1:sensor_cols: result would be too long a vector"
  # Let's use this "result would be too long a vector" from the `1:sensor_cols` part
  # or "Can't assign to column(s)" from data.table
  # expect_error(read_sensor_data(empty_file), "result would be too long a vector|Can't assign to column")
  # The most likely error is from `1:sensor_cols` when `sensor_cols` is negative.
  # `1:(-1)` gives `c(1, 0, -1)`.
  # `setnames(dt, c(1,0,-1), ...)`
  # The error "column indices must be positive" is common in data.table.
  # Let's use a more general error message that should cover issues with `setnames` and invalid column indices.
  # The actual error in `Updated_Seatek_Analysis.R` for `setnames(dt, 1:sensor_cols, sensor_names)`
  # when `sensor_cols` is -1 and `sensor_names` is `character(0)` is:
  # "Error in setnames(dt, 1:sensor_cols, sensor_names):
  #   Items of 'old' length 3 must be unique but have 3 non-unique item(s): [1] '1', [2] '0', [3] '-1'. Items of 'new' length 0 must be unique."
  # This is quite specific. Let's try to match part of it or a more general data.table error.
  # The error message "old[i] is not the name of a column in x" is also possible if it tries to rename by name.
  # "j must be a vector of names or positive unique integer numbers"
  # Let's stick to a general `expect_error` if the exact message is too complex or version-dependent.
  # The prompt initially suggested `expect_error()`.
  expect_error(read_sensor_data(empty_file))
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
