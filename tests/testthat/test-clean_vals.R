library(testthat)

# Note: In the R testing suite, tests/testthat/testthat.R sources the main script
# into the environment, but if we're running an individual file without
# `testthat::test_dir()`, we need to make sure the function is available.
if (!exists("clean_vals")) {
  if (file.exists("Updated_Seatek_Analysis.R")) {
    source("Updated_Seatek_Analysis.R")
  } else if (file.exists("../../Updated_Seatek_Analysis.R")) {
    source("../../Updated_Seatek_Analysis.R")
  }
}

test_that("clean_vals filters positive numbers correctly", {
  # Test with positive, negative, and zero
  expect_equal(clean_vals(c(-1, 0, 1, 2, -3)), c(1, 2))

  # Test with NA - which() inherently drops NA values
  expect_equal(clean_vals(c(NA, 1, 2, NA)), c(1, 2))

  # Test with all negative/zero
  expect_equal(clean_vals(c(-1, 0, -2)), numeric(0))

  # Test with all positive
  expect_equal(clean_vals(c(1, 2, 3)), c(1, 2, 3))

  # Test with empty vector
  expect_equal(clean_vals(numeric(0)), numeric(0))
})
