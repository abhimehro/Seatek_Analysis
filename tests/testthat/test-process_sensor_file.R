library(testthat)
library(data.table)

test_that("find_sensor_files finds files matching pattern and errors on empty", {
  temp_dir <- file.path(tempdir(), "test_find_sensor_files")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # Should error when empty
  expect_error(
    find_sensor_files(temp_dir),
    regexp = "No sensor files found matching"
  )

  # Create dummy matching file
  dummy_file <- file.path(temp_dir, "SS_Y01.txt")
  writeLines("dummy content", dummy_file)

  found <- find_sensor_files(temp_dir)
  expect_equal(length(found), 1)
  expect_equal(basename(found[1]), "SS_Y01.txt")
})

test_that("process_sensor_file correctly processes a valid sensor file", {
  temp_dir <- file.path(tempdir(), "test_process_sensor_file")
  if (dir.exists(temp_dir)) {
    unlink(temp_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  source_data_file <- file.path(getwd(), "data", "SS_Y01_valid.txt")
  if (!file.exists(source_data_file)) {
    # If running from another wd, check fallback
    source_data_file <- file.path("tests", "testthat", "data", "SS_Y01_valid.txt")
  }
  target_file <- file.path(temp_dir, "SS_Y01.txt")
  file.copy(source_data_file, target_file)

  res <- process_sensor_file(target_file, temp_dir)

  expect_true(is.list(res))
  expect_true(all(c("dt", "sheet_name", "raw_task") %in% names(res)))
  expect_equal(res$sheet_name, "1995")
  expect_true(is.data.table(res$dt))
  expect_equal(nrow(res$dt), 32)
  expect_equal(res$raw_task$out_raw, file.path(temp_dir, "SS_Y01.xlsx"))
  expect_true(is.data.table(res$raw_task$df))
})
