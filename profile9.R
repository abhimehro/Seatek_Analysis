library(microbenchmark)

v_first <- runif(10)
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
