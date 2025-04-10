# Complete Updated Seatek Analysis Script
# Author: Abhi Mehrotra
# Last Updated: 2024-03-17
# Revised: 2024-03-17

# This script processes Seatek sensor data to analyze riverbed changes over time.
# It handles multiple file formats, performs various calculations, and generates
# comprehensive Excel reports with proper formatting.

#' Load and verify required packages
required_packages <- c("data.table", "openxlsx", "dplyr", "tidyr")

install_required_packages <- function() {
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg)
    }
    library(pkg, character.only = TRUE)
  }
}

# Install and load required packages
install_required_packages()

#' Enhanced path normalization function to handle directory and file paths
#' @param path Path to normalize
#' @param is_directory Boolean indicating if the path is to a directory
#' @return Normalized path
normalize_path <- function(path, is_directory = NULL) {
  # Print original path for debugging
  cat("--------------------------------------\n")
  cat("PATH NORMALIZATION DEBUG INFO:\n")
  cat("--------------------------------------\n")
  cat("Original path: ", path, "\n")
  cat("Current working directory: ", getwd(), "\n")
  cat("Home directory: ", Sys.getenv("HOME"), "\n")
  
  # Auto-detect if it's a directory unless explicitly specified
  if (is.null(is_directory)) {
    is_directory <- !grepl("\\.[^\\.]+$", basename(path)) # No file extension means likely directory
    cat("Auto-detected path type: ", ifelse(is_directory, "DIRECTORY", "FILE"), "\n")
  } else {
    cat("Explicitly specified path type: ", ifelse(is_directory, "DIRECTORY", "FILE"), "\n")
  }
  
  # First expand any ~
  path <- path.expand(path)
  cat("After path.expand: ", path, "\n")
  
  # Verification function based on path type
  verify_path <- function(p) {
    if (is_directory) {
      return(dir.exists(p))
    } else {
      return(file.exists(p))
    }
  }
  
  # Try exact path first
  if (verify_path(path)) {
    cat("Path exists exactly as provided\n")
    return(normalizePath(path, mustWork = TRUE))
  }
  
  # Then normalize
  path <- tryCatch(
    normalizePath(path, mustWork = FALSE),
    error = function(e) path
  )
  
  # Create all possible path variations
  cat("Generating path variations...\n")
  # Case 1: Convert "R Projects" to "RProjects" and vice versa
  # Case 2: Replace ~ with full home path
  # Case 3: Try different combinations
  possible_paths <- c(
    path,
    gsub("R Projects", "RProjects", path),
    gsub("RProjects", "R Projects", path),
    gsub("~/", paste0(Sys.getenv("HOME"), "/"), path),
    gsub("~/", paste0(Sys.getenv("HOME"), "/"), gsub("RProjects", "R Projects", path)),
    gsub("~/", paste0(Sys.getenv("HOME"), "/"), gsub("R Projects", "RProjects", path)),
    # Also try unix path separator conversions
    gsub("\\\\", "/", path)
  )
  
  # Make sure all paths are unique
  possible_paths <- unique(possible_paths)
  
  # Try each path
  for (idx in seq_along(possible_paths)) {
    possible_path <- possible_paths[idx]
    cat(sprintf("[%d/%d] Trying path: %s", idx, length(possible_paths), possible_path), "\n")
    
    if (verify_path(possible_path)) {
      cat("✓ Found existing path!\n")
      cat("--------------------------------------\n")
      return(normalizePath(possible_path, mustWork = TRUE))
    } else {
      cat("✗ Path not found\n")
    }
  }
  
  # If we got here, try absolute paths specific to this project
  cat("Trying standard absolute paths for this project...\n")
  absolute_paths <- c(
    paste0("/Users/", Sys.getenv("USER"), "/RProjects/Seatek_Analysis/Data"),
    paste0("/Users/", Sys.getenv("USER"), "/R Projects/Seatek_Analysis/Data"),
    # Add more specific paths that might be relevant
    paste0(getwd(), "/Data"),
    paste0(dirname(getwd()), "/Seatek_Analysis/Data"),
    paste0(Sys.getenv("HOME"), "/RProjects/Seatek_Analysis/Data"),
    paste0(Sys.getenv("HOME"), "/R Projects/Seatek_Analysis/Data"),
    "Data" # Relative to current directory
  )
  
  # Make sure all paths are unique
  absolute_paths <- unique(absolute_paths)
  
  for (idx in seq_along(absolute_paths)) {
    abs_path <- absolute_paths[idx]
    cat(sprintf("[%d/%d] Trying absolute path: %s", idx, length(absolute_paths), abs_path), "\n")
    
    if (verify_path(abs_path)) {
      cat("✓ Found existing absolute path!\n")
      cat("--------------------------------------\n")
      return(normalizePath(abs_path, mustWork = TRUE))
    } else {
      cat("✗ Path not found\n")
    }
  }
  
  # If all else fails, return the original normalized path with a warning
  warning(paste0("Could not find an existing path for: ", path, 
                "\nTried ", length(possible_paths) + length(absolute_paths), 
                " different path variations."))
  cat("❌ No existing path found. Returning original path: ", path, "\n")
  cat("❌ THIS WILL LIKELY CAUSE AN ERROR WHEN USED!\n")
  cat("--------------------------------------\n")
  return(path)
}

# Forward declaration of verify_data_directory function (defined later)

#' Configuration settings
config <- list(
  # Excel styling options
  excel_styles = list(
    header = list(
      textDecoration = "bold",
      border = "bottom",
      fgFill = "#E2E2E2"
    ),
    number_format = "0.000",
    date_format = "YYYY-MM-DD"
  ),
  
  # Sheet ordering
  sheet_order = c(
    "0. Analysis Info",
    "1. First 5 Averages",
    "2. Last 5 Averages",
    "3. Full Run Averages",
    "4. Within Year Differences",
    "5. NAVD88 Converted",
    "6. Year-to-Year Differences"
  ),
  
  # River Mile offsets
  river_mile_offsets = list(
    "RM 54.0" = list(sensors = 1:2, offset = 15),
    "RM 53.0" = list(sensors = 3:4, offset = 15),
    "RM 51.9" = list(sensors = 5:6, offset = 15),
    "RM 50.5" = list(sensors = 7:8, offset = 10),
    "RM 46.0" = list(sensors = 9:12, offset = 7),
    "RM 42.1" = list(sensors = 13:16, offset = 18),
    "RM 33.6" = list(sensors = 17:20, offset = 5),
    "RM 23.0" = list(sensors = 21:22, offset = 13),
    "RM 21.5" = list(sensors = 23:24, offset = 12),
    "RM 17.0" = list(sensors = 25:27, offset = 14),
    "RM 15.0" = list(sensors = 28:30, offset = 17),
    "RM 13.1" = list(sensors = 31:32, offset = 15)
  ),
  
  # Complete year mapping (file year to actual year)
  year_mapping = list(
    "2001" = "1995 (Y01)",
    "2002" = "1996 (Y02)",
    "2003" = "1997 (Y03)",
    "2004" = "1998 (Y04)",
    "2005" = "1999 (Y05)",
    "2006" = "2000 (Y06)",
    "2007" = "2001 (Y07)",
    "2008" = "2002 (Y08)",
    "2009" = "2003 (Y09)",
    "2010" = "2004 (Y10)",
    "2011" = "2005 (Y11)",
    "2012" = "2006 (Y12)",
    "2013" = "2007 (Y13)",
    "2014" = "2008 (Y14)",
    "2015" = "2009 (Y15)",
    "2016" = "2010 (Y16)",
    "2017" = "2011 (Y17)",
    "2018" = "2012 (Y18)",
    "2019" = "2013 (Y19)",
    "2020" = "2014 (Y20)"
  )
)

