test_that("lapply(.SD) optimization produces exact same results as sapply baseline", {
  library(data.table)

  # Function to clean values (dropping NAs and values <= 0)
  # This matches the implementation in the benchmark and main script
  clean_vals <- function(x) x[which(x > 0)]

  # Setup synthetic data.table mimicking the benchmark data
  set.seed(42)
  n_rows <- 50
  n_cols <- 5
  sensor_names <- paste0("Sensor", sprintf("%02d", 1:n_cols))

  # Introduce some NAs and negatives to simulate real-world data and edge cases
  # Done on the matrix before converting to data.table to ensure correct element-wise replacement
  mat <- matrix(runif(n_rows * n_cols, -5, 15), nrow = n_rows)
  mat[sample(1:(n_rows * n_cols), 20)] <- NA
  mat[sample(1:(n_rows * n_cols), 20)] <- -1

  df <- data.table(mat)
  setnames(df, sensor_names)

  # --- Baseline: Using sapply with column slicing ---
  baseline_first10 <- sapply(df[, ..sensor_names], function(x) {
    mean(clean_vals(head(x, 10)))
  })
  baseline_last5   <- sapply(df[, ..sensor_names], function(x) {
    mean(clean_vals(tail(x, 5)))
  })
  baseline_full    <- sapply(df[, ..sensor_names], function(x) {
    mean(clean_vals(x))
  })

  # --- Optimized: Using data.table native lapply(.SD) ---
  optimized_first10 <- unlist(df[1:min(10, .N), lapply(.SD, function(x) {
    mean(clean_vals(x))
  }), .SDcols = sensor_names])

  optimized_last5   <- unlist(df[max(1, .N - 4):.N, lapply(.SD, function(x) {
    mean(clean_vals(x))
  }), .SDcols = sensor_names])

  optimized_full    <- unlist(df[, lapply(.SD, function(x) {
    mean(clean_vals(x))
  }), .SDcols = sensor_names])

  # --- Assertions ---
  # Names should match
  expect_equal(names(baseline_first10), names(optimized_first10))
  expect_equal(names(baseline_last5), names(optimized_last5))
  expect_equal(names(baseline_full), names(optimized_full))

  # Values should be identical
  expect_equal(baseline_first10, optimized_first10)
  expect_equal(baseline_last5, optimized_last5)
  expect_equal(baseline_full, optimized_full)
})
