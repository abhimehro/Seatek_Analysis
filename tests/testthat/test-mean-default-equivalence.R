# Equivalence evidence for the mean() -> mean.default() edit in PR 749.
#
# Commit 81fcf93 changed calc_stats to call mean.default(v_val). PR head
# a38d4ac reverted that line while fixing a workflow file, so this tree
# still calls mean(v_val). The tests below run the real calc_stats body
# both ways, and the direct mean() / mean.default() call, on the same
# inputs. mean.default() does not dispatch S3 methods; that is the risk.

library(testthat)

find_analysis_source <- function() {
  candidates <- c(
    "Updated_Seatek_Analysis.R",
    file.path("..", "..", "Updated_Seatek_Analysis.R")
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit) < 1L) {
    stop("Updated_Seatek_Analysis.R not found from ", getwd())
  }
  normalizePath(hit[[1L]], winslash = "/", mustWork = TRUE)
}

count_token <- function(text, token) {
  vapply(text, function(line) {
    mm <- gregexpr(token, line, perl = TRUE)[[1]]
    if (mm[[1]] == -1L) 0L else length(mm)
  }, 1L, USE.NAMES = FALSE)
}

analysis_lines <- function() {
  readLines(find_analysis_source(), warn = FALSE)
}

# Pull the nested calc_stats out of the source so the comparison cannot
# drift from the function the PR actually edits.
extract_calc_stats <- function(use_mean_default) {
  lines <- analysis_lines()
  start <- which(grepl(
    "^  calc_stats <- function\\(v_val\\) \\{",
    lines
  ))
  if (length(start) != 1L) {
    stop("Expected exactly one calc_stats definition, found ", length(start))
  }
  depth <- 0L
  end <- NA_integer_
  for (i in start:length(lines)) {
    depth <- depth + count_token(lines[[i]], "\\{") -
      count_token(lines[[i]], "\\}")
    if (i > start && depth == 0L) {
      end <- i
      break
    }
  }
  if (is.na(end)) {
    stop("Could not find the end of calc_stats")
  }
  chunk <- lines[start:end]
  mean_idx <- grep("mean      = mean(v_val)", chunk, fixed = TRUE)
  if (length(mean_idx) != 1L) {
    stop("Expected one mean(v_val) assignment inside calc_stats")
  }
  if (use_mean_default) {
    chunk[mean_idx] <- sub(
      "mean(v_val)",
      "mean.default(v_val)",
      chunk[mean_idx],
      fixed = TRUE
    )
  }
  env <- new.env(parent = globalenv())
  eval(parse(text = chunk), envir = env)
  env$calc_stats
}

