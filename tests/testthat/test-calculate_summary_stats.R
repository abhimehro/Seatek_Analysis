library(testthat)

context("Testing calculate_summary_stats function")

test_that("calculate_summary_stats handles strict n < 3 for rollmean3", {

  mock_results <- list(
    "Year1" = data.frame(full = c(10, 20, NA), row.names = c("Sensor01", "Sensor02", "Sensor03")),
    "Year2" = data.frame(full = c(15, NA, NA), row.names = c("Sensor01", "Sensor02", "Sensor03")),
    "Year3" = data.frame(full = c(20, 30, NA), row.names = c("Sensor01", "Sensor02", "Sensor03"))
  )

  summary_df <- calculate_summary_stats(mock_results)

  # The output of calculate_summary_stats is a wide data.frame
  # (as.data.frame(summary_wide) is called before returning)
  # The columns are formatted as Metric_Stat, e.g., "full_rollmean3"

  # Sensor01: 3 valid values (10, 15, 20) -> mean(10, 15, 20) = 15
  expect_equal(summary_df[summary_df$Sensor == "Sensor01", "full_rollmean3"], 15)

  # Sensor02: 2 valid values (20, NA, 30) -> should be NA
  expect_true(is.na(summary_df[summary_df$Sensor == "Sensor02", "full_rollmean3"]),
              info = "Sensor with n < 3 should have NA for rollmean3")

  # Sensor03: 0 valid values -> should be NA
  expect_true(is.na(summary_df[summary_df$Sensor == "Sensor03", "full_rollmean3"]),
              info = "Sensor with all NA should have NA for rollmean3")

  # Check count is correct
  expect_equal(summary_df[summary_df$Sensor == "Sensor01", "full_count"], 3)
  expect_equal(summary_df[summary_df$Sensor == "Sensor02", "full_count"], 2)
  expect_equal(summary_df[summary_df$Sensor == "Sensor03", "full_count"], 0)
})

test_that("calculate_summary_stats correctly computes summary metrics and handles rollmean3 edge cases with full data", {

  years <- as.character(2001:2004)

  mock_results <- list(
    "2001" = data.frame(
      first10 = c(10, 20, NA, 40),
      last5   = c(11, 21, NA, 41),
      full    = c(12, 22, NA, 42),
      within_diff = c(2, 1, NA, 2),
      row.names = c("Sensor01", "Sensor02", "Sensor03", "Sensor04")
    ),
    "2002" = data.frame(
      first10 = c(15, NA, NA, 45),
      last5   = c(16, NA, NA, 46),
      full    = c(17, NA, NA, 47),
      within_diff = c(2, NA, NA, 2),
      row.names = c("Sensor01", "Sensor02", "Sensor03", "Sensor04")
    ),
    "2003" = data.frame(
      first10 = c(20, 30, NA, 50),
      last5   = c(21, 31, NA, 51),
      full    = c(22, 32, NA, 52),
      within_diff = c(2, 1, NA, 2),
      row.names = c("Sensor01", "Sensor02", "Sensor03", "Sensor04")
    ),
    "2004" = data.frame(
      first10 = c(25, NA, NA, 55),
      last5   = c(26, NA, NA, 56),
      full    = c(27, NA, NA, 57),
      within_diff = c(2, NA, NA, 2),
      row.names = c("Sensor01", "Sensor02", "Sensor03", "Sensor04")
    )
  )

  summary_df <- calculate_summary_stats(mock_results)

  # Sensor01: 4 years, full_rollmean3 should be mean(c(17, 22, 27)) = 22
  expect_equal(summary_df[summary_df$Sensor == "Sensor01", "full_rollmean3"], mean(c(17, 22, 27)),
               info = "Sensor01 should calculate rollmean3 from last 3 valid values")

  # Sensor02: 2 valid years (2001, 2003), full_rollmean3 should be NA
  expect_true(is.na(summary_df[summary_df$Sensor == "Sensor02", "full_rollmean3"]),
               info = "Sensor02 has only 2 valid years, rollmean3 should be NA")

  # Sensor03: All NA, full_rollmean3 should be NA
  expect_true(is.na(summary_df[summary_df$Sensor == "Sensor03", "full_rollmean3"]),
               info = "Sensor03 has 0 valid years, rollmean3 should be NA")

  # Sensor04: 4 years, full_rollmean3 should be mean(c(47, 52, 57)) = 52
  expect_equal(summary_df[summary_df$Sensor == "Sensor04", "full_rollmean3"], mean(c(47, 52, 57)),
               info = "Sensor04 should calculate rollmean3 from last 3 valid values")

})