#' Process directory to identify valid Seatek data files
#' @param data_dir Directory containing Seatek data files
#' @return List with valid files and invalid files
process_directory <- function(data_dir) {
  # Get all files in the directory
  all_files <- list.files(data_dir, full.names = TRUE, pattern = "\\.txt$|\\.xlsx$")
  
  # Initialize results
  valid_files <- list()
  invalid_files <- list()
  
  # Process each file
  for (file_path in all_files) {
    result <- validate_seatek_file(file_path)
    
    if (result$valid) {
      valid_files[[basename(file_path)]] <- list(
        path = file_path,
        metadata = result$metadata
      )
    } else {
      invalid_files[[basename(file_path)]] <- list(
        path = file_path,
        reason = result$reason
      )
    }
  }
  
  return(list(
    valid_files = valid_files,
    invalid_files = invalid_files
  ))
}

#' Sort files chronologically based on metadata
#' @param files List of validated files with metadata
#' @return Sorted list of files
sort_files_chronologically <- function(files) {
  if (length(files) == 0) {
    return(list())
  }
  
  # Extract years for sorting
  years <- sapply(files, function(file) {
    if (!is.null(file$metadata$year)) {
      return(file$metadata$year)
    } else {
      return(NA)
    }
  })
  
  # Sort by year
  sorted_indices <- order(years, na.last = TRUE)
  sorted_files <- files[sorted_indices]
  
  return(sorted_files)
}

#' Validate and categorize Seatek data files
#' @param file_path Path to the data file
#' @return List with validation status and file metadata
validate_seatek_file <- function(file_path) {
  file_name <- basename(file_path)
  
  # Define expected patterns
  patterns <- list(
    trial = "^SS_P\\d{4}(ii)?\\.txt$",
    yearly = "^SS_Y\\d{2}(\\.txt|\\.xlsx)$",
    yearly_part = "^SS_Y\\d{1,2}\\(part2\\)\\.txt$",
    s27_format = "^S27_Y\\d{2}\\.txt$",
    s26_format = "^S26_Y\\d{2}\\.txt$",
    crash = "\\[Program crashed.*\\]"
  )
  
  # Check file existence
  if (!file.exists(file_path)) {
    return(list(
      valid = FALSE,
      reason = "File does not exist",
      metadata = NULL
    ))
  }
  
  # Extract metadata based on file pattern
  metadata <- list(
    original_name = file_name,
    type = NA,
    year = NA,
    iteration = NA,
    is_processed = FALSE
  )
  
  if (grepl(patterns$trial, file_name)) {
    metadata$type <- "trial"
    metadata$year <- as.numeric(sub("^SS_P(\\d{4}).*\\.txt$", "\\1", file_name))
    metadata$iteration <- if (grepl("ii\\.txt$", file_name)) "ii" else "i"
  } else if (grepl(patterns$yearly_part, file_name)) {
    metadata$type <- "yearly_part"
    metadata$year <- as.numeric(sub("^SS_Y(\\d{1,2}).*$", "\\1", file_name))
    metadata$iteration <- "part2"
  } else if (grepl(patterns$yearly, file_name)) {
    metadata$type <- "yearly"
    metadata$year <- as.numeric(sub("^SS_Y(\\d{2}).*$", "\\1", file_name))
    metadata$iteration <- "i"
    metadata$is_processed <- grepl("\\.xlsx$", file_name)
  } else if (grepl(patterns$s27_format, file_name)) {
    # Handle your specific file pattern
    metadata$type <- "s27_yearly"
    metadata$year <- as.numeric(sub("^S27_Y(\\d{2})\\.txt$", "\\1", file_name))
    metadata$iteration <- "i"
  } else if (grepl(patterns$s26_format, file_name)) {
    # Handle Series 26 file pattern
    metadata$type <- "s26_yearly"
    metadata$year <- as.numeric(sub("^S26_Y(\\d{2})\\.txt$", "\\1", file_name))
    metadata$iteration <- "i"
  } else if (grepl(patterns$crash, file_name)) {
    return(list(
      valid = FALSE,
      reason = "Crashed file",
      metadata = list(original_name = file_name, type = "crash")
    ))
  } else {
    return(list(
      valid = FALSE,
      reason = "Invalid file name pattern",
      metadata = NULL
    ))
  }
  
  # Convert two-digit years to full years
  if (metadata$type == "yearly" || metadata$type == "yearly_part" || metadata$type == "s27_yearly" || metadata$type == "s26_yearly") {
    metadata$year <- 2000 + metadata$year
  }
  
  return(list(
    valid = TRUE,
    reason = NULL,
    metadata = metadata
  ))
}

