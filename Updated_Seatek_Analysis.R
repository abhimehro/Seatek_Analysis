# Complete Updated Seatek Analysis Script
# Author: Abhi Mehrotra
# Last Updated: 2025-05-06

# This script processes Seatek sensor data to analyze riverbed changes over time.
# It reads raw sensor data files (S28_Yxx.txt), validates them, exports each to Excel,
# computes summary metrics (first 10, last 5, full, within_diff), and generates a combined summary workbook.

# Load required packages (install if missing)
required_packages <- c("data.table", "openxlsx", "dplyr", "tidyr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

library(data.table)
library(openxlsx)
library(dplyr)
library(tidyr)

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
    fread(file_path, header = FALSE, sep = sep, fill = TRUE, na.strings = c("NA")),
    error = function(e) stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
  )
  if (ncol(dt) < 33) {
    warning(sprintf("File %s has only %d columns; expected >=33.", basename(file_path), ncol(dt)))
  }
  total_cols <- ncol(dt)
  sensor_cols <- min(total_cols - 1, 32)
  # Name sensors and timestamp
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  if (total_cols >= sensor_cols + 1) {
    setnames(dt, sensor_cols + 1, "Timestamp")
  }
  # Keep only sensor columns + Timestamp
  dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)), "Timestamp"), with = FALSE]
  # Convert timestamp if numeric
  if (all(!is.na(as.numeric(dt$Timestamp)))) {
    dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
  }
  return(dt)
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
    out_raw <- file.path(data_dir, paste0(tools::file_path_sans_ext(basename(f)), ".xlsx"))
    write.xlsx(df, out_raw, overwrite = TRUE)
    message(sprintf("Raw data written to %s", out_raw))
    # Compute summary metrics
    clean_vals <- function(x) x[!is.na(x) & x > 0]
    first10 <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(head(x, 10))))
    last5  <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(tail(x, 5))))
    full   <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(x)))
    diff   <- full - first10
    # Derive sheet/year name
    year_tag <- sub("^SS_Y([0-9]{2})\\.txt$", "\\1", basename(f))
    # Map Y01=1995, Y02=1996, ..., Y20=2014
    year_num <- as.integer(year_tag)
    sheet_name <- if (!is.na(year_num) && year_num >= 1 && year_num <= 20) as.character(1994 + year_num) else basename(f)
    results[[sheet_name]] <- data.frame(
      first10 = first10,
      last5 = last5,
      full = full,
      within_diff = diff,
      row.names = paste0("Sensor", sprintf("%02d", 1:32)),
      check.names = FALSE
    )
  }
  return(results)
}

# Write combined summary workbook
dump_summary_excel <- function(results, output_file, highlight_top_n = 5) {
  wb <- createWorkbook()
  headerStyle <- createStyle(textDecoration = "bold")
  # Write each year's sheet
  for (year in names(results)) {
    addWorksheet(wb, year)
    df <- as.data.frame(results[[year]])
    writeData(wb, sheet = year, x = df, rowNames = TRUE, headerStyle = headerStyle)
    freezePane(wb, sheet = year, firstRow = TRUE)
    # Optional: highlight largest within_diff in each year
    if ("within_diff" %in% colnames(df)) {
      max_idx <- which.max(abs(df$within_diff))
      highlightStyle <- createStyle(bgFill = "#FFD700")
      addStyle(wb, sheet = year, style = highlightStyle, rows = max_idx + 1, cols = which(colnames(df) == "within_diff") + 1, gridExpand = TRUE, stack = TRUE)
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
    summary_df[[paste0(metric, "_min")]] <- apply(vals, 1, min, na.rm = TRUE)
    summary_df[[paste0(metric, "_max")]] <- apply(vals, 1, max, na.rm = TRUE)
    summary_df[[paste0(metric, "_count")]] <- apply(vals, 1, function(x) sum(!is.na(x)))
  }
  addWorksheet(wb, "Summary")
  writeData(wb, sheet = "Summary", x = summary_df, headerStyle = headerStyle)
  freezePane(wb, sheet = "Summary", firstRow = TRUE)
  # Highlight top N sensors with largest absolute within_diff_mean
  if ("within_diff_mean" %in% colnames(summary_df)) {
    abs_diff <- abs(summary_df$within_diff_mean)
    top_idx <- order(abs_diff, decreasing = TRUE)[seq_len(min(highlight_top_n, length(abs_diff)))]
    highlightStyle <- createStyle(bgFill = "#FF9999")
    addStyle(wb, sheet = "Summary", style = highlightStyle, rows = top_idx + 1, cols = which(colnames(summary_df) == "within_diff_mean") + 1, gridExpand = TRUE, stack = TRUE)
  }
  saveWorkbook(wb, output_file, overwrite = TRUE)
  message(sprintf("Summary written to %s", output_file))
}

# Main execution block
if (sys.nframe() == 0 || interactive()) {
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
}
# End of script
