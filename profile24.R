library(microbenchmark)
library(data.table)

# Is the which(v > 0) slow?
v_first <- runif(100)
v_first[v_first < 0.2] <- NA
v_first[v_first > 0.8] <- -1

print(microbenchmark(
    mean.default(v_first[which(v_first > 0)]),
    {
        if (anyNA(v_first)) v_first <- v_first[!is.na(v_first)]
        mean.default(v_first[v_first > 0])
    },
    times = 10000
))

# Test sub vs substr
filename <- "path/to/SS_Y05.txt"
base <- basename(filename)
print(microbenchmark(
    sub("^SS_Y([0-9]{2})\\.txt$", "\\1", base),
    substr(base, 5, 6),
    times = 10000
))

# test .POSIXct vs as.POSIXct
num_ts <- 1600000000 + 1:1000
print(microbenchmark(
    as.POSIXct(num_ts, origin = "1970-01-01", tz = "UTC"),
    .POSIXct(num_ts, tz = "UTC"),
    times = 10000
))
