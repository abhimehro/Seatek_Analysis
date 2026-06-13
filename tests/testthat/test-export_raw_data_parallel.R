library(testthat)

test_that("export_raw_data_parallel handles empty task list", {
  # It should just return NULL or nothing and not throw an error
  expect_silent(export_raw_data_parallel(list()))
})

test_that("export_raw_data_parallel writes excel files correctly", {
  tmp_dir <- tempfile()
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE))

  # Mock data.table for tasks
  dt1 <- data.table::data.table(A = 1:5, B = letters[1:5])
  dt2 <- data.table::data.table(C = 10:14, D = LETTERS[1:5])

  file1 <- file.path(tmp_dir, "test1.xlsx")
  file2 <- file.path(tmp_dir, "test2.xlsx")

  # Define tasks correctly. Note: function expects out_raw and df
  raw_tasks <- list(
    list(df = dt1, out_raw = file1),
    list(df = dt2, out_raw = file2)
  )

  # export_raw_data_parallel prints one message per output file; suppress them
  suppressMessages(export_raw_data_parallel(raw_tasks))

  # Verify files exist
  expect_true(file.exists(file1))
  expect_true(file.exists(file2))

  # Verify content
  res1 <- openxlsx::read.xlsx(file1)
  res2 <- openxlsx::read.xlsx(file2)

  expect_equal(res1$A, 1:5)
  expect_equal(res1$B, letters[1:5])

  expect_equal(res2$C, 10:14)
  expect_equal(res2$D, LETTERS[1:5])
})
