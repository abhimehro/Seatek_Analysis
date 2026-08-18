library(microbenchmark)
v <- runif(10000)

print(microbenchmark(
    mean.default(v[which(v > 0)]),
    mean.default(v[v > 0]),
    times = 10000
))
