# Complete Updated Seatek Analysis Script
# Author: Abhi Meh# Complete Updated Seatek Analysis Script
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

# Verify and normalize data directory path
auto_detect_data_dir <- function(data_dir) {
  if (missing(data_dir) || !dir.exists(data_dir)) {
    stop(paste0("Data directory not found: ", data_dir))
  }
  normalizePath(data_dir)
}

# Default separator for reading files
default_sep <- " "

# Read sensor data from a .txt file
read_sensor_data <- function(file_path) {
  file_path <- normalizePath(file_path)
  message(sprintf("Reading sensor file: %s", basename(file_path)))
  if (!file.exists(file_path) || !grepl("\\.txt$", file_path)) {
    stop(sprintf("Invalid file: %s", file_path))
  }
  dt <- tryCatch(
    fread(file_path, header = FALSE, sep = default_sep, fill = TRUE, na.strings = c("NA")),
    error = function(e) stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
  )
  # Warn if fewer than expected columns
  if (ncol(dt) < 33) {
    warning(sprintf("File %s has only %d columns; expected >=33.", basename(file_path), ncol(dt)))
  }
  # Assign names to sensor columns and timestamp
  cols <- ncol(dt)
  sensor_cols <- min(cols - 1, 32)
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  if (cols >= sensor_cols + 1) {
    setnames(dt, sensor_cols + 1, "Timestamp")
  }
  # Keep only sensor columns and timestamp
  dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)), "Timestamp"), with = FALSE]
  # Convert Timestamp if numeric
  if (all(!is.na(as.numeric(dt$Timestamp)))) {
    dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
  }
  return(dt)
}

# Process sensor files: export raw data and compute summaries
eprocess_all_data <- function(data_dir) {
  data_dir <- auto_detect_data_dir(data_dir)
  files <- list.files(data_dir, pattern = "^S28_Y[0-9]{2}\\.txt$", full.names = TRUE)
  if (length(files) == 0) {
    stop("No sensor .txt data files found in directory (pattern S28_Y##.txt).")
  }
  results <- list()
  for (f in files) {
    df <- read_sensor_data(f)
    # Export the raw data to its own Excel file
    raw_out <- file.path(data_dir, paste0(tools::file_path_sans_ext(basename(f)), ".xlsx"))
    write.xlsx(df, raw_out, overwrite = TRUE)
    message(sprintf("Raw data written to %s", raw_out))
    # Compute summary metrics
    year_tag <- sub("^.*S28_Y([0-9]{2})\\.txt$", "\\1", basename(f))
    year <- if (nchar(year_tag) == 2) paste0("20", year_tag) else basename(f)
    clean_vals <- function(x) x[!is.na(x) & x > 0]
    first5 <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(head(x, 5))))
    last5  <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(tail(x, 5))))
    full   <- sapply(df[, 1:32, with = FALSE], function(x) mean(clean_vals(x)))
    within_diff <- full - first5
    results[[year]] <- list(
      first5 = first5,
      last5 = last5,
      full = full,
      within_diff = within_diff
    )
  }
  return(results)
}

# Write summary workbook\written_summary_excel <- function(results, output_file) {
wb <- createWorkbook()
for (year in names(results)) {
  addWorksheet(wb, year)
  df <- as.data.frame(results[[year]])
  rownames(df) <- paste0("Sensor", sprintf("%02d", 1:32))
  writeData(wb, sheet = year, x = df, rowNames = TRUE)
}
saveWorkbook(wb, output_file, overwrite = TRUE)
message(sprintf("Summary written to %s", output_file))
}

# Main execution
main <- function() {
  data_dir <- "/Users/abhis_space/RProjects/Seatek_Analysis/Data"
  results <- process_all_data(data_dir)
  summary_out <- file.path(data_dir, "Seatek_Summary.xlsx")
  write_summary_excel(results, summary_out)
  message("Processing complete.")
}

# Automatically run in non-interactive sessions
if (!interactive()) {
  main()
}
# End of script