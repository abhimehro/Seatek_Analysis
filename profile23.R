library(data.table)
library(microbenchmark)

v <- runif(100)
v[1:5] <- NA
v[6:10] <- -1

print(microbenchmark(
    base = mean.default(v[which(v > 0)]),
    opt = {
        if (anyNA(v)) v_clean <- v[!is.na(v)] else v_clean <- v
        mean.default(v_clean[v_clean > 0])
    },
    times = 100000
))
