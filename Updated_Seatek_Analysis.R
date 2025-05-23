# Seatek Sensor Data Analysis Script
# Author: Abhi Mehrotra (Original), AI Agent (Consolidation & Modularization)
# Last Updated: 2024-07-15
#
# Purpose:
# This script is the primary tool for processing Seatek sensor data from raw text files.
# It performs the following key operations:
# 1. Reads and validates raw sensor data files (e.g., SS_Yxx.txt).
# 2. Exports the raw data for each input file to a separate sheet in an Excel file.
# 3. Calculates summary statistics for each sensor in each file, including:
#    - Mean of the first 10 readings (first10)
#    - Mean of the last 5 readings (last5)
#    - Mean of all readings (full)
#    - Difference between 'full' and 'first10' (within_diff)
# 4. Generates a comprehensive summary Excel workbook (`Seatek_Summary.xlsx`) containing:
#    - A sheet for each year's processed data.
#    - A "Summary_All" sheet with aggregated statistics across all years for all sensors.
#    - A "Summary_Sufficient" sheet, filtering sensors based on data availability.
#    - A "Summary" sheet (based on "Summary_Sufficient") with highlighting for sensors
#      exhibiting significant changes or variability.
# 5. Produces various summary CSV files derived from the Excel summary sheets.
#
# Integration Note:
# The output Excel file `Seatek_Summary.xlsx` (specifically the individual year sheets)
# is designed to be compatible as an input for further analysis, such as the
# `Series_27/Analysis/outlier_analysis_series27.py` script, which can be used for
# outlier detection and correction.

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

# Log all warnings, errors, and messages to a file for diagnostics
# This log file helps in troubleshooting and tracking the script's execution.
log_file <- file.path(getwd(), "processing_warnings.log")
if (file.exists(log_file)) file.remove(log_file) # Clear old log file on new run
log_handler <- function(type, msg) {
  cat(sprintf("[%s] %s\n", type, msg), file=log_file, append=TRUE)
}

#' Verify and normalize data directory path.
#'
#' @param data_dir A string path to the data directory.
#' @return A normalized string path to the data directory.
#' @stopifnot If the directory does not exist.
auto_detect_data_dir <- function(data_dir) {
  if (missing(data_dir) || !dir.exists(data_dir)) {
    stop(sprintf("Data directory not found: %s", data_dir))
  }
  normalizePath(data_dir)
}

#' Read a single sensor data file.
#'
#' Reads a space-separated .txt file containing sensor readings. Expects up to 32 sensor columns
#' and a timestamp column. Handles potential errors during file reading and basic validation.
#'
#' @param file_path A string path to the .txt sensor data file.
#' @param sep A string specifying the column separator (default is " ").
#' @return A data.table object with named sensor columns (Sensor01, Sensor02, ...) and a Timestamp column.
#'         Timestamp is converted to POSIXct if originally numeric.
#' @stopifnot If the file does not exist, is not a .txt file, or if fread encounters an error.
read_sensor_data <- function(file_path, sep = " ") {
  file_path <- normalizePath(file_path) # Ensure path is absolute and normalized
  message(sprintf("Reading sensor file: %s", basename(file_path)))
  
  # Validate file existence and extension
  if (!file.exists(file_path) || !grepl("\\.txt$", file_path, ignore.case = TRUE)) {
    stop(sprintf("Invalid file: %s. Must be a .txt file.. Must be a .txt file.", file_path))
  }
  
  # Attempt to read the file using fread for efficiency
  dt <- tryCatch(
    fread(file_path, header = FALSE, sep = sep, fill = TRUE, na.strings = c("NA", "", "NULL")), # Added more NA strings
    error = function(e) stop(sprintf("Error reading %s: %s", basename(file_path), e$message))
  )
  # Basic validation of column count
  if (ncol(dt) < 1) { # Check if any column is read
      stop(sprintf("File %s appears to be empty or in an unexpected format.", basename(file_path)))
  }
  if (ncol(dt) < 33) {
    warning(sprintf("File %s has only %d columns; expected at least 33 (32 sensors + 1 timestamp).", basename(file_path), ncol(dt)))
  }
  
  total_cols <- ncol(dt)
  sensor_cols <- min(total_cols - 1, 32) # Use at most 32 sensor columns
  
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  
  # Name timestamp column if it exists
  if (total_cols > (sensor_cols)) { # If there's at least one more column for timestamp
    setnames(dt, sensor_cols + 1, "Timestamp")
  } else {
    warning(sprintf("No column found for Timestamp in %s.", basename(file_path)))
    dt[, Timestamp := NA] # Add an empty Timestamp column if missing
  }
  
  # Keep only the first 32 sensor columns and the Timestamp column
  dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)), "Timestamp"), with = FALSE]
  
  if ("Timestamp" %in% names(dt) && all(!is.na(as.numeric(dt$Timestamp)))) {
    dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
  }
  return(dt)
}

