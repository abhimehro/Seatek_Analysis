library(data.table)
library(microbenchmark)
source("Updated_Seatek_Analysis.R")

test_base <- function(n_rows, n_years) {
    dir.create("test_data2", showWarnings = FALSE)
    files <- list.files("test_data2", pattern = "^SS_Y[0-9]{2}\\.txt$", full.names = TRUE)

    dts <- lapply(files, function(f) read_sensor_data(f, verbose = FALSE))
    names(dts) <- files

    compute_sensor_metrics_opt <- function(df, filename) {
      sensor_names <- names(df)[startsWith(names(df), "Sensor")]
      n_rows <- nrow(df)
      idx_first <- 1:min(10, n_rows)
      idx_last <- max(1, n_rows - 4):n_rows
      len_sensors <- length(sensor_names)
      first10 <- numeric(len_sensors)
      last5 <- numeric(len_sensors)
      full <- numeric(len_sensors)

      for (j in seq_len(len_sensors)) {
        v <- .subset2(df, sensor_names[j])

        v_first <- v[idx_first]
        if (anyNA(v_first)) v_first <- v_first[!is.na(v_first)]
        first10[j] <- mean.default(v_first[v_first > 0])

        v_last <- v[idx_last]
        if (anyNA(v_last)) v_last <- v_last[!is.na(v_last)]
        last5[j] <- mean.default(v_last[v_last > 0])

        if (anyNA(v)) v_clean <- v[!is.na(v)] else v_clean <- v
        full[j] <- mean.default(v_clean[v_clean > 0])
      }
      diff <- full - first10
      year_tag <- substr(basename(filename), 5, 6)
      year_num <- as.integer(year_tag)
      sheet_name <- if (!is.na(year_num) && year_num >= 1 && year_num <= 20) {
        as.character(1994 + year_num)
      } else {
        basename(filename)
      }
      dt <- data.table(
        Sensor = sensor_names,
        first10 = first10,
        last5 = last5,
        full = full,
        within_diff = diff
      )
      list(dt = dt, sheet_name = sheet_name)
    }

    microbenchmark(
        base = lapply(names(dts), function(f) compute_sensor_metrics(dts[[f]], f)),
        opt = lapply(names(dts), function(f) compute_sensor_metrics_opt(dts[[f]], f)),
        times = 100
    )
}

print("Profiling compute metrics")
print(test_base(1000, 20))
