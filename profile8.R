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

calc_stats3 <- function(v_val) {
  if (anyNA(v_val)) v_val <- v_val[!is.na(v_val)]
  n <- length(v_val)
  if (n == 0) {
    list(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, 0L, NA_real_)
  } else {
    med <- median(v_val)
    list(
      mean.default(v_val),
      sd(v_val),
      med,
      mad(v_val, center = med),
      min(v_val),
      max(v_val),
      n,
      if (n < 3) NA_real_ else sum(v_val[(n - 2):n]) / 3
    )
  }
}

metrics <- setdiff(names(all_stats_dt), c("Sensor", "Year"))

test_lapply3 <- function() {
    all_stats_dt[,
    unlist(
      lapply(.SD, calc_stats3),
      recursive = FALSE,
      use.names = FALSE
    ),
    keyby = "Sensor", .SDcols = metrics
  ]
}

print(microbenchmark(
  test_lapply3(),
  times = 100
))
