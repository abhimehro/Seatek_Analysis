library(microbenchmark)
v_first <- runif(100)
v_first[v_first < 0.2] <- NA
v_first[v_first > 0.8] <- -1

print(microbenchmark(
    mean.default(v_first[which(v_first > 0)]),
    {
        v_clean <- v_first[!is.na(v_first)]
        mean.default(v_clean[v_clean > 0])
    },
    times = 10000
))
