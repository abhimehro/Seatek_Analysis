library(microbenchmark)
library(data.table)
source("Updated_Seatek_Analysis.R")

test_read_base <- function(n_rows, use_ts) {
    if (use_ts) {
        dt <- data.table(matrix(runif(n_rows * 32), ncol = 32), Timestamp = as.numeric(Sys.time()) + 1:n_rows)
    } else {
        dt <- data.table(matrix(runif(n_rows * 33), ncol = 33))
    }

    fwrite(dt, "test_data/SS_Y01.txt", sep=" ", col.names=FALSE)

    microbenchmark(
        read_sensor_data("test_data/SS_Y01.txt", verbose = FALSE),
        times = 100
    )
}

print("Read data with numeric timestamp")
print(test_read_base(1000, FALSE))
