# Updated Seatek Analysis Script
# Author: Abhi Mehrotra
# Last Updated: 2025-05-10
#
# Purpose:
# This script is the primary tool for processing and analyzing Seatek sensor data, 
# focusing on riverbed changes over time. It handles data from two main series:
#   - Series 28: Expects raw data files named 'SS_Yxx.txt' (e.g., SS_Y01.txt) 
#     typically located in 'Data/' or 'Series_28/Raw_Data/'.
#   - Series 26: Can also process 'S26_Yxx.txt' files if present in 'Series_26/Raw_Data/Text_Files/'.
#
# Processing Steps:
# 1. Reads raw sensor data files (.txt format).
# 2. Validates data and converts each raw file to an individual Excel file (.xlsx) in the 'Data/' directory (e.g., Data/SS_Y01.xlsx).
# 3. For each year/file, calculates summary metrics for each of the 32 sensors:
#    - 'first10': Mean of the first 10 valid readings.
#    - 'last5': Mean of the last 5 valid readings.
#    - 'full': Mean of all valid readings.
#    - 'within_diff': Difference between 'full' and 'first10'.
# 4. Generates a comprehensive multi-sheet Excel workbook ('Data/Seatek_Summary.xlsx') containing:
#    - A sheet for each processed year with the above metrics.
#    - 'Summary_All': Aggregated statistics (mean, sd, median, mad, min, max, count, 3-year rolling mean) for each sensor across all years.
#    - 'Summary_Sufficient': Similar to 'Summary_All', but filtered for sensors with a minimum number of data points.
#    - 'Summary': Main summary sheet, often based on 'Summary_Sufficient', may include highlighting.
# 5. Generates several CSV summary files in the 'Data/' directory:
#    - 'Data/Seatek_Summary.csv': Main summary (often from 'Summary_Sufficient').
#    - 'Data/Seatek_Summary_all.csv': Comprehensive summary statistics.
#    - 'Data/Seatek_Summary_robust.csv': Robust statistics summary.
#    - 'Data/Seatek_Summary_sufficient.csv': Filtered summary for sensors with sufficient data.
#    - 'Data/Seatek_Summary_top_sensors.csv': Data for top N sensors based on 'within_diff_mean'.
#
# Logging:
# All warnings, errors, and messages are logged to 'processing_warnings.log'.

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
log_file <- file.path(getwd(), "processing_warnings.log")
if (file.exists(log_file)) file.remove(log_file)
log_handler <- function(type, msg) {
  cat(sprintf("[%s] %s\n", type, msg), file=log_file, append=TRUE)
}

# Function: auto_detect_data_dir
# Purpose: Validates if the provided data directory exists and returns its normalized path.
# Parameters:
#   - data_dir: Character string. The path to the data directory.
# Returns:
#   Character string. The normalized absolute path to the data directory.
#   Stops execution if the directory is not found.
auto_detect_data_dir <- function(data_dir) {
  if (missing(data_dir) || !dir.exists(data_dir)) {
    stop(sprintf("Data directory not found: %s", data_dir))
  }
  normalizePath(data_dir)
}

