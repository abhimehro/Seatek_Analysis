library(testthat)

context("Testing calculate_summary_stats function")

test_that("calculate_summary_stats correctly computes statistics", {
  # Create a mock results list simulating process_all_data output
  # Three years, 2 sensors
  mock_results <- list(
    "1995" = data.frame(
      first10 = c(10, 20),
      last5 = c(15, 25),
      full = c(12, 22),
      within_diff = c(2, 5),
      row.names = c("Sensor01", "Sensor02")
    ),
    "1996" = data.frame(
      first10 = c(12, 22),
      last5 = c(17, 27),
      full = c(14, 24),
      within_diff = c(2, 5),
      row.names = c("Sensor01", "Sensor02")
    ),
    "1997" = data.frame(
      first10 = c(14, 24),
      last5 = c(19, 29),
      full = c(16, 26),
      within_diff = c(2, 5),
      row.names = c("Sensor01", "Sensor02")
    )
  )

  summary_df <- calculate_summary_stats(mock_results)

  # Check structure
  expect_s3_class(summary_df, "data.frame")
  expect_equal(nrow(summary_df), 2) # 2 sensors

  # Check Sensor01 'full' statistics
  # full values for Sensor01: 12, 14, 16
  expect_equal(summary_df$full_count[summary_df$Sensor == "Sensor01"], 3)
  expect_equal(summary_df$full_mean[summary_df$Sensor == "Sensor01"], mean(c(12, 14, 16)))
  expect_equal(summary_df$full_sd[summary_df$Sensor == "Sensor01"], sd(c(12, 14, 16)))
  expect_equal(summary_df$full_median[summary_df$Sensor == "Sensor01"], median(c(12, 14, 16)))
  expect_equal(summary_df$full_mad[summary_df$Sensor == "Sensor01"], mad(c(12, 14, 16)))
  expect_equal(summary_df$full_min[summary_df$Sensor == "Sensor01"], min(c(12, 14, 16)))
  expect_equal(summary_df$full_max[summary_df$Sensor == "Sensor01"], max(c(12, 14, 16)))
  expect_equal(summary_df$full_rollmean3[summary_df$Sensor == "Sensor01"], mean(tail(c(12, 14, 16), 3)))

  # Check non-missing percentage
  expect_equal(summary_df$full_pct_nonmissing[summary_df$Sensor == "Sensor01"], 100)
})

test_that("calculate_summary_stats handles missing values correctly", {
  mock_results_na <- list(
    "1995" = data.frame(
      first10 = c(10, NA),
      last5 = c(15, 25),
      full = c(12, 22),
      within_diff = c(2, 5),
      row.names = c("Sensor01", "Sensor02")
    ),
    "1996" = data.frame(
      first10 = c(12, 22),
      last5 = c(17, 27),
      full = c(14, NA),
      within_diff = c(2, 5),
      row.names = c("Sensor01", "Sensor02")
    )
  )

  summary_df_na <- calculate_summary_stats(mock_results_na)

  # Sensor01 first10 has no NAs: (10, 12) -> mean = 11
  expect_equal(summary_df_na$first10_mean[summary_df_na$Sensor == "Sensor01"], mean(c(10, 12)))
  expect_equal(summary_df_na$first10_count[summary_df_na$Sensor == "Sensor01"], 2)

  # Sensor02 first10 has one NA: (NA, 22) -> na.omit(NA, 22) -> mean = 22, count = 1
  expect_equal(summary_df_na$first10_mean[summary_df_na$Sensor == "Sensor02"], 22)
  expect_equal(summary_df_na$first10_count[summary_df_na$Sensor == "Sensor02"], 1)

  # Sensor02 full has one NA: (22, NA) -> count = 1
  expect_equal(summary_df_na$full_count[summary_df_na$Sensor == "Sensor02"], 1)
  # full_pct_nonmissing = 1 / 2 * 100 = 50
  expect_equal(summary_df_na$full_pct_nonmissing[summary_df_na$Sensor == "Sensor02"], 50)
})

test_that("calculate_summary_stats handles empty or entirely NA data", {
  # Entirely NA data
  mock_results_all_na <- list(
    "1995" = data.frame(
      first10 = c(NA_real_, NA_real_),
      last5 = c(NA_real_, NA_real_),
      full = c(NA_real_, NA_real_),
      within_diff = c(NA_real_, NA_real_),
      row.names = c("Sensor01", "Sensor02")
    )
  )

  summary_df_all_na <- calculate_summary_stats(mock_results_all_na)

  expect_true(is.na(summary_df_all_na$first10_mean[summary_df_all_na$Sensor == "Sensor01"]))
  expect_equal(summary_df_all_na$first10_count[summary_df_all_na$Sensor == "Sensor01"], 0)
  expect_equal(summary_df_all_na$full_pct_nonmissing[summary_df_all_na$Sensor == "Sensor01"], 0)
})
