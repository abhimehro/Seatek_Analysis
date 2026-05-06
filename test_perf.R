n <- 1000
start1 <- Sys.time()
for(i in 1:n) {
  for(j in 1:1000) {
    clean_vals <- function(x) x[which(x > 0)]
    clean_vals(rnorm(10))
  }
}
end1 <- Sys.time()
print(end1 - start1)

start2 <- Sys.time()
clean_vals2 <- function(x) x[which(x > 0)]
for(i in 1:n) {
  for(j in 1:1000) {
    clean_vals2(rnorm(10))
  }
}
end2 <- Sys.time()
print(end2 - start2)
