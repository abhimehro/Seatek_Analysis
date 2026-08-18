library(microbenchmark)
library(data.table)
source("Updated_Seatek_Analysis.R")

# Create a dummy sensor file
dir.create("test_data", showWarnings = FALSE)
dt <- data.table(matrix(runif(1000 * 33), ncol = 33))
fwrite(dt, "test_data/SS_Y01.txt", sep=" ", col.names=FALSE)

cat("Profiling read_sensor_data\n")
print(microbenchmark(
  res <- read_sensor_data("test_data/SS_Y01.txt", verbose = FALSE),
  times = 10
))

res <- read_sensor_data("test_data/SS_Y01.txt", verbose = FALSE)
cat("Profiling compute_sensor_metrics\n")
print(microbenchmark(
  compute_sensor_metrics(res, "test_data/SS_Y01.txt"),
  times = 100
))

res_metrics <- lapply(1:20, function(i) {
  dt_metrics <- compute_sensor_metrics(res, sprintf("test_data/SS_Y%02d.txt", i))
  dt_metrics
})

cat("Profiling calculate_summary_stats\n")
print(microbenchmark(
  calculate_summary_stats(res_metrics),
  times = 100
))
