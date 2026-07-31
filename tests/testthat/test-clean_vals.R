test_that("clean_vals filters positive numbers and drops NAs", {
  expect_equal(clean_vals(c(1, 2, 3)), c(1, 2, 3))
  expect_equal(clean_vals(c(-1, 0, 1)), 1)
  expect_equal(clean_vals(c(-5, -2, 0)), numeric(0))
  expect_equal(clean_vals(numeric(0)), numeric(0))
  expect_equal(clean_vals(c(1, NA, 2, -1)), c(1, 2))
  expect_equal(clean_vals(c(NA_real_, NA_real_)), numeric(0))
})
