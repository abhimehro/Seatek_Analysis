library(microbenchmark)
library(data.table)
source("Updated_Seatek_Analysis.R")

cat("Testing calculate_summary_stats with data.table\n")
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

print(microbenchmark(
  calculate_summary_stats(res),
  times = 100
))
