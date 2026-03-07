# Performance Benchmark: sapply vs data.table lapply(.SD)
#
# This script benchmarks the performance improvement of using data.table's
# native `lapply(.SD)` and row-subsetting compared to `sapply` with column
# slicing. The optimization avoids repeatedly slicing columns inside an M*N loop
# and creating intermediate subsets.
#
# NOTE: This is a manual performance benchmark script and not a unit/integration
# test. It is intended to be run explicitly (e.g. via Rscript) and should not be
# included in normal automated test or CI test suites.

# Load required packages
if (!requireNamespace("data.table", quietly = TRUE)) {
  stop(
    "The 'data.table' package is required to run this benchmark.\n",
    "Please install it before running this script, e.g.:\n",
    "  install.packages(\"data.table\")",
    call. = FALSE
  )
}
if (!requireNamespace("microbenchmark", quietly = TRUE)) {
  stop(
    "The 'microbenchmark' package is required to run this benchmark.\n",
    "Please install it before running this script, e.g.:\n",
    "  install.packages(\"microbenchmark\")",
    call. = FALSE
  )
}

library(data.table)
library(microbenchmark)

# Function to clean values (dropping NAs and values <= 0)
clean_vals <- function(x) x[which(x > 0)]

# Setup synthetic data.table with large number of rows
set.seed(42)
n_rows <- 500000
n_cols <- 32
sensor_names <- paste0("Sensor", sprintf("%02d", 1:n_cols))
df <- data.table(matrix(runif(n_rows * n_cols, -5, 15), nrow = n_rows))
setnames(df, sensor_names)

# Introduce some NAs and negatives to simulate real-world data
df[sample(1:(n_rows * n_cols), 100000)] <- NA
df[sample(1:(n_rows * n_cols), 100000)] <- -1

message(sprintf("Benchmarking with dataset size: %d rows x %d cols", n_rows, n_cols))

# Run the benchmark
mb <- microbenchmark(
  # Baseline: Using sapply with column slicing
  baseline_sapply = {
    first10 <- sapply(df[, ..sensor_names], function(x) mean(clean_vals(head(x, 10))))
    last5   <- sapply(df[, ..sensor_names], function(x) mean(clean_vals(tail(x, 5))))
    full    <- sapply(df[, ..sensor_names], function(x) mean(clean_vals(x)))
  },

  # Optimized: Using data.table native lapply(.SD)
  optimized_lapply_sd = {
    first10 <- unlist(df[1:min(10, .N), lapply(.SD, function(x) mean(clean_vals(x))), .SDcols = sensor_names])
    last5   <- unlist(df[max(1, .N - 4):.N, lapply(.SD, function(x) mean(clean_vals(x))), .SDcols = sensor_names])
    full    <- unlist(df[, lapply(.SD, function(x) mean(clean_vals(x))), .SDcols = sensor_names])
  },

  times = 10
)

print(mb)

# Calculate improvement
res <- summary(mb)
baseline_median <- res$median[res$expr == "baseline_sapply"]
optimized_median <- res$median[res$expr == "optimized_lapply_sd"]
speedup <- baseline_median / optimized_median

cat(sprintf("\n🚀 Performance Improvement:\n"))
cat(sprintf("  baseline_sapply:      %.2f ms (median)\n", baseline_median))
cat(sprintf("  optimized_lapply_sd:  %.2f ms (median)\n", optimized_median))
cat(sprintf("  Speedup:              %.2fx faster\n", speedup))
