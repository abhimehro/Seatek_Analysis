x <- rnorm(10000)
t1 <- Sys.time()
for (i in 1:1000) { sd(x) }
cat("sd(): ", Sys.time() - t1, "\n")

t2 <- Sys.time()
for (i in 1:1000) { sqrt(var(x)) }
cat("sqrt(var()): ", Sys.time() - t2, "\n")
