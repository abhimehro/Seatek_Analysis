library(microbenchmark)

filename <- "path/to/SS_Y05.txt"
base <- basename(filename)

print(microbenchmark(
    regex = sub("^SS_Y([0-9]{2})\\.txt$", "\\1", base),
    substr = substr(base, 5, 6),
    times = 100000
))