#' Calculate summary statistics for a single file's data.
#'
#' Computes metrics like mean of first 10, last 5, and all readings for each sensor.
#' Also derives a sheet name based on the year encoded in the filename.
#'
#' @param df A data.table object containing sensor data (output from `read_sensor_data`).
#' @param file_basename A string, the base name of the input file (e.g., "SS_Y01.txt").
#' @return A list containing:
#'   - `sheet_name`: A string for the Excel sheet (e.g., "1995").
#'   - `stats_df`: A data.frame with statistics (first10, last5, full, within_diff) for each sensor.
calculate_single_file_stats <- function(df, file_basename) {
  message(sprintf("Calculating statistics for: %s", file_basename))
  # Helper function to clean values (non-NA, positive) for mean calculation
  clean_vals <- function(x) x[!is.na(x) & x > 0]
  
  # Select only sensor columns for calculations (up to Sensor32)
  sensor_cols_to_process <- intersect(names(df), paste0("Sensor", sprintf("%02d", 1:32)))
  
  first10 <- sapply(df[, ..sensor_cols_to_process], function(x) mean(clean_vals(head(x, 10))))
  last5  <- sapply(df[, ..sensor_cols_to_process], function(x) mean(clean_vals(tail(x, 5))))
  full   <- sapply(df[, ..sensor_cols_to_process], function(x) mean(clean_vals(x)))
  diff   <- full - first10
  
  # Derive sheet/year name from filename (e.g., "SS_Y01.txt" -> "1995")
  year_tag <- sub("^SS_Y([0-9]{2})\\.txt$", "\\1", file_basename)
  year_num <- as.integer(year_tag)
  sheet_name <- if (!is.na(year_num) && year_num >= 1 && year_num <= 20) { # Assuming Y01-Y20 map to 1995-2014
    as.character(1994 + year_num)
  } else {
    file_basename # Fallback if pattern doesn't match
  }
  
  stats_df <- data.frame(
    first10 = first10,
    last5 = last5,
    full = full,
    within_diff = diff,
    row.names = sensor_cols_to_process, # Use actual sensor names processed
    check.names = FALSE
  )
  message(sprintf("Finished calculating statistics for: %s. Sheet name: %s", file_basename, sheet_name))
  return(list(sheet_name = sheet_name, stats_df = stats_df))
}

#' Process all sensor files in a directory.
#'
#' Iterates over .txt files matching a specific pattern (SS_Yxx.txt) in the given data directory.
#' For each file, it reads the data, exports the raw data to an Excel sheet,
#' and then calculates summary statistics.
#'
#' @param data_dir A string path to the directory containing sensor .txt files.
#' @return A list where each element is a data.frame of statistics for a file,
#'         named by the derived sheet_name (year).
process_all_data <- function(data_dir) {
  data_dir <- auto_detect_data_dir(data_dir)
  pattern <- "^SS_Y[0-9]{2}\\.txt$" # Pattern for input files like SS_Y01.txt
  files <- list.files(data_dir, pattern = pattern, full.names = TRUE)
  
  if (length(files) == 0) {
    stop(sprintf("No sensor files found matching pattern '%s' in directory %s", pattern, data_dir))
  }
  

  results <- list()
  for (f in files) {
    file_basename <- basename(f)
    message(sprintf("Processing file: %s", file_basename))
    
    df <- read_sensor_data(f) # Read data
    
    # Export raw data to an Excel file (one sheet per input file originally,
    # but this was changed to individual Excel files per raw data table).
    # The current behavior is one .xlsx file per .txt file for raw data.
    out_raw_xlsx <- file.path(data_dir, paste0(tools::file_path_sans_ext(file_basename), ".xlsx"))
    tryCatch({
      write.xlsx(df, out_raw_xlsx, overwrite = TRUE)
      message(sprintf("Raw data for %s written to %s", file_basename, out_raw_xlsx))
    }, error = function(e) {
      warning(sprintf("Failed to write raw data Excel for %s: %s", file_basename, e$message))
    })
    
    # Calculate and store statistics
    file_stats_list <- calculate_single_file_stats(df, file_basename)
    results[[file_stats_list$sheet_name]] <- file_stats_list$stats_df
    message(sprintf("Stored statistics for sheet: %s (from file %s)", file_stats_list$sheet_name, file_basename))
  }
  return(results)
}

