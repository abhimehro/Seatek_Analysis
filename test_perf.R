x <- rnorm(1000)
library(microbenchmark)
microbenchmark(
  sd(x),
  sqrt(var(x))
)
