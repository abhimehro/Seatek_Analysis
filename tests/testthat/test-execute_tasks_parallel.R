library(mockery)
library(testthat)

# The function execute_tasks_parallel is available in the global environment
# as Updated_Seatek_Analysis.R is sourced by testthat.R

test_that("execute_tasks_parallel returns empty list for empty tasks", {
  res <- execute_tasks_parallel(list(), function(x) x)
  expect_equal(res, list())
})

test_that("execute_tasks_parallel serial fallback works", {
  # Mock requireNamespace to simulate 'parallel' package missing
  stub(execute_tasks_parallel, "requireNamespace", function(...) FALSE)

  tasks <- list(1, 2, 3)
  task_func <- function(x) x * 2
  res <- execute_tasks_parallel(tasks, task_func)
  expect_equal(res, list(2, 4, 6))
})

test_that("execute_tasks_parallel parallel logic works (current OS)", {
  stub(execute_tasks_parallel, "requireNamespace", function(...) TRUE)

  stub(execute_tasks_parallel, "parallel::detectCores", function(...) 2)
  stub(execute_tasks_parallel, "parallel::mclapply", function(X, FUN, mc.cores, ...) lapply(X, FUN))
  stub(execute_tasks_parallel, "parallel::makeCluster", function(...) "mock_cluster")
  stub(execute_tasks_parallel, "parallel::stopCluster", function(cl) NULL)
  stub(execute_tasks_parallel, "parallel::parLapply", function(cl, X, FUN, ...) lapply(X, FUN))

  tasks <- list(1, 2, 3)
  task_func <- function(x) x * 2
  res <- execute_tasks_parallel(tasks, task_func)
  expect_equal(res, list(2, 4, 6))
})

test_that("execute_tasks_parallel parallel logic works (detectCores fails)", {
  stub(execute_tasks_parallel, "requireNamespace", function(...) TRUE)
  stub(execute_tasks_parallel, "parallel::detectCores", function() stop("error detecting cores"))

  # For the actual assertion
  mclapply_mock <- mock(lapply(list(1, 2, 3), function(x) x * 2))
  stub(execute_tasks_parallel, "parallel::mclapply", mclapply_mock)
  parLapply_mock <- mock(lapply(list(1, 2, 3), function(x) x * 2))
  stub(execute_tasks_parallel, "parallel::parLapply", parLapply_mock)
  stub(execute_tasks_parallel, "parallel::makeCluster", function(...) "mock_cluster")
  stub(execute_tasks_parallel, "parallel::stopCluster", function(cl) NULL)

  tasks <- list(1, 2, 3)
  task_func <- function(x) x * 2
  res <- execute_tasks_parallel(tasks, task_func)
  expect_equal(res, list(2, 4, 6))

  if (.Platform$OS.type == "unix") {
    expect_called(mclapply_mock, 1)
    expect_args(mclapply_mock, 1, tasks, task_func, mc.cores = 1)
  } else {
    expect_called(parLapply_mock, 1)
    expect_args(parLapply_mock, 1, "mock_cluster", tasks, task_func)
  }
})
