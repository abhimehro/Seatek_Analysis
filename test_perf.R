library(microbenchmark)
set.seed(123)
x <- rnorm(1000)
microbenchmark(
  sd = sd(x),
  sqrt_var = sqrt(var(x)),
  times = 1000
)
