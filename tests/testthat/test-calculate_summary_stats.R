library(testthat)

# Note: The test will produce a warning from data.table::melt:
# 'measure.vars' [mean, sd, median, mad, ...] are not all of the same type.
# By order of hierarchy, the molten data value column will be of type 'double'.
# This is expected and harmless, as it relates to integer/double coercion.

test_that("calculate_summary_stats correctly aggregates multi-year data", {
  # Mock results data generation
  mock_sensor_data <- function(val_offset) {
    data.table::data.table(
      Sensor = paste0("Sensor", sprintf("%02d", 1:3)),
      first10 = as.numeric(c(10, 20, NA)) + val_offset,
      last5 = as.numeric(c(5, 15, 25)) + val_offset,
      full = as.numeric(c(10, 20, 30)) + val_offset
    )
  }

  years <- c("1995", "1996", "1997", "1998")
  mock_results <- stats::setNames(lapply(1:length(years), function(i) mock_sensor_data(i)), years)

  # Call the function being tested
  # Suppress the data.table::melt coercion warning for clean test output
  suppressWarnings({
    summary_df <- calculate_summary_stats(mock_results)
  })

  # Check if result is a data.table/data.frame
  expect_true(is.data.frame(summary_df))

  # Check expected columns
  expected_cols <- c("Sensor", "first10_mean", "first10_count", "last5_median", "full_count", "full_pct_nonmissing")
  for (col in expected_cols) {
    expect_true(col %in% names(summary_df))
  }

  # Check row count
  expect_equal(nrow(summary_df), 3)

  # Check values for Sensor01 (all 4 years have data)
  sensor01_row <- summary_df[Sensor == "Sensor01"]
  expect_equal(sensor01_row$first10_mean, mean(c(11, 12, 13, 14)))
  expect_equal(sensor01_row$first10_count, 4)
  expect_equal(sensor01_row$full_pct_nonmissing, 100)
  expect_equal(sensor01_row$first10_min, 11)
  expect_equal(sensor01_row$first10_max, 14)
  expect_equal(sensor01_row$first10_rollmean3, 13)

  # Check values for Sensor03
  sensor03_row <- summary_df[Sensor == "Sensor03"]
  expect_true(is.na(sensor03_row$first10_mean))
  expect_equal(sensor03_row$first10_count, 0)
  expect_true(is.na(sensor03_row$first10_rollmean3))

  expect_equal(sensor03_row$full_count, 4)
  expect_equal(sensor03_row$full_pct_nonmissing, 100)
})

test_that("calculate_summary_stats handles empty input", {
  mock_results <- list()

  # rbindlist on empty list returns empty data.table with no columns
  # calculate_summary_stats will likely fail when trying to find 'Sensor' and 'Year'
  # or handle it and return empty.
  expect_error(calculate_summary_stats(mock_results))
})
