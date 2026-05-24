library(testthat)

# The auto_detect_data_dir function is expected to be in the global environment
# as Updated_Seatek_Analysis.R is sourced by the testthat.R helper.

test_that("auto_detect_data_dir correctly detects valid directories", {
  # Create a valid temporary directory inside the workspace
  valid_dir <- file.path(getwd(), "temp_valid_data_dir")
  dir.create(valid_dir, recursive = TRUE, showWarnings = FALSE)

  # Ensure cleanup after test
  on.exit(unlink(valid_dir, recursive = TRUE, force = TRUE))

  result <- auto_detect_data_dir(valid_dir)
  expect_equal(result, normalizePath(valid_dir))
})

test_that("auto_detect_data_dir errors on missing directory argument", {
  expect_error(auto_detect_data_dir(), "Data directory not provided.")
})

test_that("auto_detect_data_dir errors on non-existent directory", {
  non_existent_dir <- file.path(getwd(), "this_dir_should_not_exist_12345")
  expect_error(auto_detect_data_dir(non_existent_dir), "Data directory not found:")
})

test_that("auto_detect_data_dir errors on path traversal attempt", {
  # Create a directory outside the workspace (e.g., system temp dir)
  outside_dir <- tempdir()

  # Ensure the test only proceeds if tempdir is actually outside getwd()
  # In most test environments, it is. But just to be sure:
  cwd <- paste0(normalizePath(getwd(), winslash = "/"), "/")
  resolved_outside_dir <- paste0(normalizePath(outside_dir, winslash = "/"), "/")

  if (!startsWith(resolved_outside_dir, cwd)) {
    expect_error(auto_detect_data_dir(outside_dir), "SECURITY: Path traversal detected.")
  } else {
    # If tempdir() happens to be inside getwd(), we simulate an outside dir
    # This shouldn't normally happen but provides robustness.
    skip("tempdir() is inside the current working directory, cannot test path traversal securely")
  }
})