#' Read sensor data from file
read_sensor_data <- function(file_path) {
  tryCatch({
    # Normalize the path using the common function
    file_path <- normalize_path(file_path)
    # Log the normalized path (once)
    cat(paste("Processing file:", file_path), "\n")
    # Check if file exists and is readable
    if (!file.exists(file_path)) {
      stop(paste("File does not exist:", file_path))
    }
    
    # Check if file is a text file
    if (!grepl("\\.txt$", file_path)) {
      stop("Not a text file")
    }
    
    # Check if file is empty
    file_size <- file.size(file_path)
    if (file_size == 0) {
      log_message <- paste("Empty file detected:", basename(file_path), "(size: 0 bytes)")
      warning(log_message)
      cat(log_message, "\n")
      # Return NULL with an attribute to indicate empty file status
      result <- NULL
      attr(result, "status") <- "empty_file"
      return(result)
    } else {
      cat(paste("File size:", basename(file_path), "-", file_size, "bytes"), "\n")
    }
    # Check for line 181 issue - read the file line by line to inspect
    lines <- readLines(file_path, n = 200) # Read first 200 lines if available
    
    # Initialize variable to hold the data
    data <- NULL
    
    # Function to fix line 181 issues
    fix_line_181 <- function(lines) {
      if (length(lines) < 181) return(lines)
      
      line_181 <- lines[181]
      log_message <- paste("Checking line 181 in file:", basename(file_path))
      cat(log_message, "\n")
      
      # Clean and split the line
      fields <- strsplit(line_181, " ")[[1]]
      fields <- fields[fields != ""] # Remove empty spaces
      
      # If line has correct number of fields, return unchanged
      if (length(fields) <= 33) return(lines)
      
      # Log issue
      warning(paste("Line 181 has", length(fields), "fields instead of 33"))
      
      # Make a copy of the lines to modify
      fixed_lines <- lines
      
      # Strategy 1: Look for a special split character (\L)
      split_char_pattern <- "\\\\L"
      split_char_pos <- gregexpr(split_char_pattern, line_181)[[1]]
      
      if (split_char_pos > 0) {
        # Split at the special character
        fixed_line_1 <- substr(line_181, 1, split_char_pos - 1)
        fixed_line_2 <- substr(line_181, split_char_pos + 2, nchar(line_181))
        
        # Replace and add lines
        fixed_lines[181] <- fixed_line_1
        if (nchar(fixed_line_2) > 10) {
          fixed_lines <- c(fixed_lines[1:181], fixed_line_2, fixed_lines[182:length(fixed_lines)])
        }
        
        return(fixed_lines)
      }
      
      # Strategy 2: Look for timestamps (usually at field 33)
      timestamp_pattern <- "\\d{8,}"
      
      # Find non-empty fields for counting
      non_empty_fields <- fields[fields != ""]
      
      # If we have enough fields, assume first 33 is one record
      if (length(non_empty_fields) >= 33) {
        # Count to field 33
        field_count <- 0
        split_pos <- 0
        
        for (i in 1:length(fields)) {
          if (fields[i] != "") {
            field_count <- field_count + 1
            if (field_count == 33) {
              split_pos <- i
              break
            }
          }
        }
        
        # If 33rd field found
        if (split_pos > 0) {
          # See if it looks like a timestamp
          is_timestamp <- grepl("^\\d{8,}$", fields[split_pos])
          
          # Create first line (first 33 fields)
          fixed_line_1 <- paste(fields[1:split_pos], collapse = " ")
          fixed_lines[181] <- fixed_line_1
          
          # If there are more fields, create a second line
          if (split_pos < length(fields)) {
            fixed_line_2 <- paste(fields[(split_pos+1):length(fields)], collapse = " ")
            if (nchar(fixed_line_2) > 10) {
              fixed_lines <- c(fixed_lines[1:181], fixed_line_2, fixed_lines[182:length(fixed_lines)])
            }
          }
          
          return(fixed_lines)
        }
      }
      
      # If all strategies failed, try a simple split at field 33 if possible
      if (length(fields) >= 65) {
        # Split in half (roughly)
        mid_point <- ceiling(length(fields) / 2)
        fixed_line_1 <- paste(fields[1:mid_point], collapse = " ")
        fixed_line_2 <- paste(fields[(mid_point+1):length(fields)], collapse = " ")
        
        fixed_lines[181] <- fixed_line_1
        if (nchar(fixed_line_2) > 10) {
          fixed_lines <- c(fixed_lines[1:181], fixed_line_2, fixed_lines[182:length(fixed_lines)])
        }
        
        return(fixed_lines)
      }
      
      # Fall back to using original lines if all strategies failed
      return(lines)
    }
    
    # If we have more than 180 lines, check for line 181 issue
    if (length(lines) >= 181) {
      fields <- strsplit(lines[181], " ")[[1]]
      fields <- fields[fields != ""] # Remove empty spaces
      
      if (length(fields) > 33) {
        # Fix lines if issue detected
        fixed_lines <- fix_line_181(lines)
        
        # Write fixed content to a temporary file
        temp_file <- tempfile()
        writeLines(fixed_lines, temp_file)
        
        # Read from the fixed file
        data <- tryCatch({
          dt <- fread(temp_file, header = FALSE, na.strings = c("0.00", "NA"))
          cat(paste("Successfully read fixed file for:", basename(file_path)), "\n")
          dt
        }, error = function(e) {
          warning(paste("Error reading fixed file:", e$message))
          NULL
        })
        
        # Clean up
        file.remove(temp_file)
        
        # Log success if data was read
        if(!is.null(data)) {
          log_message <- paste("Fixed file processed successfully:", basename(file_path))
          cat(log_message, "\n")
        }
      } else {
        # Normal read if no issue detected in line 181
        data <- tryCatch({
          dt <- fread(file_path, header = FALSE, na.strings = c("0.00", "NA"), 
                    fill = TRUE, verbose = FALSE)
          cat(paste("Successfully read file:", basename(file_path)), "\n")
          dt
        }, error = function(e) {
          warning(paste("Error reading file:", e$message))
          NULL
        })
      }
    } else {
      # File is shorter than 181 lines
      data <- tryCatch({
        dt <- fread(file_path, header = FALSE, na.strings = c("0.00", "NA"), 
                  fill = TRUE, verbose = FALSE)
        cat(paste("Successfully read file:", basename(file_path)), "\n")
        dt
      }, error = function(e) {
        warning(paste("Error reading file:", e$message))
        NULL
      })
    }
    
    # Check if data is NULL
    if (is.null(data)) {
      warning(paste("Failed to read data from file:", basename(file_path)))
      return(NULL)
    }
    
    # Check column count
    if (ncol(data) != 33) {
      warning(paste("Invalid column count:", ncol(data), "in file", basename(file_path)))
      return(NULL)
    }
    
    return(data)
  }, error = function(e) {
    warning(sprintf("Error reading file %s: %s", basename(file_path), e$message))
    return(NULL)
  })
}

#' Calculate metrics for sensor data
#' @param data Raw sensor data
#' @param n_rows Number of rows for averaging
#' @return List of calculated metrics
calculate_metrics <- function(data, n_rows = 5) {
  # Check if data is valid
  if (is.null(data) || nrow(data) == 0) {
    warning("Invalid or empty data")
    return(NULL)
  }
  
  # Define sensor columns
  sensor_cols <- 1:32
  
  # Calculate averages
  first_rows <- head(data[, ..sensor_cols], n_rows)
  last_rows <- tail(data[, ..sensor_cols], n_rows)
  
  first_avg <- colMeans(first_rows, na.rm = TRUE)
  last_avg <- colMeans(last_rows, na.rm = TRUE)
  
  # New full run average calculation:
  # Take the last 5 values of each column, but only average non-zero values
  full_run_avg <- numeric(length(sensor_cols))
  for (col in sensor_cols) {
    # Get last 5 values including zeros/NA (position matters)
    last_five <- tail(data[[col]], n_rows)
    # Filter to keep only non-zero and non-NA values
    non_zero_values <- last_five[!is.na(last_five) & last_five > 0]
    # Calculate average of non-zero values
    if (length(non_zero_values) > 0) {
      full_run_avg[col] <- mean(non_zero_values)
    } else {
      # If all values are zero or NA, use 0
      full_run_avg[col] <- 0
    }
  }
  
  within_year_diff <- last_avg - first_avg
  
  # NAVD88 conversion
  navd88_conversion <- function(x) {
    return(-(x + 1.9 - 0.32) * 400 / 30.48)
  }
  
  # Get offsets from config
  offsets <- numeric(32)
  for (rm_info in config$river_mile_offsets) {
    offsets[rm_info$sensors] <- rm_info$offset
  }
  
  navd88_full_run <- navd88_conversion(full_run_avg) + offsets
  
  return(list(
    first_5_avg = first_avg,
    last_5_avg = last_avg,
    full_run_avg = full_run_avg,
    within_year_diff = within_year_diff,
    navd88_full_run = navd88_full_run
  ))
}

