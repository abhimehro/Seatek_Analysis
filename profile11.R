library(microbenchmark)

test_which_base <- function(n, na_frac, neg_frac) {
    v <- runif(n)
    v[sample(1:n, n * na_frac)] <- NA
    v[sample(1:n, n * neg_frac)] <- -1

    microbenchmark(
        which = mean.default(v[which(v > 0)]),
        anyNA = {
            if (anyNA(v)) v_clean <- v[!is.na(v)] else v_clean <- v
            mean.default(v_clean[v_clean > 0])
        },
        times = 1000
    )
}

print("Small array (n=10)")
print(test_which_base(10, 0.2, 0.2))

print("Medium array (n=1000)")
print(test_which_base(1000, 0.2, 0.2))

print("No NA array (n=1000)")
print(test_which_base(1000, 0, 0.2))
