library(testthat)
library(openxlsx)
library(data.table)

# Updated_Seatek_Analysis.R should be sourced by testthat.R,
# but we can source it locally just in case this is run independently
if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R")
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R")
}

test_that("export_comprehensive_summary creates sheet and writes CSV", {
  # Setup temporary directory and files
  temp_dir_name <- "temp_export_comp_summary_test"
  temp_dir_path <- file.path(getwd(), temp_dir_name)

  if (dir.exists(temp_dir_path)) {
    unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir_path, recursive = TRUE, showWarnings = FALSE)

  # Create a mock Excel workbook
  wb <- createWorkbook()

  # Create a mock summary data.table
  mock_summary_df <- data.table(
    Sensor = paste0("Sensor", 1:3),
    full_count = c(10, 15, 20),
    full_mean = c(1.1, 2.2, 3.3)
  )

  # Define output file paths
  output_file <- file.path(temp_dir_path, "test_output.xlsx")
  expected_csv <- file.path(temp_dir_path, "test_output_all.csv")

  # Mock style
  header_style <- createStyle(textDecoration = "Bold", border = "Bottom")

  # Call the function, suppressing messages
  suppressMessages({
    export_comprehensive_summary(
      wb = wb,
      summary_df_all = mock_summary_df,
      output_file = output_file,
      header_style = header_style
    )
  })

  # Asserts

  # 1. Verify sheet was added to workbook
  sheet_names <- names(wb)
  expect_true(
    "Summary_All" %in% sheet_names,
    label = "Summary_All sheet must be added to the workbook"
  )

  # 2. Verify CSV was written to disk
  expect_true(
    file.exists(expected_csv),
    label = "Comprehensive summary CSV file must be created"
  )

  # 3. Verify CSV contents match the mock dataframe
  read_csv <- data.table::fread(expected_csv)
  expect_equal(
    nrow(read_csv), nrow(mock_summary_df),
    label = "Written CSV should have same row count as input"
  )
  expect_equal(
    read_csv$Sensor, mock_summary_df$Sensor,
    label = "Written CSV should have matching Sensor column"
  )
  expect_equal(
    read_csv$full_mean, mock_summary_df$full_mean,
    label = "Written CSV should have matching data columns"
  )

  # Cleanup
  unlink(temp_dir_path, recursive = TRUE, force = TRUE)
})
