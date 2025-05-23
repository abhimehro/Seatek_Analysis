# Seatek Analysis Script (Older Version)
# Author: Abhi Mehrotra
# Last Updated: 2025-05-06 (original date)
#
# !! IMPORTANT !!
# This script is likely an older version or intended for specific use cases,
# possibly for processing 'S28_Yxx.txt' files if they were structured or located
# differently than what 'Updated_Seatek_Analysis.R' now handles.
#
# For the primary, most current, and comprehensive analysis workflow,
# please refer to 'Updated_Seatek_Analysis.R'.
#
# This script's functionality is largely superseded by 'Updated_Seatek_Analysis.R',
# which processes both Series 28 ('SS_Yxx.txt') and Series 26 ('S26_Yxx.txt') data,
# offers more robust summary statistics, and aligns with the current repository structure.
#
# Original Purpose (assumed):
# This script was designed to process Seatek sensor data (likely 'S28_Yxx.txt' files)
# to analyze riverbed changes. It involved reading raw data, exporting to Excel,
# computing basic summary metrics, and generating a combined summary workbook.
# It uses the 'logger' package for logging, unlike the custom log handler in the updated script.

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

# Function: auto_detect_data_dir (Older version)
# Purpose: Validates data directory.
# Parameters:
#   - data_dir: Path to data directory.
# Returns: Normalized path or stops.
auto_detect_data_dir <- function(data_dir) {
  if (missing(data_dir) || !dir.exists(data_dir)) {
    stop(paste0("Data directory not found: ", data_dir))
  }
  normalizePath(data_dir)
}

# Default separator for reading files (Older version)
default_sep <- " "

# Function: read_sensor_data (Older version)
# Purpose: Reads a single sensor data file (.txt), space-separated.
# Parameters:
#   - file_path: Full path to the sensor .txt file.
# Returns: A data.table with sensor readings and timestamp.
# Note: Uses 'logger' package for logging. Assumes 'S28_Yxx.txt' like structure.
read_sensor_data <- function(file_path) {
  file_path <- normalizePath(file_path)
  log_info("Reading sensor file: {basename(file_path)}")
  if (!file.exists(file_path) || !grepl("\\.txt$", file_path, ignore.case = TRUE)) { # Made case-insensitive
    log_error("Invalid file: {file_path}")
    stop(sprintf("Invalid file: %s", file_path))
  }
  dt <- tryCatch(
    fread(file_path, header = FALSE, sep = default_sep, fill = TRUE, na.strings = c("NA", "", "NULL")), # Added more NA strings
    error = function(e) {
      log_error("Error reading {basename(file_path)}: {e$message}")
      stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
    }
  )
  if (ncol(dt) < 1) { # Check if any column is read
      log_error("File {basename(file_path)} appears to be empty or in an unexpected format.")
      stop(sprintf("File %s appears to be empty or in an unexpected format.", basename(file_path)))
  }
  if (ncol(dt) < 33) {
    log_warn("File {basename(file_path)} has only {ncol(dt)} columns; expected at least 33 (32 sensors + 1 timestamp).")
  }
  
  total_cols <- ncol(dt)
  sensor_cols <- min(total_cols - 1, 32) # Max 32 sensor columns
  
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  if (total_cols >= (sensor_cols + 1)) {
    setnames(dt, sensor_cols + 1, "Timestamp")
    dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)), "Timestamp"), with = FALSE]
    if (is.numeric(dt$Timestamp) && any(!is.na(dt$Timestamp))) {
        if (all(sapply(dt$Timestamp[!is.na(dt$Timestamp)], is.numeric))) {
             dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
        } else {
            log_warn("Timestamp column in {basename(file_path)} contains non-numeric values, not converted to POSIXct.")
        }
    } else if (!is.numeric(dt$Timestamp) || all(is.na(dt$Timestamp))) {
        log_info("Timestamp in {basename(file_path)} is not strictly numeric. Using as is.")
    }
  } else {
    log_warn("No Timestamp column found or named in {basename(file_path)}.")
    dt <- dt[, paste0("Sensor", sprintf("%02d", 1:sensor_cols)), with = FALSE]
  }
  return(dt)
}

