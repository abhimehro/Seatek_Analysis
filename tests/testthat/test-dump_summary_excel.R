library(testthat)
# Ensure openxlsx is available for reading/writing Excel files.
# It's a dependency of Updated_Seatek_Analysis.R, so it should be loaded
# if tests are run after sourcing the main script.
# An explicit library call can be a safeguard if running tests in isolation.
# library(openxlsx)
# library(tools) # for file_path_sans_ext
# library(utils) # for read.csv
# library(stats) # for setNames

# The dump_summary_excel function is expected to be in the global environment
# as Updated_Seatek_Analysis.R should be sourced by the testthat.R helper.

context("Testing dump_summary_excel function")

test_that("dump_summary_excel creates correct Excel and CSV files", {
  temp_dir_name <- "temp_dump_summary_test_output" # Unique name
  # testthat runs tests with the working directory set to the directory containing the test file.
  # So getwd() inside tests/testthat/test-dump_summary_excel.R will be tests/testthat
  temp_dir_path <- file.path(getwd(), temp_dir_name) 

  # Clean up before test, in case of previous failed run
  if (dir.exists(temp_dir_path)) {
    unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir_path, recursive = TRUE, showWarnings = FALSE)

  # Mock results data generation
  # Generates a data.frame for one year with some offset to make data unique per year
  mock_sensor_data <- function(val_offset) {
    data.frame(
      first10 = runif(32, 5, 15) + val_offset,
      last5 = runif(32, 5, 15) + val_offset,
      full = runif(32, 5, 15) + val_offset, 
      within_diff = runif(32, -2, 2) + val_offset, # within_diff can be negative
      row.names = paste0("Sensor", sprintf("%02d", 1:32))
    )
  }
  # Create a list of such data.frames, named by year (5 years for Summary_Sufficient test)
  years <- as.character(1995:1999)
  mock_results <- stats::setNames(lapply(1:length(years), function(i) mock_sensor_data(i)), years)

  output_excel_file <- file.path(temp_dir_path, "test_summary_output.xlsx")
  
  # Suppress messages from dump_summary_excel (like "Writing sheet...")
  suppressMessages({
    # Call the function being tested
    dump_summary_excel(mock_results, output_excel_file, highlight_top_n = 3)
  })

  # 1. Check Excel file creation
  expect_true(file.exists(output_excel_file), label = "Excel file must be created.")

  # 2. Check Excel sheet names
  # Need openxlsx for this. If not loaded via main script, test might fail here.
  # Ensure it's listed as a dependency or loaded.
  sheet_names <- openxlsx::getSheetNames(output_excel_file)
  expected_sheets <- c(years, "Summary_All", "Summary_Sufficient", "Summary")
  expect_true(all(expected_sheets %in% sheet_names), label = "All specified Excel sheets must be present.")
  # Also check if "Summary_Top_Sensors" is present as dump_summary_excel creates it
  expect_true("Summary_Top_Sensors" %in% sheet_names, label = "Summary_Top_Sensors sheet must be present.")


  # 3. Check CSV file creation
  csv_base_name <- tools::file_path_sans_ext(output_excel_file) # From tools package
  
  csv_files_to_check <- c(
    paste0(csv_base_name, "_all.csv"),
    paste0(csv_base_name, "_sufficient.csv"),
    paste0(csv_base_name, "_top_sensors.csv"),
    paste0(csv_base_name, ".csv"), # Corresponds to "Summary" sheet
    paste0(csv_base_name, "_robust.csv") # Corresponds to "Summary_Robust" sheet (if created)
                                        # The function creates "Summary_Robust" sheet and CSV
  )
  
  for (csv_file_path in csv_files_to_check) {
    expect_true(file.exists(csv_file_path), info = paste("Expected CSV file not found:", csv_file_path))
    if (grepl("_sufficient.csv", csv_file_path, fixed = TRUE)) {
        # utils::read.csv is fine
        df_sufficient_csv <- utils::read.csv(csv_file_path, row.names = 1) # Assuming first col is row names
        expect_gt(nrow(df_sufficient_csv), 0, label = "The _sufficient.csv should not be empty.")
        # Given 5 years of mock data and min_count=5 (default), all 32 sensors should be present.
        expect_equal(nrow(df_sufficient_csv), 32, label = "The _sufficient.csv should contain 32 sensor rows.")
    }
  }

  # 4. Basic content check for one Excel sheet
  # rowNames=TRUE is important as our mock data has sensor names as row names
  data_from_1995_sheet <- openxlsx::read.xlsx(output_excel_file, sheet = "1995", rowNames = TRUE)
  
  # Compare a specific value
  original_value <- mock_results[["1995"]]["Sensor01", "first10"]
  value_from_excel <- data_from_1995_sheet["Sensor01", "first10"]
  expect_equal(value_from_excel, original_value, tolerance = 1e-6, 
               label = "Data integrity check for Sensor01 first10 in 1995 sheet.")

  # Check one more value from a different column and sensor for robustness
  original_value_s32_full <- mock_results[["1999"]]["Sensor32", "full"]
  data_from_1999_sheet <- openxlsx::read.xlsx(output_excel_file, sheet = "1999", rowNames = TRUE)
  value_from_excel_s32_full <- data_from_1999_sheet["Sensor32", "full"]
  expect_equal(value_from_excel_s32_full, original_value_s32_full, tolerance = 1e-6,
               label = "Data integrity check for Sensor32 full in 1999 sheet.")

  # Cleanup: Remove the temporary directory and its contents
  unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  expect_false(dir.exists(temp_dir_path), label = "Temporary directory should be deleted after test.")
})
