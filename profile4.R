library(microbenchmark)
library(data.table)

# Test data.table subset vs unquoted var
dt <- data.table(a = runif(10000), b = runif(10000))

print(microbenchmark(
    dt$a,
    dt[["a"]],
    .subset2(dt, "a"),
    times = 10000
))

# What about creating the return dt in compute_sensor_metrics?
first10 <- runif(32)
last5 <- runif(32)
full <- runif(32)
diff <- runif(32)
sensor_names <- sprintf("Sensor%02d", 1:32)

print(microbenchmark(
    data.table(
        Sensor = sensor_names,
        first10 = first10,
        last5 = last5,
        full = full,
        within_diff = diff
    ),
    times = 1000
))
