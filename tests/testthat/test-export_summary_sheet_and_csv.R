library(testthat)
library(openxlsx)
library(data.table)

env <- globalenv()

if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R", local=env)
} else if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R", local=env)
} else {
  stop("Main analysis script not found.")
}

test_that("export_summary_sheet_and_csv works correctly", {
  # Create a new workbook
  wb <- createWorkbook()

  # Create temp directory and files
  temp_dir <- tempdir()
  output_file <- file.path(temp_dir, "test_summary.xlsx")
  csv_file <- file.path(temp_dir, "test_summary_suffix.csv")

  if (file.exists(csv_file)) file.remove(csv_file)

  # Create mock data
  mock_df <- data.table(
    Sensor = paste0("Sensor0", 1:5),
    value = runif(5, 10, 20)
  )

  # Create mock styles
  header_style <- createStyle(textDecoration = "Bold", border = "Bottom")

  # Capture output messages
  out <- capture.output({
    msg <- capture_messages({
      export_summary_sheet_and_csv(
        wb = wb,
        df = mock_df,
        output_file = output_file,
        header_style = header_style,
        sheet_name = "Summary_Test",
        suffix = "_suffix.csv",
        msg_prefix = "Test"
      )
    })
  })

  # 1. Check if sheet was added
  expect_true("Summary_Test" %in% names(wb), label = "Summary_Test sheet should be added to the workbook.")

  # 2. Check if CSV file was created
  expect_true(file.exists(csv_file), label = "CSV file should be created with correct suffix.")

  # 3. Verify the CSV data
  saved_csv <- read.csv(csv_file)
  expect_equal(nrow(saved_csv), 5)
  expect_equal(colnames(saved_csv), c("Sensor", "value"))

  # 4. Check console output
  expect_match(msg[1], "Test CSV written to")
  expect_match(out[1], "Saved: test_summary_suffix.csv")

  # Cleanup
  if (file.exists(csv_file)) file.remove(csv_file)
})