#' Create data frames for Excel output
#' @param results List of calculated metrics by year
#' @return List of data frames for Excel
create_data_frames <- function(results) {
  if (length(results) == 0) {
    warning("No results to process")
    return(list())
  }
  
  # Extract years and map them
  years <- sapply(names(results), function(fname) {
    year <- as.character(results[[fname]]$metadata$year)
    if (year %in% names(config$year_mapping)) {
      return(config$year_mapping[[year]])
    } else {
      return(year)
    }
  })
  
  # Create data frames
  first_5_averages <- data.frame(Year = years, stringsAsFactors = FALSE)
  last_5_averages <- data.frame(Year = years, stringsAsFactors = FALSE)
  full_run_averages <- data.frame(Year = years, stringsAsFactors = FALSE)
  within_year_differences <- data.frame(Year = years, stringsAsFactors = FALSE)
  navd88_converted <- data.frame(Year = years, stringsAsFactors = FALSE)
  
  # Fill data frames
  for (i in 1:length(results)) {
    fname <- names(results)[i]
    metrics <- results[[fname]]$metrics
    
    for (j in 1:32) {
      first_5_averages[i, j+1] <- metrics$first_5_avg[j]
      last_5_averages[i, j+1] <- metrics$last_5_avg[j]
      full_run_averages[i, j+1] <- metrics$full_run_avg[j]
      within_year_differences[i, j+1] <- metrics$within_year_diff[j]
      navd88_converted[i, j+1] <- metrics$navd88_full_run[j]
    }
  }
  
  # Name columns
  col_names <- c("Year", paste("Sensor", sprintf("%02d", 1:32)))
  names(first_5_averages) <- col_names
  names(last_5_averages) <- col_names
  names(full_run_averages) <- col_names
  names(within_year_differences) <- col_names
  names(navd88_converted) <- col_names
  
  # Calculate year-to-year differences
  year_to_year_differences <- NULL
  if (nrow(first_5_averages) >= 2) {
    # Get original years for sorting
    original_years <- sapply(names(results), function(fname) {
      return(results[[fname]]$metadata$year)
    })
    
    # Sort by original year
    sorted_indices <- order(original_years)
    sorted_first_5 <- first_5_averages[sorted_indices, ]
    sorted_last_5 <- last_5_averages[sorted_indices, ]
    
    # Create year pairs
    year_pairs <- character(length(sorted_indices) - 1)
    for (i in 1:(length(sorted_indices) - 1)) {
      year_pairs[i] <- paste(sorted_first_5$Year[i+1], "to", sorted_first_5$Year[i])
    }
    
    # Initialize data frame
    year_to_year_differences <- data.frame(Year_Pair = year_pairs, stringsAsFactors = FALSE)
    
    # Calculate differences
    for (j in 1:32) {
      col_name <- paste("Sensor", sprintf("%02d", j))
      year_to_year_differences[, col_name] <- 
        sorted_first_5[2:nrow(sorted_first_5), j+1] - 
        sorted_last_5[1:(nrow(sorted_last_5)-1), j+1]
    }
  }
  
  # Return all data frames
  return(list(
    "First 5 Averages" = first_5_averages,
    "Last 5 Averages" = last_5_averages,
    "Full Run Averages" = full_run_averages,
    "Within Year Differences" = within_year_differences,
    "NAVD88 Converted" = navd88_converted,
    "Year-to-Year Differences" = year_to_year_differences
  ))
}

#' Create river mile summary
#' @return Data frame with river mile information
create_river_mile_summary <- function() {
  # Create data frame with river mile information
  river_miles <- names(config$river_mile_offsets)
  num_sensors <- sapply(config$river_mile_offsets, function(x) length(x$sensors))
  offsets <- sapply(config$river_mile_offsets, function(x) x$offset)
  sensors <- sapply(config$river_mile_offsets, function(x) paste(x$sensors, collapse=", "))
  
  # Create data frame
  river_mile_df <- data.frame(
    River_Mile = river_miles,
    Num_Sensors = num_sensors,
    Start_Year = "1995 (Y01)",
    End_Year = "2014 (Y20)",
    Y_Offset = offsets,
    Sensors = sensors,
    Notes = "",
    stringsAsFactors = FALSE
  )
  
  return(river_mile_df)
}

#' Export raw data to Excel
#' @param data Raw data from file
#' @param output_file Output file path
#' @param year Year of data
export_raw_data <- function(data, output_file, year) {
  tryCatch({
    # Create workbook
    wb <- openxlsx::createWorkbook()
    
    # Add worksheet
    openxlsx::addWorksheet(wb, "Raw Data")
    
    # Create column headers
    headers <- c("Time", paste("Sensor", sprintf("%02d", 1:32)))
    
    # Add headers row
    openxlsx::writeData(wb, "Raw Data", t(headers), startRow = 1)
    
    # Write data
    openxlsx::writeData(wb, "Raw Data", data, startRow = 2, colNames = FALSE)
    
    # Create styles
    headerStyle <- openxlsx::createStyle(
      textDecoration = "bold",
      border = "bottom",
      fgFill = "#E2E2E2",
      halign = "center"
    )
    
    # Apply styles
    openxlsx::addStyle(wb, "Raw Data", headerStyle, rows = 1, cols = 1:33)
    
    # Auto-adjust column widths
    openxlsx::setColWidths(wb, "Raw Data", cols = 1:33, widths = "auto")
    
    # Save workbook
    openxlsx::saveWorkbook(wb, output_file, overwrite = TRUE)
    
    return(TRUE)
  }, error = function(e) {
    warning(sprintf("Error exporting raw data: %s", e$message))
    return(FALSE)
  })
}

