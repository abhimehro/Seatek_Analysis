# Complete Updated Seatek Analysis Script
# Author: Abhi Mehrotra
# Last Updated: 2025-05-06

# This script processes Seatek sensor data to analyze riverbed changes
# over time.
# It reads raw sensor data files (S28_Yxx.txt), validates them,
# exports each to Excel,
# computes summary metrics (first 10, last 5, full, within_diff),
# and generates a combined summary workbook.

# Load required packages (install if missing)
required_packages <- c("data.table", "openxlsx", "dplyr", "tidyr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    # Use HTTPS to prevent MITM attacks
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(data.table)
library(openxlsx)
library(dplyr)
library(tidyr)

# Log all warnings, errors, and messages to a file for diagnostics
log_file <- file.path(getwd(), "processing_warnings.log")
if (file.exists(log_file)) file.remove(log_file)
log_handler <- function(type, msg) {
  cat(sprintf("[%s] %s\n", type, msg), file = log_file, append = TRUE)
}

# Utility: verify and normalize data directory path
auto_detect_data_dir <- function(data_dir) {
  if (missing(data_dir) || !dir.exists(data_dir)) {
    stop(sprintf("Data directory not found: %s", data_dir))
  }
  normalizePath(data_dir)
}

# Read a single sensor data file
read_sensor_data <- function(file_path, sep = " ") {
  file_path <- normalizePath(file_path)
  message(sprintf("Reading sensor file: %s", basename(file_path)))
  if (!file.exists(file_path) || !grepl("\\.txt$", file_path)) {
    stop(sprintf("Invalid file: %s", file_path))
  }
  dt <- tryCatch(
    fread(file_path, header = FALSE, sep = sep, fill = TRUE,
          na.strings = c("NA")),
    error = function(e) {
      stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
    }
  )
  if (ncol(dt) < 33) {
    warning(sprintf("File %s has only %d columns; expected >=33.",
                    basename(file_path), ncol(dt)))
  }
  total_cols <- ncol(dt)
  sensor_cols <- min(total_cols - 1, 32)
  # Name sensors and timestamp
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  if (total_cols >= sensor_cols + 1) {
    setnames(dt, sensor_cols + 1, "Timestamp")
  }
  # Keep only sensor columns + Timestamp
  dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)),
               "Timestamp"), with = FALSE]
  # Convert timestamp if numeric
  if (all(!is.na(as.numeric(dt$Timestamp)))) {
    dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
  }
  dt # Implicit return
}

# Process all sensor files: export raw, compute metrics
process_all_data <- function(data_dir) {
  data_dir <- auto_detect_data_dir(data_dir)
  pattern <- "^SS_Y[0-9]{2}\\.txt$"  # Updated pattern to match your files
  files <- list.files(data_dir, pattern = pattern, full.names = TRUE)
  if (length(files) == 0) {
    stop(sprintf("No sensor files found matching %s in %s", pattern, data_dir))
  }
  results <- list()
  for (f in files) {
    df <- read_sensor_data(f)
    # Export raw data to Excel
    out_raw <- file.path(data_dir, paste0(
      tools::file_path_sans_ext(basename(f)), ".xlsx"
    ))
    write.xlsx(df, out_raw, overwrite = TRUE)
    message(sprintf("Raw data written to %s", out_raw))
    # Compute summary metrics
    clean_vals <- function(x) x[!is.na(x) & x > 0]
    sensor_names <- grep("^Sensor", names(df), value = TRUE)
    first10 <- sapply(df[, ..sensor_names],
                      function(x) mean(clean_vals(head(x, 10))))
    last5  <- sapply(df[, ..sensor_names],
                     function(x) mean(clean_vals(tail(x, 5))))
    full   <- sapply(df[, ..sensor_names], function(x) mean(clean_vals(x)))
    diff   <- full - first10
    # Derive sheet/year name
    year_tag <- sub("^SS_Y([0-9]{2})\\.txt$", "\\1", basename(f))
    # Map Y01=1995, Y02=1996, ..., Y20=2014
    year_num <- as.integer(year_tag)
    sheet_name <- if (!is.na(year_num) && year_num >= 1 && year_num <= 20) {
      as.character(1994 + year_num)
    } else {
      basename(f)
    }
    results[[sheet_name]] <- data.frame(
      first10 = first10,
      last5 = last5,
      full = full,
      within_diff = diff,
      row.names = sensor_names,
      check.names = FALSE
    )
  }
  results # Implicit return
}

