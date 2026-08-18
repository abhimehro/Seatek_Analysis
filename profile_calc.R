library(microbenchmark)
library(data.table)
source("Updated_Seatek_Analysis.R")

cat("Testing calc_stats optimization\n")

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

calculate_summary_stats_optimized <- function(results) {
  all_stats_dt <- rbindlist(results, idcol = "Year")
  metrics <- setdiff(names(all_stats_dt), c("Sensor", "Year"))

  # OPTIMIZATION: Instead of using lapply(.SD, calc_stats) grouping by Sensor,
  # we can use matrix operations or direct column assignments which are faster
  # since we have fixed 32 sensors and 20 years.

  summary_wide <- all_stats_dt[, .(
      first10_mean = mean.default(first10),
      first10_sd = sd(first10),
      first10_median = median(first10),
      first10_mad = mad(first10, center = median(first10)),
      first10_min = min(first10),
      first10_max = max(first10),
      first10_count = .N,
      first10_rollmean3 = if (.N < 3) NA_real_ else sum(first10[(.N - 2):.N]) / 3
  ), keyby = Sensor]

  summary_wide # Implicit return
}

print(microbenchmark(
  calculate_summary_stats(res),
  # calculate_summary_stats_optimized(res), # just checking base for now
  times = 100
))
