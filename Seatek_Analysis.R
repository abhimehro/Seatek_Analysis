# Complete Updated Seatek Analysis Script
# Author: Abhi Mehrotra
# Last Updated: 2025-05-06

# This script processes Seatek sensor data to analyze riverbed changes over time.
# It reads raw sensor data files (S28_Yxx.txt), validates them, exports each to Excel,
# computes summary metrics, and generates a combined summary workbook.

# Load required packages (install if missing)
required_packages <- c("data.table", "openxlsx", "dplyr", "tidyr", "logger")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

library(data.table)
library(openxlsx)
library(dplyr)
library(tidyr)
library(logger)
log_appender(appender_file("seatek_analysis.log"))
log_layout(layout_glue_colors)

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
  log_info("Reading sensor file: {basename(file_path)}")
  if (!file.exists(file_path) || !grepl("\\.txt$", file_path)) {
    log_error("Invalid file: {file_path}")
    stop(sprintf("Invalid file: %s", file_path))
  }
  dt <- tryCatch(
    fread(file_path, header = FALSE, sep = default_sep, fill = TRUE, na.strings = c("NA")),
    error = function(e) {
      log_error("Error reading {basename(file_path)}: {e$message}")
      stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
    }
  )
  if (ncol(dt) < 33) {
    log_warn("File {basename(file_path)} has only {ncol(dt)} columns; expected >=33.")
  }
  cols <- ncol(dt)
  sensor_cols <- min(cols - 1, 32)
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  if (cols >= sensor_cols + 1) {
    setnames(dt, sensor_cols + 1, "Timestamp")
  }
  dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)), "Timestamp"), with = FALSE]
  if (all(!is.na(as.numeric(dt$Timestamp)))) {
    dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
  }
  return(dt)
}

process_all_data <- function(data_dir, file_pattern = "^S28_Y[0-9]{2}\\.txt$") {
  data_dir <- auto_detect_data_dir(data_dir)
  print(paste("Looking for data in:", data_dir))
  print(list.files(data_dir))
  if (!file.exists(file.path(data_dir, "S28_Y01.txt"))) {
    stop("File S28_Y01.txt not found in data_dir!")
  }
  files <- list.files(data_dir, pattern = file_pattern, full.names = TRUE)
  if (length(files) == 0) {
    log_error("No sensor .txt data files found in directory (pattern S28_Y##.txt).")
    stop("No sensor .txt data files found in directory (pattern S28_Y##.txt).")
  }
  results <- list()
  for (f in files) {
    tryCatch({
      df <- read_sensor_data(f)
      raw_out <- file.path(data_dir, paste0(tools::file_path_sans_ext(basename(f)), ".xlsx"))
      write.xlsx(df, raw_out, overwrite = TRUE)
      log_info("Raw data written to {raw_out}")
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
    }, error = function(e) {
      log_error("Failed to process file {f}: {e$message}")
    })
  }
  return(results)
}

# Write summary workbook
write_summary_excel <- function(results, output_file) {
  wb <- createWorkbook()
  for (year in names(results)) {
    addWorksheet(wb, year)
    df <- as.data.frame(results[[year]])
    rownames(df) <- paste0("Sensor", sprintf("%02d", 1:32))
    writeData(wb, sheet = year, x = df, rowNames = TRUE)
  }
  saveWorkbook(wb, output_file, overwrite = TRUE)
  log_info("Summary written to {output_file}")
}

# Main execution
main <- function() {
  data_dir <- file.path(getwd(), "Data")
  print(paste("Running main(). Data directory:", data_dir))
  if (!dir.exists(data_dir)) {
    stop(paste("Data directory does not exist:", data_dir))
  }
  data_dir <- normalizePath(data_dir)
  print(getwd())
  file_pattern <- "^S28_Y[0-9]{2}\\.txt$"
  results <- process_all_data(data_dir, file_pattern)
  summary_out <- file.path(data_dir, "Seatek_Summary.xlsx")
  write_summary_excel(results, summary_out)
  message("Processing complete.")
}

if (sys.nframe() == 0 || interactive()) {
  main()
}
# End of script