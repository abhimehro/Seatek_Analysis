library(microbenchmark)
library(data.table)

# Create dummy data with Sensor
res <- lapply(1:20, function(i) {
  dt <- data.table(
    Sensor = sprintf("Sensor%02d", 1:32),
    first10 = runif(32),
    last5 = runif(32),
    full = runif(32),
    within_diff = runif(32)
  )
  dt
})

all_stats_dt <- rbindlist(res, idcol = "Year")

calc_stats <- function(v_val) {
  if (anyNA(v_val)) v_val <- v_val[!is.na(v_val)]
  n <- length(v_val)
  if (n == 0) {
    list(
      mean = NA_real_, sd = NA_real_, median = NA_real_, mad = NA_real_,
      min = NA_real_, max = NA_real_, count = 0L, rollmean3 = NA_real_
    )
  } else {
    med <- median(v_val)
    list(
      mean      = mean(v_val),
      sd        = sd(v_val),
      median    = med,
      mad       = mad(v_val, center = med),
      min       = min(v_val),
      max       = max(v_val),
      count     = n,
      rollmean3 = if (n < 3) NA_real_ else sum(v_val[(n - 2):n]) / 3
    )
  }
}

metrics <- setdiff(names(all_stats_dt), c("Sensor", "Year"))

test_lapply <- function() {
    all_stats_dt[,
    unlist(
      unname(lapply(.SD, calc_stats)),
      recursive = FALSE,
      use.names = FALSE
    ),
    keyby = "Sensor", .SDcols = metrics
  ]
}


test_direct <- function() {
    all_stats_dt[, .(
      first10_mean = mean.default(first10),
      first10_sd = sd(first10),
      first10_median = median(first10),
      first10_mad = mad(first10, center = median(first10)),
      first10_min = min(first10),
      first10_max = max(first10),
      first10_count = .N,
      first10_rollmean3 = if (.N < 3) NA_real_ else sum(first10[(.N - 2):.N]) / 3,

      last5_mean = mean.default(last5),
      last5_sd = sd(last5),
      last5_median = median(last5),
      last5_mad = mad(last5, center = median(last5)),
      last5_min = min(last5),
      last5_max = max(last5),
      last5_count = .N,
      last5_rollmean3 = if (.N < 3) NA_real_ else sum(last5[(.N - 2):.N]) / 3,

      full_mean = mean.default(full),
      full_sd = sd(full),
      full_median = median(full),
      full_mad = mad(full, center = median(full)),
      full_min = min(full),
      full_max = max(full),
      full_count = .N,
      full_rollmean3 = if (.N < 3) NA_real_ else sum(full[(.N - 2):.N]) / 3,

      within_diff_mean = mean.default(within_diff),
      within_diff_sd = sd(within_diff),
      within_diff_median = median(within_diff),
      within_diff_mad = mad(within_diff, center = median(within_diff)),
      within_diff_min = min(within_diff),
      within_diff_max = max(within_diff),
      within_diff_count = .N,
      within_diff_rollmean3 = if (.N < 3) NA_real_ else sum(within_diff[(.N - 2):.N]) / 3
    ), keyby = "Sensor"]
}


print(microbenchmark(
  test_lapply(),
  test_direct(),
  times = 100
))