# Function: read_sensor_data
# Purpose: Reads a single Seatek sensor data file (.txt). It expects space-separated values.
#          The function names the first 32 columns as 'Sensor01' through 'Sensor32'
#          and the 33rd column (if present) as 'Timestamp'.
# Parameters:
#   - file_path: Character string. The full path to the sensor data file.
#   - sep: Character. The separator used in the file (default is " ").
# Returns:
#   A data.table object containing the sensor readings and timestamp.
#   Stops execution if the file is invalid or cannot be read.
#   Issues a warning if fewer than 33 columns are found.
read_sensor_data <- function(file_path, sep = " ") {
  file_path <- normalizePath(file_path) # Ensure path is absolute and normalized
  message(sprintf("Reading sensor file: %s", basename(file_path)))
  
  # Validate file existence and extension
  if (!file.exists(file_path) || !grepl("\\.txt$", file_path, ignore.case = TRUE)) {
    stop(sprintf("Invalid file: %s. Must be a .txt file.", file_path))
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
    warning(sprintf("File %s has only %d columns; expected at least 33 (32 sensors + 1 timestamp). Sensor data might be incomplete.", basename(file_path), ncol(dt)))
  }
  
  total_cols <- ncol(dt)
  sensor_cols <- min(total_cols - 1, 32) # Number of sensor columns to actually name (max 32)
  
  # Name sensor columns (Sensor01, Sensor02, ...)
  setnames(dt, 1:sensor_cols, paste0("Sensor", sprintf("%02d", 1:sensor_cols)))
  
  # Name timestamp column if it exists
  if (total_cols >= (sensor_cols + 1)) {
    setnames(dt, sensor_cols + 1, "Timestamp")
    # Select only the named sensor columns and the Timestamp column
    dt <- dt[, c(paste0("Sensor", sprintf("%02d", 1:sensor_cols)), "Timestamp"), with = FALSE]
    
    # Convert timestamp if it's numeric (e.g., Unix epoch time)
    # Ensure to handle potential NA values in Timestamp before conversion
    if (is.numeric(dt$Timestamp) && all(!is.na(dt$Timestamp) | is.na(dt$Timestamp))) { # Check if column is numeric-like
        # Check if all non-NA values are indeed numeric
        if (all(sapply(dt$Timestamp[!is.na(dt$Timestamp)], is.numeric))) {
             dt[, Timestamp := as.POSIXct(as.numeric(Timestamp), origin = "1970-01-01")]
        } else {
            warning(sprintf("Timestamp column in %s contains non-numeric values and will not be converted to POSIXct.", basename(file_path)))
        }
    } else if (!is.numeric(dt$Timestamp)) {
        # Attempt to parse if it's character and looks like a date/datetime
        # This is a placeholder for more robust date parsing if needed
        # For now, we assume if it's not numeric, it's pre-formatted or non-standard
        message(sprintf("Timestamp in %s is not strictly numeric. Attempting to use as is or may require manual conversion.", basename(file_path)))
    }
  } else {
    # If no timestamp column, select only sensor columns
    warning(sprintf("No Timestamp column found or named in %s. Only sensor data will be available.", basename(file_path)))
    dt <- dt[, paste0("Sensor", sprintf("%02d", 1:sensor_cols)), with = FALSE]
  }
  return(dt)
}

