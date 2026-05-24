library(testthat)

test_that("log_handler writes formatted messages to log_file", {
  # Source the main script to make log_handler available
  source("../../Updated_Seatek_Analysis.R", local = TRUE)

  # Create a temporary file path
  temp_log <- tempfile("test_log_", fileext = ".log")

  # Save the original log_file value from where log_handler looks for it
  original_log_file <- get("log_file", envir = environment(log_handler))

  # Temporarily override log_file
  assign("log_file", temp_log, envir = environment(log_handler))

  on.exit({
    # Restore the original log_file value
    assign("log_file", original_log_file, envir = environment(log_handler))
    # Cleanup temporary file
    if (file.exists(temp_log)) {
      suppressWarnings(file.remove(temp_log))
    }
  }, add = TRUE)

  # Execute log_handler
  log_handler("INFO", "This is a test info message")
  log_handler("ERROR", "This is a test error message")

  # Verify the log file was created
  expect_true(file.exists(temp_log))

  # Read the contents of the log file
  log_lines <- readLines(temp_log)

  # Verify the contents
  expect_length(log_lines, 2)
  expect_equal(log_lines[1], "[INFO] This is a test info message")
  expect_equal(log_lines[2], "[ERROR] This is a test error message")
})