# Record value, error text, and warning text. identical() on this list is
# the equivalence check: a dropped warning or a changed class fails it.
capture_call <- function(fn) {
  warnings <- character()
  out <- withCallingHandlers(
    tryCatch(
      list(ok = TRUE, value = fn(), error = NA_character_),
      error = function(e) {
        list(ok = FALSE, value = NULL, error = conditionMessage(e))
      }
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  out$warnings <- warnings
  out
}

# UseMethod walks from the caller of mean() up to globalenv. A binding
# that exists only inside test_that() is invisible to calc_stats.
register_probe_mean <- function() {
  assign(
    "mean.seatek_probe",
    function(x, ...) structure(999, class = "seatek_probe_result"),
    envir = globalenv()
  )
  assign(
    "mean.seatek_child",
    function(x, ...) structure(111, class = "seatek_child_result"),
    envir = globalenv()
  )
}

unregister_probe_mean <- function() {
  rm(list = c("mean.seatek_probe", "mean.seatek_child"), envir = globalenv())
}

load_summary_variants <- function() {
  lines <- analysis_lines()
  hits <- grep("mean      = mean(v_val)", lines, fixed = TRUE)
  if (length(hits) != 1L) {
    stop("Expected one calc_stats mean assignment in the source file")
  }
  load_one <- function(use_mean_default) {
    variant <- lines
    if (use_mean_default) {
      variant[hits] <- "        mean      = mean.default(v_val),"
    }
    src <- tempfile(fileext = ".R")
    on.exit(unlink(src), add = TRUE)
    writeLines(variant, src)
    env <- new.env(parent = globalenv())
    # The script only defines functions when sourced (sys.nframe() > 0).
    suppressPackageStartupMessages(
      suppressMessages(sys.source(src, envir = env))
    )
    env$calculate_summary_stats
  }
  list(old = load_one(FALSE), new = load_one(TRUE))
}

test_that("PR head calc_stats still calls mean(), not mean.default()", {
  lines <- analysis_lines()
  calc_start <- which(grepl(
    "^  calc_stats <- function\\(v_val\\) \\{",
    lines
  ))
  expect_length(calc_start, 1L)
  # The assignment is the line the PR commit added and the head commit
  # removed. Other mean.default() calls already exist in compute_sensor_metrics.
  expect_true(any(grepl(
    "mean      = mean(v_val)",
    lines,
    fixed = TRUE
  )))
  expect_false(any(grepl("mean.default(v_val)", lines, fixed = TRUE)))
  call_line <- lines[grep("mean      = mean(v_val)", lines, fixed = TRUE)]
  expect_length(call_line, 1L)
  expect_false(grepl("trim", call_line, fixed = TRUE))
  expect_false(grepl("na.rm", call_line, fixed = TRUE))
})

test_that("extracted calc_stats bodies differ only by the mean call", {
  old_fn <- extract_calc_stats(FALSE)
  new_fn <- extract_calc_stats(TRUE)
  old_body <- paste(deparse(old_fn), collapse = "\n")
  new_body <- paste(deparse(new_fn), collapse = "\n")
  expect_true(grepl("mean(v_val)", old_body, fixed = TRUE))
  expect_false(grepl("mean.default", old_body, fixed = TRUE))
  expect_true(grepl("mean.default(v_val)", new_body, fixed = TRUE))
  swapped <- sub("mean.default(v_val)", "mean(v_val)", new_body, fixed = TRUE)
  expect_identical(swapped, old_body)
})

test_that("mean.default matches mean for plain numeric, integer, and logical vectors", {
  cases <- list(
    list("normal numeric", c(1.5, 2.5, 3.5, 10), 4.375),
    list("length-1 double", 4.2, 4.2),
    list("length-1 integer", 4L, 4),
    list("integer vector", 1:4, 2.5),
    list("double vector", as.numeric(1:4), 2.5),
    list("logical vector", c(TRUE, FALSE, TRUE, TRUE), 0.75),
    list(
      "data.frame column",
      data.frame(a = c(1, 2, 3, 4))[["a"]],
      2.5
    ),
    list(
      "data.table column",
      data.table::data.table(a = c(1, 2, 3, 4))[["a"]],
      2.5
    )
  )
  for (case in cases) {
    old <- capture_call(function() mean(case[[2]]))
    new <- capture_call(function() mean.default(case[[2]]))
    expect_true(old$ok, info = case[[1]])
    expect_identical(old$warnings, character(), info = case[[1]])
    expect_identical(new, old, info = case[[1]])
    expect_identical(old$value, case[[3]], info = case[[1]])
  }
})

test_that("NA, NaN, Inf, and empty vectors match, including na.rm", {
  na_vec <- c(1, NA, 3)
  expect_identical(
    capture_call(function() mean.default(na_vec, na.rm = FALSE)),
    capture_call(function() mean(na_vec, na.rm = FALSE))
  )
  expect_identical(mean(na_vec, na.rm = FALSE), NA_real_)
  expect_identical(mean(na_vec, na.rm = TRUE), 2)
  expect_identical(
    mean.default(na_vec, na.rm = TRUE),
    mean(na_vec, na.rm = TRUE)
  )

  nan_vec <- c(1, NaN, 3)
  nan_old <- capture_call(function() mean(nan_vec))
  nan_new <- capture_call(function() mean.default(nan_vec))
  expect_identical(nan_new, nan_old)
  expect_true(is.nan(nan_old$value))
  expect_identical(mean(nan_vec, na.rm = TRUE), 2)
  expect_identical(mean.default(nan_vec, na.rm = TRUE), 2)

  expect_identical(mean(c(1, Inf, 3)), Inf)
  expect_identical(mean.default(c(1, Inf, 3)), Inf)
  expect_identical(mean(c(1, -Inf, 3)), -Inf)
  expect_identical(mean.default(c(1, -Inf, 3)), -Inf)
  expect_true(is.nan(mean(c(Inf, -Inf))))
  expect_identical(mean.default(c(Inf, -Inf)), mean(c(Inf, -Inf)))
  expect_identical(mean(c(Inf, Inf)), Inf)
  expect_identical(mean.default(c(-Inf, -Inf)), -Inf)

  # calc_stats drops NA and NaN before the mean call and never passes na.rm.
  # Empty input returns the sentinel list and does not call mean at all.
  old_fn <- extract_calc_stats(FALSE)
  new_fn <- extract_calc_stats(TRUE)
  expect_identical(new_fn(na_vec), old_fn(na_vec))
  # NA is removed before mean(), so c(1, NA, 3) is summarized as c(1, 3).
  expect_identical(old_fn(na_vec)$mean, 2)
  expect_identical(old_fn(na_vec)$count, 2L)
  expect_identical(new_fn(nan_vec), old_fn(nan_vec))
  expect_identical(old_fn(nan_vec)$mean, 2)
  expect_identical(new_fn(c(NA_real_, NA_real_)), old_fn(c(NA_real_, NA_real_)))
  expect_identical(old_fn(c(NA_real_, NA_real_))$mean, NA_real_)
  expect_identical(old_fn(c(NA_real_, NA_real_))$count, 0L)
  expect_identical(new_fn(c(NaN, NaN)), old_fn(c(NaN, NaN)))
  expect_identical(old_fn(c(NaN, NaN))$count, 0L)
  expect_identical(new_fn(c(1, Inf, 3)), old_fn(c(1, Inf, 3)))
  expect_identical(old_fn(c(1, Inf, 3))$mean, Inf)
  expect_identical(new_fn(c(Inf, -Inf)), old_fn(c(Inf, -Inf)))
  expect_true(is.nan(old_fn(c(Inf, -Inf))$mean))

  for (empty in list(numeric(0), integer(0), logical(0))) {
    direct_old <- capture_call(function() mean(empty))
    direct_new <- capture_call(function() mean.default(empty))
    expect_identical(direct_new, direct_old)
    expect_true(is.nan(direct_old$value))
    expect_identical(direct_old$warnings, character())
    expect_identical(new_fn(empty), old_fn(empty))
    expect_identical(old_fn(empty)$mean, NA_real_)
    expect_identical(old_fn(empty)$count, 0L)
  }
})

test_that("trim is not used by calc_stats, and the same trim matches", {
  # Documented because the PR swaps the function that owns `trim`.
  # The call site passes no trim, so only the default (0) is live.
  x <- c(1, 2, 3, 4, 100)
  expect_identical(mean(x, trim = 0), 22)
  expect_identical(mean.default(x, trim = 0), 22)
  expect_identical(mean(x, trim = 0.2), 3)
  expect_identical(mean.default(x, trim = 0.2), mean(x, trim = 0.2))
  expect_identical(mean(x, trim = 0.5), 3)
  expect_identical(mean.default(x, trim = 0.5), mean(x, trim = 0.5))
  expect_identical(mean.default(1:10, trim = 0.2), mean(1:10, trim = 0.2))
  expect_identical(mean(1:10, trim = 0.2), 5.5)
})

test_that("factor, character, and a whole data.frame hit the same default", {
  # No mean.factor or mean.data.frame method exists. UseMethod falls
  # through to mean.default, so the two calls agree: warning and NA.
  factor_x <- factor(c("a", "b", "a", "c"))
  character_x <- c("a", "b", "a")
  frame_x <- data.frame(a = c(1, 2, 3, 4))
  for (x in list(factor_x, character_x, frame_x)) {
    old <- capture_call(function() mean(x))
    new <- capture_call(function() mean.default(x))
    expect_identical(new, old)
    expect_true(old$ok)
    expect_identical(old$value, NA_real_)
    expect_true(any(grepl(
      "argument is not numeric or logical: returning NA",
      old$warnings,
      fixed = TRUE
    )))
  }

  old_fn <- extract_calc_stats(FALSE)
  new_fn <- extract_calc_stats(TRUE)
  # median() rejects factors and data.frames before mean() runs.
  factor_old <- capture_call(function() old_fn(factor_x))
  factor_new <- capture_call(function() new_fn(factor_x))
  expect_identical(factor_new, factor_old)
  expect_false(factor_old$ok)
  expect_identical(factor_old$error, "need numeric data")

  frame_old <- capture_call(function() old_fn(frame_x))
  frame_new <- capture_call(function() new_fn(frame_x))
  expect_identical(frame_new, frame_old)
  expect_identical(frame_old$error, "need numeric data")

  # Character reaches mean(), warns, then fails later in the same list().
  char_old <- capture_call(function() old_fn(character_x))
  char_new <- capture_call(function() new_fn(character_x))
  expect_identical(char_new, char_old)
  expect_false(char_old$ok)
  expect_identical(char_old$error, "non-numeric argument to binary operator")
  expect_true(any(grepl(
    "argument is not numeric or logical: returning NA",
    char_old$warnings,
    fixed = TRUE
  )))
})

test_that("a class with its own mean method is not equivalent", {
  register_probe_mean()
  on.exit(unregister_probe_mean(), add = TRUE)

  own <- structure(c(10, 20, 30), class = "seatek_probe")
  # The object stays numeric, so mean.default() does not warn. It skips
  # the method and returns the arithmetic mean.
  expect_true(is.numeric(own))
  old <- capture_call(function() mean(own))
  new <- capture_call(function() mean.default(own))
  expect_identical(old$value, structure(999, class = "seatek_probe_result"))
  expect_identical(old$warnings, character())
  expect_identical(new$value, 20)
  expect_identical(new$warnings, character())
  expect_false(identical(old, new))

  # The child class has its own method. mean.default() still ignores it.
  child <- structure(c(10, 20, 30), class = "seatek_child")
  child_old <- capture_call(function() mean(child))
  child_new <- capture_call(function() mean.default(child))
  expect_identical(
    child_old$value,
    structure(111, class = "seatek_child_result")
  )
  expect_identical(child_new$value, 20)
  expect_false(identical(child_old, child_new))

  inherited <- structure(
    c(10, 20, 30),
    class = c("seatek_child", "seatek_probe")
  )
  inh_old <- capture_call(function() mean(inherited))
  inh_new <- capture_call(function() mean.default(inherited))
  # The child method is found first. mean.default() does not walk the class.
  expect_identical(
    inh_old$value,
    structure(111, class = "seatek_child_result")
  )
  expect_identical(inh_new$value, 20)

  # No method registered: both calls use the numeric default.
  plain <- structure(c(10, 20, 30), class = "seatek_plain")
  expect_identical(
    capture_call(function() mean.default(plain)),
    capture_call(function() mean(plain))
  )
  expect_identical(mean(plain), 20)

  old_fn <- extract_calc_stats(FALSE)
  new_fn <- extract_calc_stats(TRUE)
  old_stats <- capture_call(function() old_fn(own))
  new_stats <- capture_call(function() new_fn(own))
  expect_true(old_stats$ok)
  expect_true(new_stats$ok)
  expect_identical(old_stats$warnings, character())
  expect_identical(new_stats$warnings, character())
  expect_identical(
    old_stats$value$mean,
    structure(999, class = "seatek_probe_result")
  )
  expect_identical(new_stats$value$mean, 20)
  old_rest <- old_stats$value
  new_rest <- new_stats$value
  old_rest$mean <- NULL
  new_rest$mean <- NULL
  expect_identical(new_rest, old_rest)
  expect_identical(old_rest$sd, 10)
  expect_identical(old_rest$count, 3L)
})

test_that("Date, POSIXct, and difftime means are not equivalent", {
  not_numeric_warning <- "argument is not numeric or logical: returning NA"

  date_x <- as.Date("2020-01-01") + 0:2
  date_old <- capture_call(function() mean(date_x))
  date_new <- capture_call(function() mean.default(date_x))
  expect_identical(date_old$value, as.Date("2020-01-02"))
  expect_identical(date_old$warnings, character())
  expect_identical(date_new$value, NA_real_)
  expect_true(any(grepl(not_numeric_warning, date_new$warnings, fixed = TRUE)))

  date_na <- c(as.Date("2020-01-01"), as.Date(NA), as.Date("2020-01-03"))
  expect_identical(mean(date_na, na.rm = TRUE), as.Date("2020-01-02"))
  date_na_new <- capture_call(function() mean.default(date_na, na.rm = TRUE))
  expect_identical(date_na_new$value, NA_real_)
  expect_true(any(grepl(
    not_numeric_warning,
    date_na_new$warnings,
    fixed = TRUE
  )))

  posix_x <- as.POSIXct(
    c("2020-01-01 00:00:00", "2020-01-03 00:00:00", "2020-01-05 00:00:00"),
    tz = "UTC"
  )
  posix_old <- capture_call(function() mean(posix_x))
  posix_new <- capture_call(function() mean.default(posix_x))
  expect_identical(
    posix_old$value,
    as.POSIXct("2020-01-03 00:00:00", tz = "UTC")
  )
  expect_identical(posix_new$value, NA_real_)
  expect_true(any(grepl(not_numeric_warning, posix_new$warnings, fixed = TRUE)))

  diff_x <- as.difftime(c(1, 3, 5), units = "secs")
  diff_old <- capture_call(function() mean(diff_x))
  diff_new <- capture_call(function() mean.default(diff_x))
  expect_identical(diff_old$value, as.difftime(3, units = "secs"))
  expect_identical(diff_new$value, NA_real_)
  expect_true(any(grepl(not_numeric_warning, diff_new$warnings, fixed = TRUE)))

  old_fn <- extract_calc_stats(FALSE)
  new_fn <- extract_calc_stats(TRUE)

  # Length 1 never reaches rollmean3's sum(), so the mean difference is returned.
  one_date <- as.Date("2020-01-15")
  one_old <- capture_call(function() old_fn(one_date))
  one_new <- capture_call(function() new_fn(one_date))
  expect_true(one_old$ok)
  expect_true(one_new$ok)
  expect_identical(one_old$value$mean, as.Date("2020-01-15"))
  expect_identical(one_old$warnings, character())
  expect_identical(one_new$value$mean, NA_real_)
  expect_true(any(grepl(not_numeric_warning, one_new$warnings, fixed = TRUE)))

  one_posix <- as.POSIXct("2020-01-03 00:00:00", tz = "UTC")
  posix1_old <- capture_call(function() old_fn(one_posix))
  posix1_new <- capture_call(function() new_fn(one_posix))
  expect_identical(posix1_old$value$mean, one_posix)
  expect_identical(posix1_new$value$mean, NA_real_)
  expect_true(any(grepl(
    not_numeric_warning,
    posix1_new$warnings,
    fixed = TRUE
  )))

  # Length >= 3 evaluates sum() for rollmean3. Date and POSIXct error there.
  # The new path still emits the mean.default warning before that error.
  date_long_old <- capture_call(function() old_fn(date_x))
  date_long_new <- capture_call(function() new_fn(date_x))
  expect_false(date_long_old$ok)
  expect_false(date_long_new$ok)
  expect_identical(date_long_old$error, date_long_new$error)
  expect_identical(date_long_old$error, "sum not defined for \"Date\" objects")
  expect_identical(date_long_old$warnings, character())
  expect_true(any(grepl(
    not_numeric_warning,
    date_long_new$warnings,
    fixed = TRUE
  )))

  posix_long_old <- capture_call(function() old_fn(posix_x))
  posix_long_new <- capture_call(function() new_fn(posix_x))
  expect_identical(posix_long_old$error, posix_long_new$error)
  expect_identical(
    posix_long_old$error,
    "'sum' not defined for \"POSIXt\" objects"
  )
  expect_identical(posix_long_old$warnings, character())
  expect_true(any(grepl(
    not_numeric_warning,
    posix_long_new$warnings,
    fixed = TRUE
  )))

  # difftime has sum() and sd(), so calc_stats returns. Only the mean changes.
  diff_stats_old <- capture_call(function() old_fn(diff_x))
  diff_stats_new <- capture_call(function() new_fn(diff_x))
  expect_true(diff_stats_old$ok)
  expect_true(diff_stats_new$ok)
  expect_identical(diff_stats_old$warnings, character())
  expect_identical(
    diff_stats_old$value$mean,
    as.difftime(3, units = "secs")
  )
  expect_identical(diff_stats_new$value$mean, NA_real_)
  expect_true(any(grepl(
    not_numeric_warning,
    diff_stats_new$warnings,
    fixed = TRUE
  )))
  diff_old_rest <- diff_stats_old$value
  diff_new_rest <- diff_stats_new$value
  diff_old_rest$mean <- NULL
  diff_new_rest$mean <- NULL
  expect_identical(diff_new_rest, diff_old_rest)
})

test_that("calculate_summary_stats matches on pipeline numeric columns", {
  variants <- load_summary_variants()
  results <- list(
    "1995" = data.table::data.table(
      Sensor = c("S1", "S2"),
      first10 = c(1, NA_real_),
      last5 = c(5, 6),
      full = c(10, 11),
      within_diff = c(9, NA_real_)
    ),
    "1996" = data.table::data.table(
      Sensor = c("S1", "S2"),
      first10 = c(3, 4),
      last5 = c(7, 8),
      full = c(12, 13),
      within_diff = c(9, 9)
    )
  )
  old <- capture_call(function() variants$old(results))
  new <- capture_call(function() variants$new(results))
  expect_true(old$ok)
  expect_identical(new, old)
  # Known values, so identical-to-each-other cannot hide a shared wrong mean.
  # S2 first10 drops the NA and keeps 4. S1 first10 is mean(c(1, 3)).
  s1 <- old$value[Sensor == "S1"]
  s2 <- old$value[Sensor == "S2"]
  expect_identical(s1$first10_mean, 2)
  expect_identical(s2$first10_mean, 4)
  expect_identical(s1$full_mean, 11)
  expect_identical(s2$full_mean, 12)
  expect_identical(s1$within_diff_mean, 9)
  expect_identical(s2$within_diff_mean, 9)
  expect_identical(s2$first10_count, 1L)
  expect_identical(s1$full_pct_nonmissing, 100)

  integer_results <- list(
    "1995" = data.table::data.table(Sensor = "S1", metric = 1L),
    "1996" = data.table::data.table(Sensor = "S1", metric = 3L)
  )
  int_old <- capture_call(function() variants$old(integer_results))
  int_new <- capture_call(function() variants$new(integer_results))
  expect_identical(int_new, int_old)
  expect_identical(int_old$value$metric_mean, 2)

  logical_results <- list(
    "1995" = data.table::data.table(Sensor = "S1", metric = TRUE),
    "1996" = data.table::data.table(Sensor = "S1", metric = FALSE)
  )
  log_old <- capture_call(function() variants$old(logical_results))
  log_new <- capture_call(function() variants$new(logical_results))
  expect_identical(log_new, log_old)
  expect_identical(log_old$value$metric_mean, 0.5)
})

test_that("calculate_summary_stats changes when a column has a mean method", {
  register_probe_mean()
  on.exit(unregister_probe_mean(), add = TRUE)
  variants <- load_summary_variants()
  results <- list(
    "1995" = data.table::data.table(
      Sensor = c("S1", "S2"),
      metric = structure(c(10, 30), class = "seatek_probe")
    ),
    "1996" = data.table::data.table(
      Sensor = c("S1", "S2"),
      metric = structure(c(20, 40), class = "seatek_probe")
    )
  )
  # data.table keeps the class through rbindlist, so the method is reachable
  # from the public summary function, not only from a direct mean() call.
  combined <- data.table::rbindlist(results, idcol = "Year")
  expect_identical(class(combined$metric), "seatek_probe")

  old <- capture_call(function() variants$old(results))
  new <- capture_call(function() variants$new(results))
  expect_true(old$ok)
  expect_true(new$ok)
  expect_identical(old$warnings, character())
  expect_identical(new$warnings, character())
  expect_identical(
    old$value$metric_mean,
    structure(c(999, 999), class = "seatek_probe_result")
  )
  expect_identical(new$value$metric_mean, c(15, 35))
  expect_false(identical(old$value, new$value))
})

test_that("calculate_summary_stats changes Date and difftime columns", {
  variants <- load_summary_variants()
  not_numeric_warning <- "argument is not numeric or logical: returning NA"

  date_results <- list(
    "1995" = data.table::data.table(
      Sensor = "S1",
      metric = as.Date("2020-01-15")
    )
  )
  date_old <- capture_call(function() variants$old(date_results))
  date_new <- capture_call(function() variants$new(date_results))
  expect_true(date_old$ok)
  expect_true(date_new$ok)
  expect_identical(date_old$value$metric_mean, as.Date("2020-01-15"))
  expect_identical(date_old$warnings, character())
  expect_identical(date_new$value$metric_mean, NA_real_)
  expect_true(any(grepl(
    not_numeric_warning,
    date_new$warnings,
    fixed = TRUE
  )))

  diff_results <- list(
    "1995" = data.table::data.table(
      Sensor = "S1",
      metric = as.difftime(1, units = "secs")
    ),
    "1996" = data.table::data.table(
      Sensor = "S1",
      metric = as.difftime(5, units = "secs")
    )
  )
  diff_old <- capture_call(function() variants$old(diff_results))
  diff_new <- capture_call(function() variants$new(diff_results))
  expect_true(diff_old$ok)
  expect_true(diff_new$ok)
  expect_identical(diff_old$value$metric_mean, as.difftime(3, units = "secs"))
  expect_identical(diff_new$value$metric_mean, NA_real_)
  expect_identical(diff_old$warnings, character())
  expect_true(any(grepl(
    not_numeric_warning,
    diff_new$warnings,
    fixed = TRUE
  )))

  posix_results <- list(
    "1995" = data.table::data.table(
      Sensor = "S1",
      metric = as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
    ),
    "1996" = data.table::data.table(
      Sensor = "S1",
      metric = as.POSIXct("2020-01-05 00:00:00", tz = "UTC")
    )
  )
  posix_old <- capture_call(function() variants$old(posix_results))
  posix_new <- capture_call(function() variants$new(posix_results))
  expect_true(posix_old$ok)
  expect_identical(
    posix_old$value$metric_mean,
    as.POSIXct("2020-01-03 00:00:00", tz = "UTC")
  )
  expect_identical(posix_new$value$metric_mean, NA_real_)
  expect_true(any(grepl(
    not_numeric_warning,
    posix_new$warnings,
    fixed = TRUE
  )))
})
