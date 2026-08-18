library(data.table)
library(microbenchmark)
source("Updated_Seatek_Analysis.R")

cat("Profiling which() vs .subset2 assignment\n")

df <- data.table(matrix(runif(1000 * 32), ncol = 32))
names(df) <- sprintf("Sensor%02d", 1:32)
df[sample(1:(1000*32), 1000)] <- NA

v_first_base <- numeric(32)
v_first_opt <- numeric(32)

idx_first <- 1:10

test_base <- function() {
    for (j in 1:32) {
        v <- .subset2(df, names(df)[j])
        v_first <- v[idx_first]
        v_first_base[j] <- mean.default(v_first[which(v_first > 0)])
    }
}

test_opt <- function() {
    for (j in 1:32) {
        v <- .subset2(df, names(df)[j])
        v_first <- v[idx_first]
        if (anyNA(v_first)) v_first <- v_first[!is.na(v_first)]
        v_first_opt[j] <- mean.default(v_first[v_first > 0])
    }
}

print(microbenchmark(
    test_base(),
    test_opt(),
    times = 10000
))