# Write combined summary workbook
dump_summary_excel <- function(results, output_file, highlight_top_n = 5) {
  wb <- createWorkbook()
  header_style <- createStyle(textDecoration = "bold")
  # Write each year's sheet
  for (year in names(results)) {
    addWorksheet(wb, year)
    df <- as.data.frame(results[[year]])
    writeData(wb, sheet = year, x = df, rowNames = TRUE,
              headerStyle = header_style)
    freezePane(wb, sheet = year, firstRow = TRUE)
    # Optional: highlight largest within_diff in each year
    if ("within_diff" %in% colnames(df)) {
      max_idx <- which.max(abs(df$within_diff))
      highlight_style_yearly <- createStyle(bgFill = "#FFD700")
      addStyle(wb, sheet = year, style = highlight_style_yearly,
               rows = max_idx + 1,
               cols = which(colnames(df) == "within_diff") + 1,
               gridExpand = TRUE, stack = TRUE)
    }
  }
  # Add summary sheet with overall stats
  all_stats <- do.call(rbind, results)
  sensor_names <- rownames(all_stats)
  sensors <- unique(sensor_names)
  metrics <- colnames(all_stats)
  summary_df <- data.frame(
    Sensor = sensors,
    stringsAsFactors = FALSE
  )
  for (metric in metrics) {
    vals <- sapply(sensors, function(s) all_stats[sensor_names == s, metric])
    vals <- as.matrix(vals)
    summary_df[[paste0(metric, "_mean")]] <- rowMeans(vals, na.rm = TRUE)
    summary_df[[paste0(metric, "_sd")]] <- apply(vals, 1, sd, na.rm = TRUE)
    summary_df[[paste0(metric, "_median")]] <-
      apply(vals, 1, median, na.rm = TRUE)
    summary_df[[paste0(metric, "_mad")]] <- apply(vals, 1, mad, na.rm = TRUE)
    summary_df[[paste0(metric, "_min")]] <- apply(vals, 1, function(x) {
      x_clean <- x[!is.na(x)]
      if (length(x_clean) == 0) NA else min(x_clean)
    })
    summary_df[[paste0(metric, "_max")]] <- apply(vals, 1, function(x) {
      x_clean <- x[!is.na(x)]
      if (length(x_clean) == 0) NA else max(x_clean)
    })
    summary_df[[paste0(metric, "_count")]] <-
      apply(vals, 1, function(x) sum(!is.na(x)))
    # Rolling mean (3-year) for each sensor
    summary_df[[paste0(metric, "_rollmean3")]] <- apply(vals, 1, function(x) {
      x_clean <- x[!is.na(x)]
      if (length(x_clean) < 3) return(NA)
      mean(tail(x_clean, 3))
    })
  }

  # Calculate percent non-missing for 'full'
  summary_df$full_pct_nonmissing <-
    100 * summary_df$full_count / length(results)

  # --- Comprehensive summary (all sensors) ---
  summary_df_all <- summary_df # keep a copy before filtering
  addWorksheet(wb, "Summary_All")
  writeData(wb, sheet = "Summary_All", x = summary_df_all,
            headerStyle = header_style)
  freezePane(wb, sheet = "Summary_All", firstRow = TRUE)
  # Export comprehensive summary as CSV
  csv_all <- sub("\\.xlsx$", "_all.csv", output_file)
  write.csv(summary_df_all, csv_all, row.names = FALSE)
  message(sprintf("Comprehensive summary CSV written to %s", csv_all))

  # --- Filtered summary (sufficient data only) ---
  min_count <- 5
  summary_df_sufficient <-
    summary_df_all[summary_df_all$full_count >= min_count, ]
  addWorksheet(wb, "Summary_Sufficient")
  writeData(wb, sheet = "Summary_Sufficient", x = summary_df_sufficient,
            headerStyle = header_style)
  freezePane(wb, sheet = "Summary_Sufficient", firstRow = TRUE)
  # Export filtered summary as CSV
  csv_sufficient <- sub("\\.xlsx$", "_sufficient.csv", output_file)
  write.csv(summary_df_sufficient, csv_sufficient, row.names = FALSE)
  message(sprintf("Filtered summary CSV written to %s", csv_sufficient))

  # Continue with filtered summary for top sensors and highlighting
  summary_df <- summary_df_sufficient
  # Flag high-variability sensors (e.g., full_sd > threshold)
  sd_threshold <- 2 # adjust as needed
  summary_df$flag_high_variability <- summary_df$full_sd > sd_threshold

  # Prepare top sensors by absolute within_diff_mean
  if ("within_diff_mean" %in% colnames(summary_df)) {
    abs_diff <- abs(summary_df$within_diff_mean)
    top_n <- 5
    top_sensors <- summary_df[order(-abs_diff), ][1:top_n,
      c(
        "Sensor", "within_diff_mean",
        "full_mean", "full_sd",
        "full_pct_nonmissing"
      )
    ]
    write.csv(top_sensors,
              sub("\\.xlsx$", "_top_sensors.csv", output_file),
              row.names = FALSE)
    addWorksheet(wb, "Summary_Top_Sensors")
    writeData(
      wb,
      sheet = "Summary_Top_Sensors",
      x = top_sensors,
      headerStyle = header_style
    )
    freezePane(wb, sheet = "Summary_Top_Sensors", firstRow = TRUE)
    setColWidths(wb, sheet = "Summary_Top_Sensors", cols = 1:ncol(top_sensors), widths = "auto")
  }

  addWorksheet(wb, "Summary")
  writeData(wb, sheet = "Summary", x = summary_df, headerStyle = header_style)
  freezePane(wb, sheet = "Summary", firstRow = TRUE)
  # Highlight top N sensors with largest absolute within_diff_mean
  if ("within_diff_mean" %in% colnames(summary_df)) {
    abs_diff <- abs(summary_df$within_diff_mean)
    top_idx <- order(abs_diff, decreasing = TRUE)[
      seq_len(min(highlight_top_n, length(abs_diff)))
    ]
    highlight_style_summary <- createStyle(bgFill = "#FF9999")
    addStyle(wb, sheet = "Summary", style = highlight_style_summary,
             rows = top_idx + 1,
             cols = which(colnames(summary_df) == "within_diff_mean") + 1,
             gridExpand = TRUE, stack = TRUE)
  }
  saveWorkbook(wb, output_file, overwrite = TRUE)
  message(sprintf("Summary written to %s", output_file))
  # Also export summary as CSV for preview
  csv_out <- sub("\\.xlsx$", ".csv", output_file)
  write.csv(summary_df, csv_out, row.names = FALSE)
  message(sprintf("Summary CSV written to %s", csv_out))
  # Export robust stats as CSV
  csv_robust <- sub("\\.xlsx$", "_robust.csv", output_file)
  write.csv(summary_df, csv_robust, row.names = FALSE)
  message(sprintf("Robust summary CSV written to %s", csv_robust))
}

