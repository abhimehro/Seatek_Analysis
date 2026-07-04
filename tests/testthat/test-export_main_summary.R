library(testthat)
library(openxlsx)
library(data.table)

if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R")
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R")
}

test_that("export_main_summary works correctly", {
  temp_dir_name <- "temp_export_main_summary_test"
  temp_dir_path <- file.path(getwd(), temp_dir_name)

  if (dir.exists(temp_dir_path)) {
    unlink(temp_dir_path, recursive = TRUE, force = TRUE)
  }
  dir.create(temp_dir_path, recursive = TRUE, showWarnings = FALSE)

  wb <- createWorkbook()

  # Create mock data
  mock_summary_df <- data.table(
    Sensor = paste0("Sensor", sprintf("%02d", 1:10)),
    within_diff_mean = c(0.1, 0.5, -0.2, 1.5, -2.5, 0.3, 0.8, -1.2, 0.0, 0.9)
  )

  output_file <- file.path(temp_dir_path, "test_main_summary.xlsx")
  header_style <- createStyle(textDecoration = "Bold", border = "Bottom")
  highlight_style_summary <- createStyle(
    fontColour = "#9C0006",
    bgFill = "#FFC7CE"
  )

  # 1. Normal execution with highlighting
  suppressMessages({
    export_main_summary(
      wb = wb,
      summary_df = mock_summary_df,
      output_file = output_file,
      header_style = header_style,
      highlight_top_n = 3,
      highlight_style_summary = highlight_style_summary
    )
  })

  # Check Excel file creation
  expect_true(file.exists(output_file), label = "Excel file must be created.")

  # Check Excel sheet names
  sheet_names <- openxlsx::getSheetNames(output_file)
  expect_true("Summary" %in% sheet_names,
              label = "Summary sheet must be present.")

  # Check CSV files creation
  csv_base_name <- tools::file_path_sans_ext(output_file)
  csv_out <- paste0(csv_base_name, ".csv")
  csv_robust <- paste0(csv_base_name, "_robust.csv")

  expect_true(file.exists(csv_out), info = "Expected Summary CSV not found")
  expect_true(file.exists(csv_robust),
              info = "Expected Robust Summary CSV not found")

  # 2. Execution without within_diff_mean
  wb2 <- createWorkbook()
  mock_summary_no_diff <- mock_summary_df[, -c("within_diff_mean")]
  output_file2 <- file.path(temp_dir_path, "test_main_summary2.xlsx")

  suppressMessages({
    export_main_summary(
      wb = wb2,
      summary_df = mock_summary_no_diff,
      output_file = output_file2,
      header_style = header_style,
      highlight_top_n = 3,
      highlight_style_summary = highlight_style_summary
    )
  })

  expect_true(file.exists(output_file2),
              label = "Excel file must be created without diff mean.")
  sheet_names2 <- openxlsx::getSheetNames(output_file2)
  expect_true("Summary" %in% sheet_names2,
              label = "Summary sheet must be present even without diff mean.")

  # 3. Execution without highlight style
  wb3 <- createWorkbook()
  output_file3 <- file.path(temp_dir_path, "test_main_summary3.xlsx")

  suppressMessages({
    export_main_summary(
      wb = wb3,
      summary_df = mock_summary_df,
      output_file = output_file3,
      header_style = header_style,
      highlight_top_n = 3,
      highlight_style_summary = NULL
    )
  })

  expect_true(file.exists(output_file3),
              label = "Excel file must be created without highlight style.")
  sheet_names3 <- openxlsx::getSheetNames(output_file3)
  expect_true("Summary" %in% sheet_names3,
              label = "Summary sheet must be present without highlight style.")

  # Cleanup
  unlink(temp_dir_path, recursive = TRUE, force = TRUE)
})