# Function: process_all_data
# Purpose: Processes all relevant Seatek sensor data files found in specified directories.
#          It handles Series 28 ('SS_Yxx.txt') files from 'data_dir_series28' (typically 'Data/' or 'Series_28/Raw_Data/')
#          and Series 26 ('S26_Yxx.txt') files from 'data_dir_series26' (typically 'Series_26/Raw_Data/Text_Files/').
#          For each file, it reads the data, exports the raw data to an Excel file in 'Data/',
#          and computes summary metrics (first10, last5, full, within_diff).
# Parameters:
#   - data_dir_series28: Character string. Path to the directory containing Series 28 'SS_Yxx.txt' files.
#   - data_dir_series26: Character string. Path to the directory containing Series 26 'S26_Yxx.txt' files.
#   - output_dir_raw_excel: Character string. Path to the directory where individual year Excel files are saved (typically 'Data/').
# Returns:
#   A list named 'results'. Each element in the list corresponds to a processed file/year.
#   The name of each element is the 'sheet_name' (e.g., "1995" for Y01).
#   Each element contains a data.frame with metrics (first10, last5, full, within_diff) for 32 sensors.
#   Stops if no sensor files are found for either series.
process_all_data <- function(data_dir_series28, data_dir_series26, output_dir_raw_excel) {
  # Validate directories
  data_dir_s28 <- auto_detect_data_dir(data_dir_series28)
  data_dir_s26 <- auto_detect_data_dir(data_dir_series26)
  output_dir_excel <- auto_detect_data_dir(output_dir_raw_excel)

  # Define patterns for Series 28 and Series 26 files
  pattern_s28 <- "^SS_Y[0-9]{2}\\.txt$"
  pattern_s26 <- "^S26_Y[0-9]{2}\\.txt$"

  files_s28 <- list.files(data_dir_s28, pattern = pattern_s28, full.names = TRUE)
  files_s26 <- list.files(data_dir_s26, pattern = pattern_s26, full.names = TRUE)
  
  all_files <- c(files_s28, files_s26)

  if (length(all_files) == 0) {
    stop(sprintf("No sensor files found matching patterns '%s' in %s OR '%s' in %s", 
                 pattern_s28, data_dir_s28, pattern_s26, data_dir_s26))
  }

  results <- list()
  for (f in all_files) {
    df <- read_sensor_data(f) # Assumes read_sensor_data can handle both S26 and SS naming for columns if they differ structurally
    
    # Export raw data to Excel in the specified output directory (e.g., Data/)
    # The Excel filename is based on the original .txt filename (e.g., SS_Y01.xlsx or S26_Y01.xlsx)
    out_raw_excel_path <- file.path(output_dir_excel, paste0(tools::file_path_sans_ext(basename(f)), ".xlsx"))
    write.xlsx(df, out_raw_excel_path, overwrite = TRUE)
    message(sprintf("Raw data for %s written to %s", basename(f), out_raw_excel_path))
    
    # Compute summary metrics
    # Ensure calculations are robust to missing sensors or all-NA columns
    num_sensors_to_process <- min(ncol(df) -1, 32) # Process up to 32 sensors or fewer if data has less
    if ("Timestamp" %in% names(df)) {
        sensor_data_cols <- df[, 1:num_sensors_to_process, with = FALSE]
    } else {
        sensor_data_cols <- df[, 1:num_sensors_to_process, with = FALSE] # No timestamp column
    }

    clean_vals <- function(x) { # Helper to remove NA and non-positive values before mean
        x_cleaned <- x[!is.na(x) & x > 0]
        if(length(x_cleaned) == 0) NA else x_cleaned # Return NA if no valid data points
    }
    
    first10 <- sapply(sensor_data_cols, function(x) mean(clean_vals(head(x, 10)), na.rm = TRUE))
    last5  <- sapply(sensor_data_cols, function(x) mean(clean_vals(tail(x, 5)), na.rm = TRUE))
    full   <- sapply(sensor_data_cols, function(x) mean(clean_vals(x), na.rm = TRUE))
    diff   <- full - first10
    
    # Derive sheet/year name from filename (e.g., SS_Y01.txt -> "1995")
    # Handles both SS_Yxx.txt and S26_Yxx.txt patterns
    year_tag_match <- regexpr("(SS_Y|S26_Y)([0-9]{2})\\.txt$", basename(f), ignore.case = TRUE)
    year_tag_str <- regmatches(basename(f), year_tag_match)
    year_digits <- sub("(SS_Y|S26_Y)", "", year_tag_str[1], ignore.case = TRUE) # Extracts "01", "02", etc.
    year_digits <- sub("\\.txt$", "", year_digits, ignore.case = TRUE) # remove .txt suffix

    year_num <- as.integer(year_digits)
    
    # Map Y01 to 1995, Y02 to 1996, ..., Y20 to 2014. Consistent for S26 and SS.
    sheet_name <- if (!is.na(year_num) && year_num >= 1 && year_num <= 20) {
      as.character(1994 + year_num) 
    } else {
      # Fallback sheet name if pattern doesn't match expected Yxx format
      tools::file_path_sans_ext(basename(f)) 
    }
    
    # Pad results if fewer than 32 sensors were processed to ensure data.frame has 32 rows
    metrics_df <- data.frame(
        first10 = first10,
        last5 = last5,
        full = full,
        within_diff = diff
        # row.names are set implicitly by sapply if sensor_data_cols had names,
        # otherwise, they will be V1, V2 etc. We need consistent Sensor01-Sensor32 names.
    )

    # Ensure 32 sensor rows with consistent names (Sensor01 to Sensor32)
    # Initialize a template data frame with all 32 sensor names
    sensor_names_std <- paste0("Sensor", sprintf("%02d", 1:32))
    final_metrics_df <- data.frame(row.names = sensor_names_std)
    
    # Populate with calculated metrics, matching by original sensor names if available
    # current_sensor_names <- names(first10) # These should be Sensor01, Sensor02...
    current_sensor_names <- paste0("Sensor", sprintf("%02d", 1:num_sensors_to_process))


    final_metrics_df$first10 <- NA
    final_metrics_df$last5 <- NA
    final_metrics_df$full <- NA
    final_metrics_df$within_diff <- NA

    final_metrics_df[current_sensor_names, "first10"] <- first10
    final_metrics_df[current_sensor_names, "last5"] <- last5
    final_metrics_df[current_sensor_names, "full"] <- full
    final_metrics_df[current_sensor_names, "within_diff"] <- diff
    
    results[[sheet_name]] <- final_metrics_df
  }
  return(results)
}

