if (!requireNamespace("data.table", quietly = TRUE)) {
  message("data.table is missing. Using substitute logic for testing")
} else {
  library(data.table)
  source("Updated_Seatek_Analysis.R")

  df <- data.table(
    Time = 1:15,
    Sensor1 = c(rep(10, 10), rep(20, 5)), # first10 = 10, last5 = 20, full = 13.33
    Sensor2 = c(rep(0, 10), rep(5, 5))    # clean_vals will drop 0s.
  )

  res <- compute_sensor_metrics(df, "SS_Y01.txt")
  print(res)
}
