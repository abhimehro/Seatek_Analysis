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
metrics <- setdiff(names(all_stats_dt), c("Sensor", "Year"))


calc_stats1 <- function(v_val) {
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

calc_stats2 <- function(v_val) {
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
      mean      = mean.default(v_val),
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

test_lapply1 <- function() {
    all_stats_dt[,
    unlist(
      unname(lapply(.SD, calc_stats1)),
      recursive = FALSE,
      use.names = FALSE
    ),
    keyby = "Sensor", .SDcols = metrics
  ]
}

test_lapply2 <- function() {
    all_stats_dt[,
    unlist(
      unname(lapply(.SD, calc_stats2)),
      recursive = FALSE,
      use.names = FALSE
    ),
    keyby = "Sensor", .SDcols = metrics
  ]
}

print(microbenchmark(
  test_lapply1(),
  test_lapply2(),
  times = 100
))