# Function: dump_summary_excel
# Purpose: Writes the processed results into a multi-sheet Excel workbook and several CSV files.
#          The Excel workbook includes:
#          - A sheet for each year with its sensor metrics.
#          - 'Summary_All': All sensors, all years, with mean, sd, median, mad, min, max, count, 3yr rolling mean.
#          - 'Summary_Sufficient': Filtered version of 'Summary_All' for sensors with enough data points.
#          - 'Summary': Typically based on 'Summary_Sufficient', may include highlighting for top N sensors.
#          Corresponding CSV files are also generated.
# Parameters:
#   - results: List. The output from `process_all_data`. Each element is a data.frame for a year.
#   - output_file: Character string. The path for the output Excel file (e.g., "Data/Seatek_Summary.xlsx").
#   - highlight_top_n: Integer. Number of top sensors to highlight in the 'Summary' sheet based on 'within_diff_mean'.
# Returns:
#   Invisible. The function primarily writes files.
dump_summary_excel <- function(results, output_file, highlight_top_n = 5) {
  wb <- createWorkbook()
  headerStyle <- createStyle(textDecoration = "bold") # Style for headers

  # --- Write each year's data to a separate sheet ---
  for (year_sheet_name in names(results)) {
    addWorksheet(wb, year_sheet_name)
    df_year <- as.data.frame(results[[year_sheet_name]]) # Ensure it's a data.frame
    # writeData includes row names if rowNames = TRUE and df_year has them (which it should from process_all_data)
    writeData(wb, sheet = year_sheet_name, x = df_year, rowNames = TRUE, headerStyle = headerStyle)
    freezePane(wb, sheet = year_sheet_name, firstRow = TRUE) # Freeze header row
    
    # Optional: highlight the sensor with the largest absolute 'within_diff' in each year's sheet
    if ("within_diff" %in% colnames(df_year) && nrow(df_year) > 0) {
      # Calculate absolute differences, handling potential NAs
      abs_diffs <- abs(df_year$within_diff)
      valid_diffs <- !is.na(abs_diffs)
      if(any(valid_diffs)){
          max_idx <- which(abs_diffs == max(abs_diffs[valid_diffs], na.rm = TRUE))[1] # Get first max index
          highlightStyle <- createStyle(bgFill = "#FFD700") # Yellow highlight
          # +1 for rows because of header, +1 for cols because of rownames
          addStyle(wb, sheet = year_sheet_name, style = highlightStyle, rows = max_idx + 1, 
                   cols = which(colnames(df_year) == "within_diff") + 1, 
                   gridExpand = TRUE, stack = TRUE)
      }
    }
  }

  # --- Aggregate stats for summary sheets ---
  # Combine all years' data; `do.call(rbind, ...)` assumes consistent column names and structure
  # Each element of results is a data.frame with sensors as rownames and metrics as columns
  all_stats_list <- lapply(names(results), function(year_name) {
      df <- results[[year_name]]
      df$Sensor <- rownames(df) # Add sensor names as a column
      df$Year <- year_name     # Add year as a column
      return(df)
  })
  all_stats_long <- do.call(rbind, all_stats_list) # Long format: Sensor, Year, metrics...

  # Pivot to a format suitable for calculating stats per sensor across years
  # We need to gather metrics for each sensor-year combination first
  # This part seems overly complex in the original; simplifying the aggregation logic.
  # The goal is to have, for each sensor, a list or vector of its 'first10', 'last5', etc., across all years.

  sensors <- unique(all_stats_long$Sensor) # Should be Sensor01-Sensor32
  metrics_to_summarize <- c("first10", "last5", "full", "within_diff")
  
  summary_stats_list <- list()

  for (sensor_id in sensors) {
    sensor_data_all_years <- all_stats_long[all_stats_long$Sensor == sensor_id, metrics_to_summarize, drop = FALSE]
    # For each metric, calculate mean, sd, median, mad, min, max, count, rollmean3
    sensor_summary <- list(Sensor = sensor_id)
    for (metric in metrics_to_summarize) {
      metric_values <- sensor_data_all_years[[metric]][!is.na(sensor_data_all_years[[metric]])] # Valid values for the current metric

      sensor_summary[[paste0(metric, "_mean")]] <- if(length(metric_values) > 0) mean(metric_values) else NA
      sensor_summary[[paste0(metric, "_sd")]] <- if(length(metric_values) > 1) sd(metric_values) else NA # sd needs n > 1
      sensor_summary[[paste0(metric, "_median")]] <- if(length(metric_values) > 0) median(metric_values) else NA
      sensor_summary[[paste0(metric, "_mad")]] <- if(length(metric_values) > 0) mad(metric_values) else NA
      sensor_summary[[paste0(metric, "_min")]] <- if(length(metric_values) > 0) min(metric_values) else NA
      sensor_summary[[paste0(metric, "_max")]] <- if(length(metric_values) > 0) max(metric_values) else NA
      sensor_summary[[paste0(metric, "_count")]] <- length(metric_values)
      # 3-year rolling mean (mean of last 3 available data points for that sensor-metric)
      sensor_summary[[paste0(metric, "_rollmean3")]] <- if(length(metric_values) >= 3) mean(tail(metric_values, 3)) else NA
    }
    summary_stats_list[[sensor_id]] <- as.data.frame(sensor_summary)
  }
  summary_df <- do.call(rbind, summary_stats_list) # This is the base for Summary_All

  # Calculate percent non-missing for 'full' metric (percentage of years a sensor has 'full' data)
  total_years <- length(names(results))
  summary_df$full_pct_nonmissing <- 100 * summary_df$full_count / total_years

  # --- Comprehensive summary (all sensors) sheet and CSV ('Summary_All') ---
  summary_df_all <- summary_df # This data frame contains all sensors
  addWorksheet(wb, "Summary_All")
  writeData(wb, sheet = "Summary_All", x = summary_df_all, headerStyle = headerStyle, rowNames = FALSE) # rowNames=FALSE as Sensor is a column
  freezePane(wb, sheet = "Summary_All", firstRow = TRUE)
  csv_all_path <- sub("\\.xlsx$", "_all.csv", output_file)
  write.csv(summary_df_all, csv_all_path, row.names = FALSE)
  message(sprintf("Comprehensive summary (all sensors) CSV written to %s", csv_all_path))

  # --- Filtered summary (sufficient data only) sheet and CSV ('Summary_Sufficient') ---
  # Sensors are included if they have at least 'min_data_points_for_summary' valid data points for the 'full' metric.
  min_data_points_for_summary <- 5 
  summary_df_sufficient <- summary_df_all[which(summary_df_all$full_count >= min_data_points_for_summary), ]
  addWorksheet(wb, "Summary_Sufficient")
  writeData(wb, sheet = "Summary_Sufficient", x = summary_df_sufficient, headerStyle = headerStyle, rowNames = FALSE)
  freezePane(wb, sheet = "Summary_Sufficient", firstRow = TRUE)
  csv_sufficient_path <- sub("\\.xlsx$", "_sufficient.csv", output_file)
  write.csv(summary_df_sufficient, csv_sufficient_path, row.names = FALSE)
  message(sprintf("Filtered summary (sufficient data) CSV written to %s", csv_sufficient_path))

  # --- Main 'Summary' sheet (typically based on sufficient data) and CSV ---
  # This summary_df will be used for further specific outputs like top sensors.
  # Depending on requirements, this could be summary_df_all or summary_df_sufficient. Using sufficient here.
  main_summary_df <- summary_df_sufficient 
  
  # Flag high-variability sensors based on 'full_sd' (standard deviation of the 'full' metric average)
  sd_threshold_variability <- 2 # Example threshold, adjust as needed
  main_summary_df$flag_high_variability <- ifelse(!is.na(main_summary_df$full_sd) & main_summary_df$full_sd > sd_threshold_variability, TRUE, FALSE)

  # Prepare and export top N sensors based on absolute 'within_diff_mean'
  # This uses main_summary_df (which is summary_df_sufficient here)
  if ("within_diff_mean" %in% colnames(main_summary_df) && nrow(main_summary_df) > 0) {
    # Order by absolute mean of within_diff, descending. Handle NAs in ordering.
    ordered_sensors <- main_summary_df[order(-abs(main_summary_df$within_diff_mean %||% 0)), ] # %||% 0 to handle NAs in ordering
    num_top_sensors_to_export <- min(highlight_top_n, nrow(ordered_sensors))
    top_sensors_df <- ordered_sensors[1:num_top_sensors_to_export, 
                                    c("Sensor", "within_diff_mean", "full_mean", "full_sd", "full_pct_nonmissing")]
    csv_top_sensors_path <- sub("\\.xlsx$", "_top_sensors.csv", output_file)
    write.csv(top_sensors_df, csv_top_sensors_path, row.names = FALSE)
    message(sprintf("Top %d sensors CSV written to %s", num_top_sensors_to_export, csv_top_sensors_path))
  }

  # Add the main 'Summary' sheet to the workbook
  addWorksheet(wb, "Summary") # This is the main summary sheet
  writeData(wb, sheet = "Summary", x = main_summary_df, headerStyle = headerStyle, rowNames = FALSE)
  freezePane(wb, sheet = "Summary", firstRow = TRUE)
  
  # Highlight top N sensors (by abs_within_diff_mean) in the 'Summary' sheet
  if ("within_diff_mean" %in% colnames(main_summary_df) && nrow(main_summary_df) > 0) {
    # Ensure within_diff_mean is numeric for ordering, replace NA with a value that sends it to bottom if not of interest
    diff_values_for_ranking <- main_summary_df$within_diff_mean
    # NAs in diff_values_for_ranking will be ordered last by default with na.last=TRUE in order()
    # We want to rank by absolute value, so NAs should not interfere with ranking actual numbers.
    abs_diff_values <- abs(diff_values_for_ranking)
    # Get indices of top N sensors, ensuring to handle cases with fewer than N sensors or NAs.
    # `order` with `na.last=NA` removes NAs before ordering.
    valid_indices <- which(!is.na(abs_diff_values))
    ordered_valid_indices <- order(abs_diff_values[valid_indices], decreasing = TRUE)
    top_n_indices_in_main_df <- valid_indices[ordered_valid_indices[1:min(highlight_top_n, length(ordered_valid_indices))]]

    if(length(top_n_indices_in_main_df) > 0) {
        highlightStyle <- createStyle(bgFill = "#FF9999") # Light red highlight
        # Apply style to the rows of these top sensors for the 'within_diff_mean' column
        # +1 for rows because of header row in Excel sheet
        addStyle(wb, sheet = "Summary", style = highlightStyle, 
                 rows = top_n_indices_in_main_df + 1, 
                 cols = which(colnames(main_summary_df) == "within_diff_mean") + 0, # +0 because rowNames=FALSE
                 gridExpand = FALSE, stack = TRUE) # gridExpand=FALSE if only one cell, TRUE for row
    }
  }
  
  # Save the final Excel workbook
  saveWorkbook(wb, output_file, overwrite = TRUE)
  message(sprintf("Main summary Excel workbook written to %s", output_file))
  
  # Export the main summary data (used in 'Summary' sheet) to a CSV file ('Seatek_Summary.csv')
  csv_main_summary_path <- sub("\\.xlsx$", ".csv", output_file)
  write.csv(main_summary_df, csv_main_summary_path, row.names = FALSE)
  message(sprintf("Main summary CSV written to %s", csv_main_summary_path))
  
  # Export robust stats as CSV (this was `summary_df` which is `summary_df_all` here)
  # If "robust" means the one with MAD, then it's already part of summary_df_all and main_summary_df
  # The original script wrote `summary_df` (which was `summary_df_sufficient`) to `_robust.csv`.
  # Let's stick to that for consistency, so using `main_summary_df`.
  csv_robust_path <- sub("\\.xlsx$", "_robust.csv", output_file)
  write.csv(main_summary_df, csv_robust_path, row.names = FALSE) # Using main_summary_df for robust stats CSV
  message(sprintf("Robust summary stats CSV written to %s", csv_robust_path))
}

