library(microbenchmark)

test_sub <- function() {
    filename <- "SS_Y01.txt"
    sub("^SS_Y([0-9]{2})\\.txt$", "\\1", filename)
}

test_substr <- function() {
    filename <- "SS_Y01.txt"
    substr(filename, 5, 6)
}

print(microbenchmark(
    test_sub(),
    test_substr(),
    times = 100000
))
