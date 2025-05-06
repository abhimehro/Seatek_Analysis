# Complete Updated Seatek Analysis Script
# Author: Abhi Mehrotra
# Last Updated: 2025-05-06

# This script processes Seatek sensor data to analyze riverbed changes over time.
# It reads raw sensor data files (S28_Yxx.txt), validates them, exports each to Excel,
# computes summary metrics, and generates a combined summary workbook.

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
  pattern <- "^S28_Y[0-9]{2}\\.txt$"
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
    first5 <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(head(x, 5))))
    last5  <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(tail(x, 5))))
    full   <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(x)))
    diff   <- full - first5
    # Derive sheet/year name
    year_tag <- sub("^S28_Y([0-9]{2})\\.txt$", "\\1", basename(f))
    sheet_name <- if (nchar(year_tag) == 2) paste0("20", year_tag) else basename(f)
    results[[sheet_name]] <- data.frame(
      first5 = first5,
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