# Main execution block: Script entry point if run directly
if (sys.nframe() == 0 || interactive()) { # Check if script is sourced or run directly
  withCallingHandlers({
    # Define base directory for Series 28 and output files (typically 'Data/')
    # Define base directory for Series 26 raw data
    # Define output directory for yearly raw data excel files
    
    # As per README: SS_Yxx.txt are in Data/ or Series_28/Raw_Data/
    # S26_Yxx.txt are in Series_26/Raw_Data/Text_Files/
    # All outputs (Excel summaries, CSVs, individual year Excels) go to Data/
    
    base_dir <- getwd() # Project root
    dir_s28_primary <- file.path(base_dir, "Data")
    dir_s28_secondary <- file.path(base_dir, "Series_28", "Raw_Data")
    dir_s26 <- file.path(base_dir, "Series_26", "Raw_Data", "Text_Files")
    
    # Determine which Series 28 directory to use (prioritize secondary if it has files)
    # This logic could be improved, e.g. by processing from both if files exist in both.
    # For now, let's assume primary SS_Yxx location is Data/, unless Series_28/Raw_Data/ is populated.
    # However, the script `process_all_data` now takes both S28 and S26 dirs.
    # The `Data` directory is also the main output directory.

    # Let's assume `Updated_Seatek_Analysis.R` primarily processes SS_Yxx from `Data/`
    # and S26_Yxx from `Series_26/Raw_Data/Text_Files/`
    # The individual `SS_Yxx.xlsx` and `S26_Yxx.xlsx` will be written to `Data/`
    
    # Path for Series 28 input files (SS_Yxx.txt)
    # The script currently reads SS_Yxx.txt from `data_dir_series28`.
    # If SS_Yxx.txt are in `Data/` they will be processed.
    # If they are in `Series_28/Raw_Data/` then `data_dir_series28` should point there.
    # Let's assume for now that if `Series_28/Raw_Data` contains SS_Yxx.txt, those are the ones to use.
    # Otherwise, use `Data/` for SS_Yxx.txt. This is a common pattern if `Data/` is a staging area.

    actual_data_dir_s28 <- dir_s28_primary # Default to Data/ for SS_Yxx.txt files
    # Check if Series_28/Raw_Data contains the target files. If so, prefer it.
    if (dir.exists(dir_s28_secondary) && length(list.files(dir_s28_secondary, pattern = "^SS_Y[0-9]{2}\\.txt$")) > 0) {
        actual_data_dir_s28 <- dir_s28_secondary
        message(sprintf("Using %s for Series 28 SS_Yxx.txt files.", actual_data_dir_s28))
    } else {
        message(sprintf("Using %s for Series 28 SS_Yxx.txt files (as %s was empty or non-existent for these files).", actual_data_dir_s28, dir_s28_secondary))
    }

    actual_data_dir_s26 <- dir_s26 # For S26_Yxx.txt files
    output_dir_for_yearly_excel <- dir_s28_primary # All yearly Excel files (SS_Yxx.xlsx, S26_Yxx.xlsx) go to Data/
    main_output_summary_dir <- dir_s28_primary # All summary files (Seatek_Summary.xlsx, .csv) go to Data/

    message(sprintf("Processing Series 28 data from: %s", actual_data_dir_s28))
    message(sprintf("Processing Series 26 data from: %s", actual_data_dir_s26))
    message(sprintf("Yearly Excel outputs will be saved to: %s", output_dir_for_yearly_excel))
    message(sprintf("Main summary outputs will be saved to: %s", main_output_summary_dir))

    if (!dir.exists(actual_data_dir_s28)) { stop(sprintf("Series 28 data directory does not exist: %s", actual_data_dir_s28)) }
    if (!dir.exists(actual_data_dir_s26)) { stop(sprintf("Series 26 data directory does not exist: %s", actual_data_dir_s26)) }
    if (!dir.exists(output_dir_for_yearly_excel)) { dir.create(output_dir_for_yearly_excel, recursive = TRUE, showWarnings = FALSE) }
    
    # Call process_all_data with the determined directories
    results <- process_all_data(
        data_dir_series28 = actual_data_dir_s28, 
        data_dir_series26 = actual_data_dir_s26,
        output_dir_raw_excel = output_dir_for_yearly_excel
    )
    
    # Define output path for the main summary Excel file
    summary_out_excel_path <- file.path(main_output_summary_dir, "Seatek_Summary.xlsx")
    
    # Generate the summary Excel and CSV files
    dump_summary_excel(results, summary_out_excel_path)
    
    message("Processing complete.")
  },
  warning = function(w) { log_handler("WARNING", conditionMessage(w)); invokeRestart("muffleWarning") }, # Log warning and continue
  error   = function(e) { log_handler("ERROR", conditionMessage(e)); }, # Log error and stop (default behavior)
  message = function(m) { log_handler("MESSAGE", conditionMessage(m)); invokeRestart("muffleMessage") } # Log message and continue
  )
}
# End of script