#' Write a combined summary Excel workbook and associated CSV files.
#'
#' Creates an Excel workbook with:
#' - Individual sheets for each year's statistics.
#' - Summary sheets (All, Sufficient, Main Summary with highlights).
#' Also exports several CSV files for key summary tables.
#'
#' @param results A list of data.frames, output from `process_all_data`.
#' @param output_file A string path for the output Excel summary file (e.g., "Seatek_Summary.xlsx").
#' @param highlight_top_n An integer, the number of top sensors to highlight based on 'within_diff_mean'.
#' @return None. Writes files to disk.
dump_summary_excel <- function(results, output_file, highlight_top_n = 5) {
  wb <- createWorkbook()
  headerStyle <- createStyle(textDecoration = "bold")

  # Write each year's statistics to a separate sheet
  for (year in names(results)) {
    addWorksheet(wb, year)
    df_year_stats <- as.data.frame(results[[year]])
    writeData(wb, sheet = year, x = df_year_stats, rowNames = TRUE, headerStyle = headerStyle)
    freezePane(wb, sheet = year, firstRow = TRUE)
    
    if ("within_diff" %in% colnames(df_year_stats)) {
      if(any(!is.na(df_year_stats$within_diff))) {
        max_idx <- which.max(abs(df_year_stats$within_diff))
        highlightStyle <- createStyle(bgFill = "#FFD700") # Gold for max diff in year
        addStyle(wb, sheet = year, style = highlightStyle, rows = max_idx + 1, # +1 for header row
                 cols = which(colnames(df_year_stats) == "within_diff") + 1, # +1 for rownames column
                 gridExpand = TRUE, stack = TRUE)
      } else {
        message(sprintf("Skipping highlighting for sheet %s as 'within_diff' contains all NA values.", year))
      }
    }
  }

  if (length(results) == 0) {
    message("No results to summarize. Skipping summary sheets generation.")
    addWorksheet(wb, "Info") # Add an info sheet if no results
    writeData(wb, sheet = "Info", x = "No data processed or no results generated.")
    saveWorkbook(wb, output_file, overwrite = TRUE)
    message(sprintf("Empty summary workbook (with Info sheet) saved to %s", output_file))
    return()
  }
  
  # Aggregate all statistics for summary calculations
  all_stats_aggregated <- do.call(rbind, lapply(names(results), function(year_name) {
    df = as.data.frame(results[[year_name]])
    df$Year = year_name # Add year column for multi-year stats if needed later
    df$Sensor = rownames(df)
    return(df)
  }))
  
  # Check if all_stats_aggregated is empty or has no sensor data
  if(nrow(all_stats_aggregated) == 0 || !("Sensor" %in% names(all_stats_aggregated))) {
    message("Aggregated statistics are empty or missing 'Sensor' column. Cannot generate summary sheets.")
    addWorksheet(wb, "Error")
    writeData(wb, sheet = "Error", x = "Failed to aggregate statistics for summary sheets.")
    saveWorkbook(wb, output_file, overwrite = TRUE)
    return()
  }

  sensors <- unique(all_stats_aggregated$Sensor)
  metrics <- setdiff(colnames(results[[1]]), "Year") # Metrics like first10, last5 etc.
  
  summary_df_list <- lapply(metrics, function(metric) {
    metric_summary <- all_stats_aggregated %>%
      group_by(Sensor) %>%
      summarise(
        mean_val = mean(get(metric), na.rm = TRUE),
        sd_val = sd(get(metric), na.rm = TRUE),
        median_val = median(get(metric), na.rm = TRUE),
        mad_val = mad(get(metric), na.rm = TRUE),
        min_val = if(all(is.na(get(metric)))) NA else min(get(metric), na.rm = TRUE),
        max_val = if(all(is.na(get(metric)))) NA else max(get(metric), na.rm = TRUE),
        count_val = sum(!is.na(get(metric))),
        rollmean3_val = if(sum(!is.na(get(metric))) < 3) NA else mean(tail(sort(get(metric)[!is.na(get(metric))]), 3)),
        .groups = 'drop'
      )
    colnames(metric_summary) <- c("Sensor", paste0(metric, "_", c("mean", "sd", "median", "mad", "min", "max", "count", "rollmean3")))
    return(metric_summary)
  })
  
  summary_df <- Reduce(function(x, y) merge(x, y, by = "Sensor", all = TRUE), summary_df_list)
  summary_df$full_pct_nonmissing <- 100 * summary_df$full_count / length(results)

  # --- Comprehensive summary (all sensors) ---
  summary_df_all <- summary_df
  addWorksheet(wb, "Summary_All")
  writeData(wb, sheet = "Summary_All", x = summary_df_all, headerStyle = headerStyle, rowNames = FALSE) # rowNames=FALSE as Sensor is a column
  freezePane(wb, sheet = "Summary_All", firstRow = TRUE)
  csv_all <- sub("\\.xlsx$", "_all.csv", output_file)
  write.csv(summary_df_all, csv_all, row.names = FALSE)
  message(sprintf("Comprehensive summary CSV ('Summary_All') written to %s", csv_all))

  # --- Filtered summary (sufficient data only) ---
  min_data_points <- 5 # Min years of 'full' data for a sensor to be in "Sufficient" summary
  summary_df_sufficient <- summary_df_all[which(summary_df_all$full_count >= min_data_points), ]
  addWorksheet(wb, "Summary_Sufficient")
  writeData(wb, sheet = "Summary_Sufficient", x = summary_df_sufficient, headerStyle = headerStyle, rowNames = FALSE)
  freezePane(wb, sheet = "Summary_Sufficient", firstRow = TRUE)
  csv_sufficient <- sub("\\.xlsx$", "_sufficient.csv", output_file)
  write.csv(summary_df_sufficient, csv_sufficient, row.names = FALSE)
  message(sprintf("Filtered summary CSV ('Summary_Sufficient') written to %s", csv_sufficient))

  # --- Main Summary (based on sufficient data) with highlighting ---
  summary_df_for_main_sheet <- summary_df_sufficient
  if(nrow(summary_df_for_main_sheet) > 0) {
    sd_threshold <- 2 # Example threshold for flagging high variability
    summary_df_for_main_sheet$flag_high_variability <- summary_df_for_main_sheet$full_sd > sd_threshold

    if ("within_diff_mean" %in% colnames(summary_df_for_main_sheet)) {
      abs_diff_values <- abs(summary_df_for_main_sheet$within_diff_mean)
      num_top_sensors_to_csv <- min(highlight_top_n, nrow(summary_df_for_main_sheet[!is.na(abs_diff_values),]))
      if(num_top_sensors_to_csv > 0) {
        top_sensors_data <- summary_df_for_main_sheet[order(-abs_diff_values), ][1:num_top_sensors_to_csv, 
                                  c("Sensor", "within_diff_mean", "full_mean", "full_sd", "full_pct_nonmissing")]
        write.csv(top_sensors_data, sub("\\.xlsx$", "_top_sensors.csv", output_file), row.names = FALSE)
        message(sprintf("Top %d sensors CSV written to %s", num_top_sensors_to_csv, sub("\\.xlsx$", "_top_sensors.csv", output_file)))
      }
    }

    addWorksheet(wb, "Summary") # Main summary sheet
    writeData(wb, sheet = "Summary", x = summary_df_for_main_sheet, headerStyle = headerStyle)
    freezePane(wb, sheet = "Summary", firstRow = TRUE)
    
    if ("within_diff_mean" %in% colnames(summary_df_for_main_sheet)) {
      valid_diff_values <- summary_df_for_main_sheet$within_diff_mean[!is.na(summary_df_for_main_sheet$within_diff_mean)]
      num_to_highlight <- min(highlight_top_n, length(valid_diff_values))
      if (num_to_highlight > 0) {
          # Get indices from the original dataframe, accounting for NAs removed for ordering
          ordered_indices <- order(abs(summary_df_for_main_sheet$within_diff_mean), decreasing = TRUE)
          top_indices_for_highlight <- head(ordered_indices[!is.na(summary_df_for_main_sheet$within_diff_mean[ordered_indices])], num_to_highlight)

          if(length(top_indices_for_highlight) > 0) {
            highlightStyleRed <- createStyle(bgFill = "#FF9999") # Light red for highlight
            addStyle(wb, sheet = "Summary", style = highlightStyleRed, 
                     rows = top_indices_for_highlight + 1, # +1 for header
                     cols = which(colnames(summary_df_for_main_sheet) == "within_diff_mean") + 1, # +1 for rownames
                     gridExpand = TRUE, stack = TRUE)
          }
      } else { message("Not enough valid data in 'Summary' sheet to highlight top sensors by 'within_diff_mean'.") }
    }
  } else {
    message("Skipping 'Summary' sheet content and top sensors CSV as no sensors met the 'sufficient data' criteria.")
    addWorksheet(wb, "Summary")
    writeData(wb, sheet = "Summary", x = "No sensors met the 'sufficient data' criteria.", headerStyle = headerStyle)
  }
  
  saveWorkbook(wb, output_file, overwrite = TRUE)
  message(sprintf("Summary workbook written to %s", output_file))

  # Export main summary and robust summary CSVs
  csv_out_df <- if(nrow(summary_df_for_main_sheet) > 0) summary_df_for_main_sheet else data.frame()
  write.csv(csv_out_df, sub("\\.xlsx$", ".csv", output_file), row.names = FALSE)
  message(sprintf("Main summary CSV (from 'Summary' sheet data) written to %s", sub("\\.xlsx$", ".csv", output_file)))
  
  write.csv(csv_out_df, sub("\\.xlsx$", "_robust.csv", output_file), row.names = FALSE) # Re-using the same df for "robust"
  message(sprintf("Robust summary CSV (same as main 'Summary' sheet data) written to %s", sub("\\.xlsx$", "_robust.csv", output_file)))
}

