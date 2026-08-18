library(data.table)
library(microbenchmark)
source("Updated_Seatek_Analysis.R")

test_base <- function(n_rows, n_years) {
    dir.create("test_data2", showWarnings = FALSE)
    for (i in 1:n_years) {
        dt <- data.table(matrix(runif(n_rows * 32), ncol = 32), Timestamp = as.numeric(Sys.time()) + 1:n_rows)
        # Add some NAs and -1s to match real data profile
        for (col in names(dt)[1:32]) {
            dt[sample(1:n_rows, n_rows * 0.05), (col) := NA]
            dt[sample(1:n_rows, n_rows * 0.05), (col) := -1]
        }
        fwrite(dt, sprintf("test_data2/SS_Y%02d.txt", i), sep=" ", col.names=FALSE)
    }

    files <- list.files("test_data2", pattern = "^SS_Y[0-9]{2}\\.txt$", full.names = TRUE)

    microbenchmark(
        {
            results <- lapply(files, function(f) {
                dt <- read_sensor_data(f, verbose = FALSE)
                compute_sensor_metrics(dt, f)
            })
        },
        times = 10
    )
}

print("Profiling full processing loop")
print(test_base(1000, 20))
