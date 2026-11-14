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
  mock_results <- stats::setNames(lapply(seq_along(years), function(i) mock_sensor_data(i)), years)

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

test_that("compute_vector_summary_stats calculates correct statistics", {
  # Regular numeric vector
  vals <- c(10, 20, 30, 40)
  stats_res <- compute_vector_summary_stats(vals)
  expect_equal(stats_res$count, 4L)
  expect_equal(stats_res$mean, 25)
  expect_equal(stats_res$median, 25)
  expect_equal(stats_res$min, 10)
  expect_equal(stats_res$max, 40)
  expect_equal(stats_res$rollmean3, (20 + 30 + 40) / 3)

  # Vector with NAs
  vals_na <- c(10, NA, 20, NA, 30)
  stats_na <- compute_vector_summary_stats(vals_na)
  expect_equal(stats_na$count, 3L)
  expect_equal(stats_na$mean, 20)
  expect_equal(stats_na$median, 20)
  expect_equal(stats_na$min, 10)
  expect_equal(stats_na$max, 30)
  expect_equal(stats_na$rollmean3, 20)

  # Vector with length < 3
  stats_short <- compute_vector_summary_stats(c(5, 15))
  expect_equal(stats_short$count, 2L)
  expect_true(is.na(stats_short$rollmean3))

  # Empty / all NA vector
  stats_empty <- compute_vector_summary_stats(numeric(0))
  expect_equal(stats_empty$count, 0L)
  expect_true(is.na(stats_empty$mean))
  expect_true(is.na(stats_empty$sd))
  expect_true(is.na(stats_empty$median))
  expect_true(is.na(stats_empty$mad))
  expect_true(is.na(stats_empty$min))
  expect_true(is.na(stats_empty$max))
  expect_true(is.na(stats_empty$rollmean3))

  stats_all_na <- compute_vector_summary_stats(c(NA_real_, NA_real_))
  expect_equal(stats_all_na$count, 0L)
  expect_true(is.na(stats_all_na$mean))
})

test_that("generate_summary_stat_names generates consistent column schema", {
  # Verify generated column names align with expected metric prefixes and statistics
  names_out <- generate_summary_stat_names(c("first10", "full"))
  expect_equal(names_out[1], "Sensor")
  expect_true("first10_mean" %in% names_out)
  expect_true("first10_count" %in% names_out)
  expect_true("first10_rollmean3" %in% names_out)
  expect_true("full_mean" %in% names_out)
  expect_true("full_count" %in% names_out)
  expect_equal(length(names_out), 1 + 2 * 8)
})

test_that("aggregate_metric_stats aggregates metrics across sensors correctly", {
  dt <- data.table::data.table(
    Year = c("1995", "1996", "1995", "1996"),
    Sensor = c("Sensor01", "Sensor01", "Sensor02", "Sensor02"),
    first10 = c(10, 20, 30, 40),
    full = c(100, 200, 300, 400)
  )

  res <- aggregate_metric_stats(dt, c("first10", "full"))

  expect_true(data.table::is.data.table(res))
  expect_equal(nrow(res), 2)
  expect_equal(res$Sensor, c("Sensor01", "Sensor02"))
  expect_equal(res$first10_mean, c(15, 35))
  expect_equal(res$first10_count, c(2L, 2L))
  expect_equal(res$full_mean, c(150, 350))
  expect_equal(res$full_count, c(2L, 2L))
})

test_that("add_pct_nonmissing computes percentages accurately and handles edge cases", {
  dt <- data.table::data.table(
    Sensor = c("Sensor01", "Sensor02"),
    full_count = c(4L, 2L)
  )

  # Standard calculation with 4 years
  res <- add_pct_nonmissing(dt, results_count = 4)
  expect_true("full_pct_nonmissing" %in% names(res))
  expect_equal(res$full_pct_nonmissing, c(100, 50))

  # Test data.frame fallback
  df <- data.frame(
    Sensor = c("Sensor01", "Sensor02"),
    full_count = c(4L, 2L)
  )
  res_df <- add_pct_nonmissing(df, results_count = 4)
  expect_equal(res_df$full_pct_nonmissing, c(100, 50))
})