#' Create a sensor data Excel file for a specific year
#' @param metrics Metrics for the year
#' @param year Year
#' @param mapped_year Mapped year string
#' @param output_file Output file path
create_year_data_file <- function(metrics, year, mapped_year, output_file) {
  tryCatch({
    # Create a data frame with sensor as rows and metrics as columns
    sensor_names <- paste("Sensor", sprintf("%02d", 1:32))
    year_data <- data.frame(
      Sensor = sensor_names,
      First_5_Avg = metrics$first_5_avg,
      Last_5_Avg = metrics$last_5_avg,
      Full_Run_Avg = metrics$full_run_avg,
      Within_Year_Diff = metrics$within_year_diff,
      NAVD88_Converted = metrics$navd88_full_run,
      stringsAsFactors = FALSE
    )
    
    # Create workbook
    wb <- openxlsx::createWorkbook()
    
    # Add worksheet
    openxlsx::addWorksheet(wb, "Sensor Data")
    
    # Add title
    openxlsx::writeData(wb, "Sensor Data", paste("Sensor Data for Year", mapped_year), startRow = 1)
    
    # Write data
    openxlsx::writeData(wb, "Sensor Data", year_data, startRow = 3)
    
    # Create styles
    titleStyle <- openxlsx::createStyle(
      fontSize = 14,
      textDecoration = "bold",
      halign = "center"
    )
    
    headerStyle <- openxlsx::createStyle(
      textDecoration = "bold",
      border = "bottom",
      fgFill = "#E2E2E2",
      halign = "center"
    )
    
    numberStyle <- openxlsx::createStyle(numFmt = "0.000")
    
    # Apply styles
    openxlsx::addStyle(wb, "Sensor Data", titleStyle, rows = 1, cols = 1)
    openxlsx::addStyle(wb, "Sensor Data", headerStyle, rows = 3, cols = 1:ncol(year_data))
    
    # Apply number formatting
    openxlsx::addStyle(
      wb,
      "Sensor Data",
      numberStyle,
      rows = 4:(3 + nrow(year_data)),
      cols = 2:ncol(year_data),
      gridExpand = TRUE
    )
    
    # Auto-adjust column widths
    openxlsx::setColWidths(wb, "Sensor Data", cols = 1:ncol(year_data), widths = "auto")
    
    # Merge title cell across all columns
    openxlsx::mergeCells(wb, "Sensor Data", rows = 1, cols = 1:ncol(year_data))
    
    # Save workbook
    openxlsx::saveWorkbook(wb, output_file, overwrite = TRUE)
    
    return(TRUE)
  }, error = function(e) {
    warning(sprintf("Error creating year data file: %s", e$message))
    return(FALSE)
  })
}

#' Create a comprehensive data analysis report
#' @param data_dir Directory containing Seatek data files
create_analysis_report <- function(data_dir = "~/RProjects/Seatek_Analysis/Data") {
  # Print debug information
  cat("create_analysis_report() called with data_dir =", data_dir, "\n")
  cat("Current working directory:", getwd(), "\n")
  cat("Home directory:", Sys.getenv("HOME"), "\n")
  # Verify the data directory with improved error handling
  # First, try with the default path
  data_dir_orig <- data_dir
  
  # Automatically try both path formats (with and without space)
  possible_paths <- unique(c(
    data_dir_orig,
    gsub("R Projects", "RProjects", data_dir_orig, fixed = TRUE),
    gsub("RProjects", "R Projects", data_dir_orig, fixed = TRUE),
    file.path(Sys.getenv("HOME"), "RProjects/Seatek_Analysis/Data"),
    file.path(Sys.getenv("HOME"), "R Projects/Seatek_Analysis/Data"),
    file.path(getwd(), "Data")
  ))
  
  # Try each path until one works
  success <- FALSE
  path_error <- NULL
  
  for (try_path in possible_paths) {
    cat("Trying path:", try_path, "\n")
    tryCatch({
      data_dir <- verify_data_directory(try_path, caller_name = "create_analysis_report")
      success <- TRUE
      cat("Successfully resolved directory:", data_dir, "\n")
      break
    }, error = function(e) {
      cat("Path failed:", try_path, "\n")
      path_error <- e
    })
  }
  if (!success) {
    stop(paste0("ERROR: Could not find a valid data directory. ",
               "Tried ", length(possible_paths), " different paths. ",
               "Original error: ", path_error$message))
  }
  
  # Initialize logging
  log_file <- file.path(data_dir, "analysis_report_log.txt")
  log_message <- function(msg) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    message <- paste0(timestamp, " - ", msg)
    cat(message, "\n")
    cat(message, "\n", file = log_file, append = TRUE)
  }
  
  log_message("Starting Analysis Report Generation")
  
  # Process files
  tryCatch({
    # Get file inventory
    file_inventory <- process_directory(data_dir)
    sorted_files <- sort_files_chronologically(file_inventory$valid_files)
    
    if (length(sorted_files) == 0) {
      stop("No valid files found for processing")
    }
    
    log_message(sprintf("Found %d valid files to process", length(sorted_files)))
    
    # Process each file
    results <- list()
    
    for (fname in names(sorted_files)) {
      log_message(sprintf("Processing %s", fname))
      file_data <- sorted_files[[fname]]
      
      # Skip processed files
      if (file_data$metadata$is_processed) {
        log_message(sprintf("Skipping processed file: %s", fname))
        next
      }
      
      # Skip empty files with improved logging
      file_size <- file.size(file_data$path)
      if (file_size == 0) {
        log_message(sprintf("Skipping empty file: %s (0 bytes)", fname))
        next
      } else {
        log_message(sprintf("Processing file: %s (%d bytes)", fname, file_size))
      }
      
      data <- read_sensor_data(file_data$path)
      if (!is.null(data)) {
        metrics <- calculate_metrics(data)
        if (!is.null(metrics)) {
          results[[fname]] <- list(
            metrics = metrics,
            metadata = file_data$metadata,
            data = data
          )
        }
      }
    }
    
    if (length(results) == 0) {
      stop("No valid results generated")
    }
    
    # Create data frames for summary
    data_frames <- create_data_frames(results)
    
    # Create comprehensive report
    report_file <- file.path(data_dir, "Seatek_Comprehensive_Analysis.xlsx")
    
    # Create workbook
    wb <- openxlsx::createWorkbook()
    
    # Add analysis info
    analysis_info <- data.frame(
      Parameter = c(
        "Analysis Date",
        "Number of Files Processed",
        "Total Years",
        "First Year",
        "Last Year",
        "Script Version",
        "Analysis Type",
        "Data Source",
        "Notes"
      ),
      Value = c(
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        length(results),
        length(results),
        min(sapply(results, function(x) x$metadata$year)),
        max(sapply(results, function(x) x$metadata$year)),
        "2.0.3",
        "Seatek Sensor Analysis",
        "Seatek Sensor Data Files",
        "This analysis maps file years (2001-2004) to actual years (1995-1998)"
      ),
      stringsAsFactors = FALSE
    )
    
    openxlsx::addWorksheet(wb, "Analysis Info")
    openxlsx::writeData(wb, "Analysis Info", analysis_info)
    
    # Add river mile info
    river_mile_df <- create_river_mile_summary()
    openxlsx::addWorksheet(wb, "River Mile Info")
    openxlsx::writeData(wb, "River Mile Info", river_mile_df)
    
    # Add data frames
    for (sheet_name in names(data_frames)) {
      if (!is.null(data_frames[[sheet_name]])) {
        openxlsx::addWorksheet(wb, sheet_name)
        openxlsx::writeData(wb, sheet_name, data_frames[[sheet_name]])
      }
    }
    
    # Add individual year data
    for (fname in names(results)) {
      year <- results[[fname]]$metadata$year
      mapped_year <- if (as.character(year) %in% names(config$year_mapping)) {
        config$year_mapping[[as.character(year)]]
      } else {
        year
      }
      
      # Create a data frame with sensor as rows and metrics as columns
      sensor_names <- paste("Sensor", sprintf("%02d", 1:32))
      year_data <- data.frame(
        Sensor = sensor_names,
        First_5_Avg = results[[fname]]$metrics$first_5_avg,
        Last_5_Avg = results[[fname]]$metrics$last_5_avg,
        Full_Run_Avg = results[[fname]]$metrics$full_run_avg,
        Within_Year_Diff = results[[fname]]$metrics$within_year_diff,
        NAVD88_Converted = results[[fname]]$metrics$navd88_full_run,
        stringsAsFactors = FALSE
      )
      
      # Add worksheet
      sheet_name <- paste0("Year ", mapped_year)
      openxlsx::addWorksheet(wb, sheet_name)
      openxlsx::writeData(wb, sheet_name, year_data)
    }
    
    # Add data validation summary
    validation_summary <- data.frame(
      File_Name = sapply(results, function(x) x$metadata$original_name),
      Year = sapply(results, function(x) x$metadata$year),
      Mapped_Year = sapply(results, function(x) {
        year <- as.character(x$metadata$year)
        if (year %in% names(config$year_mapping)) {
          return(config$year_mapping[[year]])
        } else {
          return(year)
        }
      }),
      Row_Count = sapply(results, function(x) nrow(x$data)),
      Missing_Values = sapply(results, function(x) sum(is.na(x$data))),
      Missing_Percentage = sapply(results, function(x) 
        round(sum(is.na(x$data)) / (nrow(x$data) * ncol(x$data)) * 100, 2)
      ),
      stringsAsFactors = FALSE
    )
    
    openxlsx::addWorksheet(wb, "Data Validation")
    openxlsx::writeData(wb, "Data Validation", validation_summary)
    
    # Create styles
    headerStyle <- openxlsx::createStyle(
      textDecoration = "bold",
      border = "bottom",
      fgFill = "#E2E2E2",
      halign = "center"
    )
    
    numberStyle <- openxlsx::createStyle(numFmt = "0.000")
    
    # Apply styles to all sheets
    for (sheet in openxlsx::sheets(wb)) {
      # Get number of columns
      data <- openxlsx::readWorkbook(wb, sheet)
      if (nrow(data) > 0) {
        # Apply header style
        openxlsx::addStyle(wb, sheet, headerStyle, rows = 1, cols = 1:ncol(data))
        
        # Apply number formatting to numeric columns
        numeric_cols <- sapply(data, is.numeric)
        if (any(numeric_cols)) {
          openxlsx::addStyle(
            wb,
            sheet,
            numberStyle,
            rows = 2:nrow(data),
            cols = which(numeric_cols),
            gridExpand = TRUE
          )
        }
        
        # Auto-adjust column widths
        openxlsx::setColWidths(wb, sheet, cols = 1:ncol(data), widths = "auto")
      }
    }
    
    # Save workbook
    openxlsx::saveWorkbook(wb, report_file, overwrite = TRUE)
    log_message(sprintf("Comprehensive analysis report saved to: %s", report_file))
    
    return(TRUE)
  }, error = function(e) {
    log_message(sprintf("Error generating analysis report: %s", e$message))
    return(FALSE)
  })
}

