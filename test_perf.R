library(microbenchmark)
num_ts <- as.numeric(Sys.time()) + 1:100000

mb <- microbenchmark(
  as_posixct = as.POSIXct(num_ts, origin = "1970-01-01", tz = "UTC"),
  dot_posixct = .POSIXct(num_ts, tz = "UTC"),
  times = 100
)
print(mb)