# Main execution block
if (sys.nframe() == 0 || interactive()) {
  withCallingHandlers({
    data_dir <- file.path(getwd(), "Data")
    message(sprintf("Running main(). Data directory: %s", data_dir))
    if (!dir.exists(data_dir)) {
      stop(sprintf("Data directory does not exist: %s", data_dir))
    }
    data_dir <- normalizePath(data_dir)
    results <- process_all_data(data_dir)
    summary_out <- file.path(data_dir, "Seatek_Summary.xlsx")
    dump_summary_excel(results, summary_out)
    message("Processing complete.")
  },
  warning = function(w) {
    log_handler("WARNING", conditionMessage(w))
    invokeRestart("muffleWarning")
  },
  error   = function(e) {
    error_message <- conditionMessage(e)
    if (grepl("could not find function|Error in library|there is no package called", error_message, ignore.case = TRUE)) {
      log_handler("DEPENDENCY_ERROR", error_message)
    } else {
      log_handler("PROCESSING_ERROR", error_message)
    }
    if (interactive()) {
      message(sprintf("An error occurred: %s. Check 'processing_warnings.log' for details.", error_message))
    }
  },
  message = function(m) {
    log_handler("MESSAGE", conditionMessage(m))
    invokeRestart("muffleMessage")
  })
}
# End of script
