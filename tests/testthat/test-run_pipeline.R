library(testthat)

test_that("run_pipeline handles missing data directory correctly", {
  # We need to temporarily intercept log_handler and ensure it gets called
  # without halting the test suite if there's a stop().

  source("../../Updated_Seatek_Analysis.R", local = TRUE)

  # Mock log_handler to capture logs instead of writing to file
  log_env <- new.env()
  log_env$logs <- list()

  mock_log_handler <- function(level, message) {
    log_env$logs[[length(log_env$logs) + 1]] <- list(level = level, message = message)
    return(invisible(NULL))
  }

  # Inject the mock
  assign("log_handler", mock_log_handler, envir = environment(run_pipeline))

  on.exit({
    # Reset log handler to its original state (if we saved it, but source() does it on load anyway)
    # However we're in local=TRUE so it modifies the current env.
  }, add = TRUE)

  # Run pipeline from a temp dir where 'Data' does not exist
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd), add = TRUE)

  # Ensure "Data" does not exist
  data_dir <- file.path(temp_dir, "Data")
  if (dir.exists(data_dir)) {
    unlink(data_dir, recursive = TRUE)
  }

  # Since run_pipeline stops when the data dir doesn't exist, we must catch the error.
  # Our error handler in run_pipeline logs it, but then the stop() propagates unless
  # handled. Actually wait, withCallingHandlers doesn't stop propagation, so we need expect_error.
  expect_error(run_pipeline(), "Data directory does not exist")

  # Verify our mock log handler was called
  expect_true(length(log_env$logs) > 0)

  # Extract levels from captured logs
  levels <- sapply(log_env$logs, function(x) x$level)
  messages <- sapply(log_env$logs, function(x) x$message)

  # Should have a MESSAGE about running main, and an ERROR about missing directory
  expect_true("MESSAGE" %in% levels)
  expect_true(any(grepl("Running main", messages)))

  expect_true("PROCESSING_ERROR" %in% levels)
  expect_true(any(grepl("Data directory does not exist", messages)))
})

test_that("run_pipeline captures warnings and dependency errors", {
  source("../../Updated_Seatek_Analysis.R", local = TRUE)

  log_env <- new.env()
  log_env$logs <- list()

  mock_log_handler <- function(level, message) {
    log_env$logs[[length(log_env$logs) + 1]] <- list(level = level, message = message)
    return(invisible(NULL))
  }

  assign("log_handler", mock_log_handler, envir = environment(run_pipeline))

  # Create a dummy Data dir so it passes the first check
  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd), add = TRUE)

  data_dir <- file.path(temp_dir, "Data")
  dir.create(data_dir, showWarnings = FALSE)
  on.exit(unlink(data_dir, recursive = TRUE), add = TRUE)

  # Mock process_all_data to throw a warning and an error
  assign("process_all_data", function(dir) {
    warning("This is a test warning")
    stop("could not find function 'test_func'")
  }, envir = environment(run_pipeline))

  expect_error(run_pipeline(), "could not find function 'test_func'")

  levels <- sapply(log_env$logs, function(x) x$level)
  messages <- sapply(log_env$logs, function(x) x$message)

  expect_true("WARNING" %in% levels)
  expect_true(any(grepl("This is a test warning", messages)))

  expect_true("DEPENDENCY_ERROR" %in% levels)
  expect_true(any(grepl("could not find function 'test_func'", messages)))
})

test_that("run_pipeline executes successfully with valid data", {
  source("../../Updated_Seatek_Analysis.R", local = TRUE)

  log_env <- new.env()
  log_env$logs <- list()

  mock_log_handler <- function(level, message) {
    log_env$logs[[length(log_env$logs) + 1]] <- list(level = level, message = message)
    return(invisible(NULL))
  }
  assign("log_handler", mock_log_handler, envir = environment(run_pipeline))

  temp_dir <- tempdir()
  old_wd <- setwd(temp_dir)
  on.exit(setwd(old_wd), add = TRUE)

  data_dir <- file.path(temp_dir, "Data")
  dir.create(data_dir, showWarnings = FALSE)
  on.exit(unlink(data_dir, recursive = TRUE), add = TRUE)

  # Mock the process and summary to do nothing but return empty
  assign("process_all_data", function(dir) {
    return(list())
  }, envir = environment(run_pipeline))

  assign("dump_summary_excel", function(res, out) {
    # do nothing
  }, envir = environment(run_pipeline))

  # Should not throw an error
  expect_output(run_pipeline(), "Pipeline finished")

  levels <- sapply(log_env$logs, function(x) x$level)
  messages <- sapply(log_env$logs, function(x) x$message)

  expect_true("MESSAGE" %in% levels)
  expect_true(any(grepl("Processing complete.", messages)))
})
