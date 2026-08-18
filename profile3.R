library(microbenchmark)
library(data.table)
source("Updated_Seatek_Analysis.R")

cat("Profiling which() in compute_sensor_metrics\n")
# Create dummy vector
set.seed(123)
v <- runif(1000)
v[sample(1:1000, 100)] <- NA
v[sample(1:1000, 100)] <- -1

print(microbenchmark(
  mean.default(v[which(v > 0)]),
  mean.default(v[v > 0 & !is.na(v)]),
  {
      if (anyNA(v)) v_clean <- v[!is.na(v)] else v_clean <- v
      mean.default(v_clean[v_clean > 0])
  },
  times = 1000
))
