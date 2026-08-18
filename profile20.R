library(microbenchmark)

num_ts <- 1600000000 + 1:1000

print(microbenchmark(
    as.POSIXct(num_ts, origin = "1970-01-01", tz = "UTC"),
    .POSIXct(num_ts, tz = "UTC"),
    times = 10000
))
