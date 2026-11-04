library(testthat)

test_that("makeCluster works", {
  expect_error(parallel::makeCluster(1L), NA)
})
