library(testthat)
library(openxlsx)
library(data.table)

if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R")
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R")
}

test_that("write_summary_sheets works correctly", {
  temp_dir_name <- "temp_write_summary_sheets_test"
  temp_dir_path <- file.path(getwd(), temp_dir_name)

  if (dir.exists(temp_dir_path)) {
    unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir_path, recursive = TRUE, showWarnings = FALSE)

  wb <- createWorkbook()

  # Create mock data with some full_count < 5 and >= 5
  mock_summary_df <- data.table(
    Sensor = paste0("Sensor", sprintf("%02d", 1:10)),
    full_count = c(2, 3, 5, 6, 10, 10, 10, 10, 10, 10),
    full_mean = runif(10, 10, 20),
    full_sd = runif(10, 0.5, 3.5),
    full_pct_nonmissing = runif(10, 80, 100),
    within_diff_mean = c(0.1, 0.5, -0.2, 1.5, -2.5, 0.3, 0.8, -1.2, 0.0, 0.9)
  )

  output_file <- file.path(temp_dir_path, "test_summary.xlsx")
  header_style <- createStyle(textDecoration = "Bold", border = "Bottom")
  highlight_style_summary <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")

  # Call the function
  suppressMessages({
    write_summary_sheets(
      wb = wb,
      summary_df = mock_summary_df,
      output_file = output_file,
      header_style = header_style,
      highlight_top_n = 3,
      highlight_style_summary = highlight_style_summary
    )
  })

  # 1. Check Excel file creation
  expect_true(file.exists(output_file), label = "Excel file must be created.")

  # 2. Check Excel sheet names
  sheet_names <- openxlsx::getSheetNames(output_file)
  expected_sheets <- c("Summary_All", "Summary_Sufficient", "Summary_Top_Sensors", "Summary")
  expect_true(all(expected_sheets %in% sheet_names), label = "All specified Excel sheets must be present.")

  # 3. Check CSV files creation
  csv_base_name <- tools::file_path_sans_ext(output_file)
  csv_files_to_check <- c(
    paste0(csv_base_name, "_all.csv"),
    paste0(csv_base_name, "_sufficient.csv"),
    paste0(csv_base_name, "_top_sensors.csv"),
    paste0(csv_base_name, ".csv"),
    paste0(csv_base_name, "_robust.csv")
  )

  for (csv_file_path in csv_files_to_check) {
    expect_true(file.exists(csv_file_path), info = paste("Expected CSV file not found:", csv_file_path))
  }

  # 4. Check data filtering for sufficient data (full_count >= 5)
  sufficient_csv <- utils::read.csv(paste0(csv_base_name, "_sufficient.csv"))
  expect_equal(nrow(sufficient_csv), 8, label = "Sensors with full_count >= 5 should be 8.")

  # 5. Check data filtering for top sensors
  top_csv <- utils::read.csv(paste0(csv_base_name, "_top_sensors.csv"))
  expect_equal(nrow(top_csv), 5, label = "Top sensors should be limited to 5.")
  expect_true(all(c("Sensor", "within_diff_mean", "full_mean", "full_sd", "full_pct_nonmissing") %in% names(top_csv)), label = "Top sensors should have specific columns.")

  # 6. Test behavior without within_diff_mean
  wb2 <- createWorkbook()
  mock_summary_no_diff <- mock_summary_df[, -c("within_diff_mean")]
  output_file2 <- file.path(temp_dir_path, "test_summary2.xlsx")

  suppressMessages({
    write_summary_sheets(
      wb = wb2,
      summary_df = mock_summary_no_diff,
      output_file = output_file2,
      header_style = header_style,
      highlight_top_n = 3,
      highlight_style_summary = highlight_style_summary
    )
  })

  sheet_names2 <- openxlsx::getSheetNames(output_file2)
  expect_false("Summary_Top_Sensors" %in% sheet_names2, label = "Summary_Top_Sensors should not be present if within_diff_mean is missing.")
  expect_true(file.exists(paste0(tools::file_path_sans_ext(output_file2), "_all.csv")))
  expect_false(file.exists(paste0(tools::file_path_sans_ext(output_file2), "_top_sensors.csv")))

  # Cleanup
  unlink(temp_dir_path, recursive = TRUE, force = TRUE)
})
