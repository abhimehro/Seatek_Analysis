library(microbenchmark)
library(data.table)

summary_wide <- data.table(full_count = 1:1000)

print(microbenchmark(
    summary_wide$full_count,
    .subset2(summary_wide, "full_count"),
    times = 10000
))
