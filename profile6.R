library(microbenchmark)

colnames_data <- sprintf("Sensor%02d", 1:32)
colnames_data <- c(colnames_data, "within_diff")

print(microbenchmark(
    "within_diff" %in% colnames_data,
    any(colnames_data == "within_diff"),
    match("within_diff", colnames_data, nomatch = 0L) > 0L,
    times = 10000
))
