library(testthat)

# Source the script containing the function
# We assume the test is run with the working directory as 'tests/testthat'
# or that we can find the file relative to the project root.
# Let's try to robustly locate the file.

script_rel_path <- "../../implementation/scripts/01_environment_setup.R"
if (!file.exists(script_rel_path)) {
  # Fallback if run from project root
  script_rel_path <- "implementation/scripts/01_environment_setup.R"
}

if (!file.exists(script_rel_path)) {
  stop("Could not locate 01_environment_setup.R")
}

source(script_rel_path)

context("Environment Setup Checks")

test_that("check_r_version returns success for compatible version", {
  # Mock R version 4.0.0
  mock_version <- list(
    major = "4",
    minor = "0.0",
    version.string = "R version 4.0.0 (Mock)"
  )

  result <- check_r_version(mock_version)

  expect_true(result$success)
  expect_equal(result$message, "R version compatible")
})

test_that("check_r_version returns success for newer major version", {
  # Mock R version 5.0.0
  mock_version <- list(
    major = "5",
    minor = "0.0",
    version.string = "R version 5.0.0 (Mock)"
  )

  result <- check_r_version(mock_version)

  expect_true(result$success)
})

test_that("check_r_version returns failure for incompatible version", {
  # Mock R version 3.6.3
  mock_version <- list(
    major = "3",
    minor = "6.3",
    version.string = "R version 3.6.3 (Mock)"
  )

  result <- check_r_version(mock_version)

  expect_false(result$success)
  expect_match(result$message, "is not compatible")
})

test_that("check_r_version handles current environment correctly", {
  # This tests the default argument
  result <- check_r_version()

  expect_true(is.list(result))
  expect_true("success" %in% names(result))
  expect_true("message" %in% names(result))

  # Check if result matches actual version check logic
  current_r <- R.version
  major <- as.numeric(current_r$major)
  minor <- as.numeric(current_r$minor)
  expected_success <- (major > 4) || (major == 4 && minor >= 0)

  expect_equal(result$success, expected_success)
})