#' Main execution function
#' @param data_dir Directory containing Seatek data files
#' Helper function to check and verify data directory
#' @param data_dir Directory path to verify
#' @param caller_name Name of the calling function for error reporting
#' @return Verified and normalized directory path
verify_data_directory <- function(data_dir, caller_name = "unknown") {
  cat(paste0("🔍 Verifying data directory from '", caller_name, "' function...\n"))
  
  # Try to normalize the path using our enhanced function, explicitly specifying it's a directory
  data_dir <- normalize_path(data_dir, is_directory = TRUE)
  
  # Verify that directory exists after normalization
  if (!dir.exists(data_dir)) {
    # Check for common path variations
    possible_alt_paths <- unique(c(
      # With/without space in "R Projects" vs "RProjects"
      gsub("R Projects", "RProjects", data_dir, fixed = TRUE),
      gsub("RProjects", "R Projects", data_dir, fixed = TRUE),
      
      # Try replacing ~ with HOME
      gsub("~", Sys.getenv("HOME"), data_dir),
      
      # Common absolute paths for this project
      file.path(Sys.getenv("HOME"), "RProjects/Seatek_Analysis/Data"),
      file.path(Sys.getenv("HOME"), "R Projects/Seatek_Analysis/Data"),
      
      # Relative to current directory
      file.path(getwd(), "Data"),
      "Data"
    ))
    
    # Try each alternative path
    for (alt_path in possible_alt_paths) {
      if (dir.exists(alt_path)) {
        warning(paste0("Using alternative path: ", alt_path, " instead of ", data_dir))
        return(alt_path)
      }
    }
    
    # If still not found, stop with detailed error
    stop(paste0("ERROR in ", caller_name, "(): After normalization, directory does not exist: ", data_dir,
               "\nCurrent working directory: ", getwd(),
               "\nHome directory: ", Sys.getenv("HOME"),
               "\nCommon paths tried: ",
               "\n  - ", gsub("~", Sys.getenv("HOME"), data_dir),
               "\n  - ", gsub("R Projects", "RProjects", data_dir),
               "\n  - ", gsub("RProjects", "R Projects", data_dir),
               "\n  - ", file.path(getwd(), "Data"),
               "\nPlease check that the data directory exists and is accessible."))
  }
  
  cat(paste0("✅ Data directory verified: ", data_dir, "\n"))
  return(data_dir)
}

main <- function(data_dir = "~/RProjects/Seatek_Analysis/Data") {
  # Print debug information
  cat("main() called with data_dir =", data_dir, "\n")
  cat("Current working directory:", getwd(), "\n")
  cat("Home directory:", Sys.getenv("HOME"), "\n")
  
  # Verify the data directory
  data_dir <- verify_data_directory(data_dir, caller_name = "main")
  
  # Log the directory path being used
  cat("Using data directory:", data_dir, "\n")
  
  # Initialize logging
  log_file <- file.path(data_dir, "processing_log.txt")
  log_message <- function(msg) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    message <- paste0(timestamp, " - ", msg)
    cat(message, "\n")
    cat(message, "\n", file = log_file, append = TRUE)
  }
  
  log_message("Starting Seatek Analysis")
  # Process files
  tryCatch({
    # Get file inventory
    file_inventory <- process_directory(data_dir)
    sorted_files <- sort_files_chronologically(file_inventory$valid_files)
    
    if (length(sorted_files) == 0) {
      stop("No valid files found for processing")
    }
    
    log_message(sprintf("Found %d valid files to process", length(sorted_files)))
    
    # Process each file
    results <- list()
    
    for (fname in names(sorted_files)) {
      log_message(sprintf("Processing %s", fname))
      file_data <- sorted_files[[fname]]
      
      # Skip processed files
      if (file_data$metadata$is_processed) {
        log_message(sprintf("Skipping processed file: %s", fname))
        next
      }
      
      # Skip empty files with improved logging
      file_size <- file.size(file_data$path)
      if (file_size == 0) {
        log_message(sprintf("Skipping empty file: %s (0 bytes)", fname))
        next
      } else {
        log_message(sprintf("Processing file: %s (%d bytes)", fname, file_size))
      }
      # Read and process data
      data <- read_sensor_data(file_data$path)
      if (!is.null(data)) {
        metrics <- calculate_metrics(data)
        if (!is.null(metrics)) {
          results[[fname]] <- list(
            metrics = metrics,
            metadata = file_data$metadata
          )
        }
      }
    }
    
    if (length(results) == 0) {
      stop("No valid results generated")
    }
    
    # Export raw data to Excel
    for (fname in names(results)) {
      year <- results[[fname]]$metadata$year
      mapped_year <- if (as.character(year) %in% names(config$year_mapping)) {
        config$year_mapping[[as.character(year)]]
      } else {
        year
      }
      
      # Get the original data
      data <- read_sensor_data(sorted_files[[fname]]$path)
      if (!is.null(data)) {
        raw_data_file <- file.path(data_dir, sprintf("Raw_Data_Year_%s.xlsx", mapped_year))
        if (export_raw_data(data, raw_data_file, year)) {
          log_message(sprintf("Raw data for year %s exported to: %s", mapped_year, raw_data_file))
        }
      }
    }
    
    # Create individual year data files
    for (fname in names(results)) {
      year <- results[[fname]]$metadata$year
      mapped_year <- if (as.character(year) %in% names(config$year_mapping)) {
        config$year_mapping[[as.character(year)]]
      } else {
        year
      }
      
      year_output_file <- file.path(data_dir, sprintf("Year_%s_Data.xlsx", mapped_year))
      if (create_year_data_file(results[[fname]]$metrics, year, mapped_year, year_output_file)) {
        log_message(sprintf("Year %s data saved to: %s", mapped_year, year_output_file))
      }
    }
    
    # Create data frames for summary
    data_frames <- create_data_frames(results)
    
    # Create summary workbook
    summary_file <- file.path(data_dir, "Seatek_Analysis_Summary.xlsx")
    if (create_summary_workbook(results, data_frames, summary_file)) {
      log_message(sprintf("Summary data saved to: %s", summary_file))
    }
    
    # Return results
    return(results)
    
  }, error = function(e) {
    log_message(sprintf("Error in processing: %s", e$message))
    stop(e)
  })
}

