library(data.table)
library(microbenchmark)
source("Updated_Seatek_Analysis.R")

test_base <- function(n_rows, n_years) {
    dir.create("test_data2", showWarnings = FALSE)
    files <- list.files("test_data2", pattern = "^SS_Y[0-9]{2}\\.txt$", full.names = TRUE)

    dts <- lapply(files, function(f) read_sensor_data(f, verbose = FALSE))
    names(dts) <- files

    read_sensor_data_opt <- function(file_path,
                             sep = " ",
                             verbose = FALSE) {
      file_path <- normalizePath(file_path)
      validate_sensor_file(file_path)

      dt <- tryCatch(
        fread(file_path,
          header = FALSE, sep = sep, fill = TRUE,
          na.strings = c("NA")
        ),
        error = function(e) {
          stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
        }
      )
      total_cols <- ncol(dt)
      sensor_cols <- min(total_cols - 1, 32)
      setnames(dt, 1:sensor_cols, sprintf("Sensor%02d", 1:sensor_cols))
      if (total_cols >= sensor_cols + 1) {
        setnames(dt, sensor_cols + 1, "Timestamp")
      }
      cols_to_keep <- c(
        sprintf("Sensor%02d", 1:sensor_cols),
        "Timestamp"
      )
      cols_to_drop <- setdiff(names(dt), cols_to_keep)
      if (length(cols_to_drop) > 0) {
        set(dt, j = cols_to_drop, value = NULL)
      }
      ts_col <- .subset2(dt, "Timestamp")
      if (!inherits(ts_col, "POSIXct")) {
        if (is.numeric(ts_col)) {
          num_ts <- ts_col
        } else {
          num_ts <- suppressWarnings(as.numeric(ts_col))
        }
        if (!anyNA(num_ts)) {
          # ⚡ Bolt: .POSIXct is ~100x faster than as.POSIXct with origin
          set(dt, j = "Timestamp", value = .POSIXct(num_ts, tz = "UTC")) # nolint: object_name_linter
        }
      }
      dt
    }

    microbenchmark(
        base = lapply(files, function(f) read_sensor_data(f, verbose = FALSE)),
        opt = lapply(files, function(f) read_sensor_data_opt(f, verbose = FALSE)),
        times = 100
    )
}

print("Profiling compute metrics")
print(test_base(1000, 20))