# Main execution block: Script entry point if run directly:
# Sets up data directory, processes all files, and generates summary outputs.
# All messages, warnings, and errors during execution are caught by handlers
# and written to 'processing_warnings.log'.
if (sys.nframe() == 0 || interactive()) { # Check if script is sourced or run directly
  withCallingHandlers({
    # Define the data directory relative to the script's location or current working directory.
    # Assumes a 'Data' subdirectory containing the SS_Yxx.txt files.
    data_dir <- file.path(getwd(), "Data") 
    message(sprintf("Starting Seatek data processing. Data directory: %s", data_dir))
    
    if (!dir.exists(data_dir)) {
      stop(sprintf("Data directory does not exist: %s. Please create it and place sensor files inside.", data_dir))
    }
    data_dir_normalized <- auto_detect_data_dir(data_dir) # Normalize path
    
    # Process all data files found in the directory
    results_list <- process_all_data(data_dir_normalized)
    
    # Define output summary file name
    summary_excel_file <- file.path(data_dir_normalized, "Seatek_Summary.xlsx")
    
    # Generate the summary Excel workbook and associated CSVs
    dump_summary_excel(results_list, summary_excel_file)
    
    message(sprintf("Processing complete. Summary Excel written to: %s", summary_excel_file))
  },
  warning = function(w) { 
    log_handler("WARNING", conditionMessage(w))
    invokeRestart("muffleWarning") # Continue execution after logging warning
  },
  error   = function(e) { 
    log_handler("ERROR", conditionMessage(e))
    # invokeRestart("muffleRestart") # This would attempt to continue, which might not be desired for all errors.
                                     # For critical errors, it's often better to let the script stop after logging.
    message(sprintf("An error occurred: %s. Check 'processing_warnings.log' for details.", conditionMessage(e)))
    # Depending on R environment, script might terminate here or require explicit quit().
  },
  message = function(m) { 
    log_handler("MESSAGE", conditionMessage(m))
    invokeRestart("muffleMessage") # Let message be printed to console as well, then log.
  })
}
# End of script