#' Test script function
#' @param data_dir Directory containing Seatek data files
test_script <- function(data_dir = "~/RProjects/Seatek_Analysis/Data") {
  # Print debug information
  cat("test_script() called with data_dir =", data_dir, "\n")
  cat("Current working directory:", getwd(), "\n")
  cat("Home directory:", Sys.getenv("HOME"), "\n")
  
  # Verify the data directory
  data_dir <- verify_data_directory(data_dir, caller_name = "test_script")
  
  # List files in directory
  cat("Files in directory:\n")
  files <- list.files(data_dir)
  print(files)
  
  # Test file validation
  cat("\nValidating files:\n")
  for (file in files) {
    if (grepl("\\.txt$", file)) {
      file_path <- file.path(data_dir, file)
      result <- validate_seatek_file(file_path)
      cat(sprintf("File: %s, Valid: %s\n", file, result$valid))
      if (result$valid) {
        print(result$metadata)
      } else {
        cat(sprintf("Reason: %s\n", result$reason))
      }
    }
  }
  
  # Try to read one file
  cat("\nReading first file:\n")
  txt_files <- files[grepl("\\.txt$", files)]
  if (length(txt_files) > 0) {
    file_path <- file.path(data_dir, txt_files[1])
    data <- read_sensor_data(file_path)
    if (!is.null(data)) {
      cat("Successfully read file. Dimensions:", nrow(data), "x", ncol(data), "\n")
      cat("First few rows:\n")
      print(head(data, 3))
      
      # Test metrics calculation
      cat("\nCalculating metrics:\n")
      metrics <- calculate_metrics(data)
      if (!is.null(metrics)) {
        cat("First 5 rows average (first 5 sensors):\n")
        print(head(metrics$first_5_avg, 5))
        
        cat("\nLast 5 rows average (first 5 sensors):\n")
        print(head(metrics$last_5_avg, 5))
        
        cat("\nWithin-year difference (first 5 sensors):\n")
        print(head(metrics$within_year_diff, 5))
        
        cat("\nNAVD88 converted (first 5 sensors):\n")
        print(head(metrics$navd88_full_run, 5))
      } else {
        cat("Failed to calculate metrics.\n")
      }
    } else {
      cat("Failed to read file.\n")
    }
  }
  
  # Test river mile summary
  cat("\nCreating river mile summary:\n")
  river_mile_df <- create_river_mile_summary()
  print(head(river_mile_df))
  
  cat("\nTest completed successfully.\n")
}

