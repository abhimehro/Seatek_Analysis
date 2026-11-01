library(testthat)

test_that("execute_tasks_parallel handles empty task list", {
  res <- execute_tasks_parallel(list(), function(x) x)
  expect_equal(res, list())
})

test_that("execute_tasks_parallel executes tasks successfully using parallel backend", {
  tasks <- list(1, 2, 3)
  res <- execute_tasks_parallel(tasks, function(x) x * 2)
  expect_equal(res, list(2, 4, 6))
})

test_that("execute_tasks_parallel falls back to serial execution gracefully", {
  # Redefine the function body in our local env so we can control its execution context
  local_env <- new.env(parent = globalenv())
  local_env$execute_tasks_parallel <- execute_tasks_parallel

  # Mask requireNamespace inside local_env
  local_env$requireNamespace <- function(package, ...) {
    if (package == "parallel") {
      return(FALSE)
    }
    base::requireNamespace(package, ...)
  }

  environment(local_env$execute_tasks_parallel) <- local_env

  tasks <- list(1, 2, 3)

  res <- NULL

  # Run the function in the mocked environment
  # txtProgressBar writes to the terminal, we can capture or suppress it using capture.output
  suppressMessages(
    capture.output({
      res <- local_env$execute_tasks_parallel(tasks, function(x) x * 3)
    })
  )

  expect_equal(res, list(3, 6, 9))
})

test_that("execute_tasks_parallel handles detectCores errors gracefully", {
  # SECURITY: Use testthat::with_mocked_bindings instead of deparse + eval(parse(text=...))
  # to prevent unsafe code injection patterns.
  testthat::with_mocked_bindings(
    detectCores = function() stop("Mock Error"),
    {
      # Now it should fall back to cores=1L
      tasks <- list(1, 2)
      res <- execute_tasks_parallel(tasks, function(x) x * 4)
      expect_equal(res, list(4, 8))
    },
    .package = "parallel"
  )
})

test_that("execute_tasks_parallel executes gracefully on non-unix platforms", {
  # SECURITY: Use testthat::with_mocked_bindings to mock both cluster functions and .Platform
  # avoiding any dynamic eval(parse()) code execution.
  testthat::with_mocked_bindings(
    makeCluster = function(...) "mock_cl",
    stopCluster = function(...) TRUE,
    parLapply = function(cl, tasks, func) lapply(tasks, func),
    {
      testthat::with_mocked_bindings(
        .Platform = list(OS.type = "windows"),
        {
          tasks <- list(1, 2)
          res <- execute_tasks_parallel(tasks, function(x) x * 5)
          expect_equal(res, list(5, 10))
        },
        .package = "base"
      )
    },
    .package = "parallel"
  )
})

test_that("execute_tasks_parallel serial fallback bubbles errors from task_func", {
  local_env <- new.env(parent = globalenv())
  local_env$execute_tasks_parallel <- execute_tasks_parallel

  local_env$requireNamespace <- function(package, ...) {
    if (package == "parallel") {
      return(FALSE)
    }
    base::requireNamespace(package, ...)
  }

  environment(local_env$execute_tasks_parallel) <- local_env

  tasks <- list(1, 2, 3)

  failing_task <- function(x) {
    if (x == 2) stop("Task failed")
    return(x)
  }

  suppressMessages(
    capture.output({
      expect_error(
        local_env$execute_tasks_parallel(tasks, failing_task),
        "Task failed"
      )
    })
  )
})

test_that("execute_tasks_parallel progress bar is closed on error", {
  local_env <- new.env(parent = globalenv())
  local_env$execute_tasks_parallel <- execute_tasks_parallel

  local_env$requireNamespace <- function(package, ...) {
    if (package == "parallel") {
      return(FALSE)
    }
    base::requireNamespace(package, ...)
  }

  environment(local_env$execute_tasks_parallel) <- local_env

  # We need to capture the fact that close() was called on the progress bar.
  # A simple way to do this is to mock close() or txtProgressBar in the local env.

  pb_created <- FALSE
  pb_closed <- FALSE

  local_env$txtProgressBar <- function(min, max, style, ...) {
    pb_created <<- TRUE
    structure(list(min = min, max = max), class = "txtProgressBarMock")
  }

  local_env$setTxtProgressBar <- function(pb, value) {
    # do nothing
  }

  local_env$close <- function(con, ...) {
    if (inherits(con, "txtProgressBarMock")) {
      pb_closed <<- TRUE
    } else {
      base::close(con, ...)
    }
  }

  tasks <- list(1, 2)
  failing_task <- function(x) {
    if (x == 2) stop("Task 2 failed")
    return(x)
  }

  expect_error(
    local_env$execute_tasks_parallel(tasks, failing_task),
    "Task 2 failed"
  )

  expect_true(pb_created)
  expect_true(pb_closed)
})

test_that("execute_tasks_parallel serial fallback handles empty list gracefully", {
  local_env <- new.env(parent = globalenv())
  local_env$execute_tasks_parallel <- execute_tasks_parallel

  local_env$requireNamespace <- function(package, ...) {
    if (package == "parallel") {
      return(FALSE)
    }
    base::requireNamespace(package, ...)
  }

  environment(local_env$execute_tasks_parallel) <- local_env

  # An empty list should be returned immediately before the txtProgressBar throws an error
  # since max (length of tasks) would be 0, violating max > min in txtProgressBar.
  res <- local_env$execute_tasks_parallel(list(), function(x) x)
  expect_equal(res, list())
})