# Function: process_all_data (Older version)
# Purpose: Processes sensor files matching a pattern (default 'S28_Yxx.txt').
#          Exports raw data to Excel and computes basic metrics (first5, last5, full, within_diff).
# Parameters:
#   - data_dir: Directory containing sensor files.
#   - file_pattern: Regex pattern for files to process.
# Returns: A list of results, one element per file/year, with computed metrics.
# Note: Original script had a check for "S28_Y01.txt" which is very specific.
#       Metrics (first5 vs first10) and year naming (20xx vs 19xx) differ from updated script.
process_all_data <- function(data_dir, file_pattern = "^S28_Y[0-9]{2}\\.txt$") {
  data_dir <- auto_detect_data_dir(data_dir)
  log_info("Looking for data in: {data_dir} with pattern: {file_pattern}")
  
  files <- list.files(data_dir, pattern = file_pattern, full.names = TRUE)
  if (length(files) == 0) {
    log_error("No sensor .txt data files found in {data_dir} matching pattern {file_pattern}.")
    stop(sprintf("No sensor .txt data files found in %s matching pattern %s.", data_dir, file_pattern))
  }
  
  results <- list()
  for (f in files) {
    tryCatch({
      df <- read_sensor_data(f)
      # Output path for individual Excel file (same directory as input .txt)
      raw_out_excel_path <- file.path(dirname(f), paste0(tools::file_path_sans_ext(basename(f)), ".xlsx"))
      write.xlsx(df, raw_out_excel_path, overwrite = TRUE)
      log_info("Raw data for {basename(f)} written to {raw_out_excel_path}")
      
      # Year naming: S28_Y01 -> 2001. This is different from Updated_Seatek_Analysis.R (Y01 -> 1995)
      year_tag_match <- regexpr("S28_Y([0-9]{2})\\.txt$", basename(f), ignore.case = TRUE)
      year_digits_str <- regmatches(basename(f), year_tag_match)
      year_digits <- sub("S28_Y", "", year_digits_str[1], ignore.case = TRUE)
      year_digits <- sub("\\.txt$", "", year_digits, ignore.case = TRUE)
      
      sheet_name_year <- if (nchar(year_digits) == 2) paste0("20", year_digits) else tools::file_path_sans_ext(basename(f))

      num_sensors_to_process <- min(ncol(df) -1, 32)
      sensor_data_cols <- df[, 1:num_sensors_to_process, with = FALSE]

      clean_vals <- function(x) {
          x_cleaned <- x[!is.na(x) & x > 0]
          if(length(x_cleaned) == 0) NA else x_cleaned
      }
      
      # Metrics calculation (first5, last5) - different from updated script's first10
      first5 <- sapply(sensor_data_cols, function(x) mean(clean_vals(head(x, 5)), na.rm = TRUE))
      last5  <- sapply(sensor_data_cols, function(x) mean(clean_vals(tail(x, 5)), na.rm = TRUE))
      full   <- sapply(sensor_data_cols, function(x) mean(clean_vals(x), na.rm = TRUE))
      within_diff <- full - first5 # Based on first5
      
      # Ensure 32 sensor rows
      sensor_names_std <- paste0("Sensor", sprintf("%02d", 1:32))
      current_sensor_names <- paste0("Sensor", sprintf("%02d", 1:num_sensors_to_process))
      
      final_metrics_df <- data.frame(row.names = sensor_names_std)
      final_metrics_df$first5 <- NA; final_metrics_df$last5 <- NA; final_metrics_df$full <- NA; final_metrics_df$within_diff <- NA
      
      final_metrics_df[current_sensor_names, "first5"] <- first5
      final_metrics_df[current_sensor_names, "last5"] <- last5
      final_metrics_df[current_sensor_names, "full"] <- full
      final_metrics_df[current_sensor_names, "within_diff"] <- within_diff

      results[[sheet_name_year]] <- final_metrics_df
      
    }, error = function(e) {
      log_error("Failed to process file {f}: {e$message}")
    })
  }
  return(results)
}

# Function: write_summary_excel (Older version)
# Purpose: Writes processed results to a multi-sheet Excel workbook.
#          Each sheet corresponds to a year and contains the metrics.
# Parameters:
#   - results: List from process_all_data.
#   - output_file: Path for the output Excel file.
# Note: This version is simpler, lacking the detailed summary sheets ('Summary_All', 'Summary_Sufficient')
#       and CSV outputs of the 'Updated_Seatek_Analysis.R' script.
write_summary_excel <- function(results, output_file) {
  wb <- createWorkbook()
  headerStyle <- createStyle(textDecoration = "bold") # Added header style for consistency
  
  for (year_sheet_name in names(results)) {
    addWorksheet(wb, year_sheet_name)
    df_year <- as.data.frame(results[[year_sheet_name]])
    # Row names should already be Sensor01-Sensor32 from process_all_data
    writeData(wb, sheet = year_sheet_name, x = df_year, rowNames = TRUE, headerStyle = headerStyle)
    freezePane(wb, sheet = year_sheet_name, firstRow = TRUE) # Freeze header
  }
  saveWorkbook(wb, output_file, overwrite = TRUE)
  log_info("Summary workbook written to {output_file}")
}

# Main execution block (Older version)
# Note: Assumes data is in "Data/" relative to current working directory and expects "S28_Yxx.txt" files.
#       Output "Seatek_Summary.xlsx" is also placed in "Data/".
main <- function() {
  # Define the data directory - typically 'Data/' in the project root.
  # This script assumes S28_Yxx.txt files are directly in this data_dir.
  data_dir <- file.path(getwd(), "Data") 
  log_info("Running main(). Data directory targeted: {data_dir}")

  if (!dir.exists(data_dir)) {
    log_error("Data directory does not exist: {data_dir}")
    stop(paste("Data directory does not exist:", data_dir))
  }
  
  # Normalize path (though auto_detect_data_dir in process_all_data will also do this)
  data_dir <- normalizePath(data_dir)
  
  # Define file pattern for S28 series files
  # This was the primary focus of this older script.
  file_pattern_s28 <- "^S28_Y[0-9]{2}\\.txt$" 
  
  results <- process_all_data(data_dir = data_dir, file_pattern = file_pattern_s28)
  
  if (length(results) > 0) {
    summary_out_excel_path <- file.path(data_dir, "Seatek_Summary_S28_OlderScript.xlsx") # Changed name to avoid conflict
    write_summary_excel(results, summary_out_excel_path)
    log_info("Processing complete. Output: {summary_out_excel_path}")
    message(paste("Processing complete. Output:", summary_out_excel_path))
  } else {
    log_warn("No data processed, summary workbook not generated.")
    message("No data processed, summary workbook not generated.")
  }
}

# Script entry point if run directly
if (sys.nframe() == 0 || interactive()) {
  main()
}
# End of script