#' Validate data quality
#' @param data_dir Directory containing Seatek data files
validate_data <- function(data_dir = "~/RProjects/Seatek_Analysis/Data") {
  # Use the verify_data_directory function for consistent path handling
  data_dir <- verify_data_directory(data_dir, caller_name = "validate_data")
  cat("Validation directory path:", data_dir, "\n")
  
  # Initialize logging
  log_file <- file.path(data_dir, "validation_log.txt")
  log_message <- function(msg) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    message <- paste0(timestamp, " - ", msg)
    cat(message, "\n")
    cat(message, "\n", file = log_file, append = TRUE)
  }
  
  log_message("Starting Data Validation")
  
  # Get file inventory
  file_inventory <- process_directory(data_dir)
  sorted_files <- sort_files_chronologically(file_inventory$valid_files)
  
  if (length(sorted_files) == 0) {
    log_message("No valid files found for validation")
    return(NULL)
  }
  
  log_message(sprintf("Found %d valid files to validate", length(sorted_files)))
  
  # Initialize validation results
  validation_results <- list()
  
  # Process each file
  for (fname in names(sorted_files)) {
    log_message(sprintf("Validating %s", fname))
    file_data <- sorted_files[[fname]]
    
    # Read data
    data <- read_sensor_data(file_data$path)
    if (is.null(data)) {
      log_message(sprintf("Error reading file: %s", fname))
      next
    }
    
    # Basic validation
    validation <- list(
      file_name = fname,
      year = file_data$metadata$year,
      row_count = nrow(data),
      column_count = ncol(data),
      missing_values = sum(is.na(data)),
      missing_percentage = round(sum(is.na(data)) / (nrow(data) * ncol(data)) * 100, 2),
      min_value = min(data[, 1:32], na.rm = TRUE),
      max_value = max(data[, 1:32], na.rm = TRUE),
      issues = list()
    )
    
    # Check for potential issues
    
    # 1. Check for too many missing values in a column
    missing_by_col <- colSums(is.na(data))
    problem_cols <- which(missing_by_col / nrow(data) > 0.5)
    if (length(problem_cols) > 0) {
      validation$issues$high_missing <- sprintf(
        "Columns with >50%% missing values: %s",
        paste(problem_cols, collapse = ", ")
      )
    }
    
    # 2. Check for outliers (values more than 3 std deviations from mean)
    for (col in 1:32) {
      col_data <- data[[col]]
      col_data <- col_data[!is.na(col_data)]
      if (length(col_data) > 5) {
        col_mean <- mean(col_data)
        col_sd <- sd(col_data)
        outliers <- col_data[abs(col_data - col_mean) > 3 * col_sd]
        if (length(outliers) > 0) {
          validation$issues$outliers <- c(
            validation$issues$outliers,
            sprintf(
              "Column %d has %d outliers",
              col, length(outliers)
            )
          )
        }
      }
    }
    
    # 3. Check for abrupt changes in sensor readings
    for (col in 1:32) {
      col_data <- data[[col]]
      col_data <- col_data[!is.na(col_data)]
      if (length(col_data) > 5) {
        diffs <- abs(diff(col_data))
        large_diffs <- which(diffs > 3 * mean(diffs, na.rm = TRUE))
        if (length(large_diffs) > 0) {
          validation$issues$abrupt_changes <- c(
            validation$issues$abrupt_changes,
            sprintf(
              "Column %d has %d abrupt changes",
              col, length(large_diffs)
            )
          )
        }
      }
    }
    
    validation_results[[fname]] <- validation
  }
  
  # Create validation report
  report_file <- file.path(data_dir, "Data_Validation_Report.xlsx")
  
  # Create workbook
  wb <- openxlsx::createWorkbook()
  
  # Add summary sheet
  openxlsx::addWorksheet(wb, "Validation Summary")
  
  # Create summary data frame
  summary_df <- data.frame(
    File_Name = sapply(validation_results, function(x) x$file_name),
    Year = sapply(validation_results, function(x) x$year),
    Row_Count = sapply(validation_results, function(x) x$row_count),
    Column_Count = sapply(validation_results, function(x) x$column_count),
    Missing_Values = sapply(validation_results, function(x) x$missing_values),
    Missing_Percentage = sapply(validation_results, function(x) x$missing_percentage),
    Min_Value = sapply(validation_results, function(x) x$min_value),
    Max_Value = sapply(validation_results, function(x) x$max_value),
    Issues_Found = sapply(validation_results, function(x) length(unlist(x$issues))),
    stringsAsFactors = FALSE
  )
  
  # Write summary
  openxlsx::writeData(wb, "Validation Summary", summary_df)
  
  # Add issues sheet
  openxlsx::addWorksheet(wb, "Validation Issues")
  
  # Create issues data frame
  issues_list <- list()
  for (fname in names(validation_results)) {
    validation <- validation_results[[fname]]
    if (length(unlist(validation$issues)) > 0) {
      for (issue_type in names(validation$issues)) {
        issues <- validation$issues[[issue_type]]
        if (length(issues) > 0) {
          for (issue in issues) {
            issues_list[[length(issues_list) + 1]] <- list(
              File_Name = validation$file_name,
              Year = validation$year,
              Issue_Type = issue_type,
              Issue_Description = issue
            )
          }
        }
      }
    }
  }
  
  if (length(issues_list) > 0) {
    issues_df <- do.call(rbind, lapply(issues_list, as.data.frame))
    openxlsx::writeData(wb, "Validation Issues", issues_df)
  } else {
    openxlsx::writeData(wb, "Validation Issues", "No issues found")
  }
  
  # Create styles
  headerStyle <- openxlsx::createStyle(
    textDecoration = "bold",
    border = "bottom",
    fgFill = "#E2E2E2",
    halign = "center"
  )
  
  # Apply styles
  openxlsx::addStyle(wb, "Validation Summary", headerStyle, rows = 1, cols = 1:ncol(summary_df))
  
  if (length(issues_list) > 0) {
    openxlsx::addStyle(wb, "Validation Issues", headerStyle, rows = 1, cols = 1:ncol(issues_df))
  }
  
  # Auto-adjust column widths
  openxlsx::setColWidths(wb, "Validation Summary", cols = 1:ncol(summary_df), widths = "auto")
  
  if (length(issues_list) > 0) {
    openxlsx::setColWidths(wb, "Validation Issues", cols = 1:ncol(issues_df), widths = "auto")
  }
  
  # Save workbook
  openxlsx::saveWorkbook(wb, report_file, overwrite = TRUE)
  log_message(sprintf("Validation report saved to: %s", report_file))
  
  
  return(validation_results)
}

#' Create a summary workbook with analysis results
#' @param results Results list containing metrics and metadata
#' @param data_frames Data frames with summarized metrics
#' @param output_file Output file path
#' @return Boolean indicating success/failure
create_summary_workbook <- function(results, data_frames, output_file) {
  tryCatch({
    # Create workbook
    wb <- openxlsx::createWorkbook()
    
    # Add analysis info
    analysis_info <- data.frame(
      Parameter = c(
        "Analysis Date",
        "Number of Files Processed",
        "Total Years",
        "First Year",
        "Last Year",
        "Script Version"
      ),
      Value = c(
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        length(results),
        length(results),
        min(sapply(results, function(x) x$metadata$year)),
        max(sapply(results, function(x) x$metadata$year)),
        "2.0.3"
      ),
      stringsAsFactors = FALSE
    )
    
    openxlsx::addWorksheet(wb, "Analysis Info")
    openxlsx::writeData(wb, "Analysis Info", analysis_info)
    
    # Add data frames
    for (sheet_name in names(data_frames)) {
      if (!is.null(data_frames[[sheet_name]])) {
        openxlsx::addWorksheet(wb, sheet_name)
        openxlsx::writeData(wb, sheet_name, data_frames[[sheet_name]])
      }
    }
    
    # Create styles
    headerStyle <- openxlsx::createStyle(
      textDecoration = "bold",
      border = "bottom",
      fgFill = "#E2E2E2",
      halign = "center"
    )
    
    numberStyle <- openxlsx::createStyle(numFmt = "0.000")
    
    # Apply styles to all sheets
    for (sheet in openxlsx::sheets(wb)) {
      # Get number of columns
      data <- openxlsx::readWorkbook(wb, sheet)
      if (nrow(data) > 0) {
        # Apply header style
        openxlsx::addStyle(wb, sheet, headerStyle, rows = 1, cols = 1:ncol(data))
        
        # Apply number formatting to numeric columns
        numeric_cols <- sapply(data, is.numeric)
        if (any(numeric_cols)) {
          openxlsx::addStyle(
            wb,
            sheet,
            numberStyle,
            rows = 2:nrow(data),
            cols = which(numeric_cols),
            gridExpand = TRUE
          )
        }
        
        # Auto-adjust column widths
        openxlsx::setColWidths(wb, sheet, cols = 1:ncol(data), widths = "auto")
      }
    }
    
    # Save workbook
    openxlsx::saveWorkbook(wb, output_file, overwrite = TRUE)
    
    return(TRUE)
  }, error = function(e) {
    warning(sprintf("Error creating summary workbook: %s", e$message))
    return(FALSE)
  })
}

# Run the main function
if (!interactive()) {
  main()
} else {
  # In interactive mode, you can uncomment this to run the main function
  # main()
  
  # Or run the test script
  # test_script()
  
  # Or run data validation
  # validate_data()
  
  # Or create comprehensive analysis report
  # create_analysis_report()
  
  # Or manually execute the main function
  cat("Script loaded. Run main() to execute the full analysis.\n")
  cat("Run test_script() to test the script functionality.\n")
  cat("Run validate_data() to validate data quality.\n")
  cat("Run create_analysis_report() to generate a comprehensive analysis report.\n")
}
