library(testthat)

# The validate_sensor_file function is expected to be in the global environment
# as Updated_Seatek_Analysis.R is sourced by the testthat.R helper.

test_that("validate_sensor_file accepts valid files", {
  # Create a valid temporary file
  valid_file <- tempfile(fileext = ".txt")
  writeLines("test data", valid_file)
  on.exit(unlink(valid_file, force = TRUE))

  # Should not error
  expect_silent(validate_sensor_file(valid_file))
})

test_that("validate_sensor_file errors on non-existent file", {
  non_existent_file <- tempfile(fileext = ".txt")
  expect_error(validate_sensor_file(non_existent_file), "Invalid file:")
})

test_that("validate_sensor_file errors on wrong extension", {
  # Create a file with a wrong extension
  wrong_ext_file <- tempfile(fileext = ".csv")
  writeLines("test data", wrong_ext_file)
  on.exit(unlink(wrong_ext_file, force = TRUE))

  expect_error(validate_sensor_file(wrong_ext_file), "Invalid file:")
})

test_that("validate_sensor_file errors on oversized file", {
  # Create a valid temporary file
  large_file <- tempfile(fileext = ".txt")
  writeLines("test data", large_file)
  on.exit(unlink(large_file, force = TRUE))

  # Temporarily override file.size in the global environment to simulate a large file
  original_file_size <- base::file.size
  assign("file.size", function(...) 60 * 1024 * 1024, envir = .GlobalEnv)

  # Ensure cleanup of the mock
  on.exit({
    rm(list = "file.size", envir = .GlobalEnv)
    unlink(large_file, force = TRUE)
  }, add = TRUE)

  expect_error(validate_sensor_file(large_file), "exceeds maximum allowed size")
})
