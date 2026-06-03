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
        if (package == "parallel") return(FALSE)
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
    # Redefine the function body in our local env so we can control its execution context
    local_env <- new.env(parent = globalenv())
    local_env$execute_tasks_parallel <- execute_tasks_parallel

    # We want it to use parallel namespace but intercept tryCatch or detectCores.
    # Since tryCatch evaluates detectCores() in baseenv, masking detectCores in the function environment is hard
    # because it specifically calls `parallel::detectCores()`.
    # To mock a namespaced call without a mocking framework, we can redefine the function's source code text.

    func_text <- deparse(execute_tasks_parallel)
    func_text <- gsub("parallel::detectCores()", "stop('Mock Error')", func_text, fixed = TRUE)

    local_env$execute_tasks_parallel_mocked <- eval(parse(text = paste(func_text, collapse = "\n")))

    # Now it should fall back to cores=1L
    tasks <- list(1, 2)
    res <- local_env$execute_tasks_parallel_mocked(tasks, function(x) x * 4)
    expect_equal(res, list(4, 8))
})

test_that("execute_tasks_parallel executes gracefully on non-unix platforms", {
    local_env <- new.env(parent = globalenv())

    # We want to force the non-unix branch: .Platform$OS.type != "unix"
    func_text <- deparse(execute_tasks_parallel)
    func_text <- gsub(".Platform$OS.type == \"unix\"", "FALSE", func_text, fixed = TRUE)

    local_env$execute_tasks_parallel_mocked <- eval(parse(text = paste(func_text, collapse = "\n")))

    tasks <- list(1, 2)
    res <- local_env$execute_tasks_parallel_mocked(tasks, function(x) x * 5)
    expect_equal(res, list(5, 10))
})
