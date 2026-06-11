import re

with open("Updated_Seatek_Analysis.R", "r") as f:
    content = f.read()

# Replace the two functions with the generic one
target = """# Write comprehensive summary (all sensors)
export_comprehensive_summary <- function(wb, summary_df_all, output_file,
                                         header_style) {
  addWorksheet(wb, "Summary_All")
  writeData(wb, sheet = "Summary_All", x = summary_df_all,
            headerStyle = header_style)
  freezePane(wb, sheet = "Summary_All", firstRow = TRUE)

  csv_all <- sub("\\\\.xlsx\\$", "_all.csv", output_file)
  data.table::fwrite(summary_df_all, csv_all, row.names = FALSE)
  message(sprintf("Comprehensive summary CSV written to %s", csv_all))
  cat(sprintf("  📄 Saved: %s\\n", basename(csv_all)))
}

# Write filtered summary (sufficient data only)
export_sufficient_summary <- function(wb, summary_df_sufficient, output_file,
                                      header_style) {
  addWorksheet(wb, "Summary_Sufficient")
  writeData(wb, sheet = "Summary_Sufficient", x = summary_df_sufficient,
            headerStyle = header_style)
  freezePane(wb, sheet = "Summary_Sufficient", firstRow = TRUE)

  csv_sufficient <- sub("\\\\.xlsx\\$", "_sufficient.csv", output_file)
  data.table::fwrite(summary_df_sufficient, csv_sufficient, row.names = FALSE)
  message(sprintf("Filtered summary CSV written to %s", csv_sufficient))
  cat(sprintf("  📄 Saved: %s\\n", basename(csv_sufficient)))
}"""

replacement = """# Helper function to export summary sheet and CSV
export_summary_sheet_and_csv <- function(wb, df, output_file, header_style,
                                         sheet_name, suffix, msg_prefix) {
  addWorksheet(wb, sheet_name)
  writeData(wb, sheet = sheet_name, x = df, headerStyle = header_style)
  freezePane(wb, sheet = sheet_name, firstRow = TRUE)

  csv_file <- sub("\\\\.xlsx\\$", suffix, output_file)
  data.table::fwrite(df, csv_file, row.names = FALSE)
  message(sprintf("%s CSV written to %s", msg_prefix, csv_file))
  cat(sprintf("  📄 Saved: %s\\n", basename(csv_file)))
}"""

content = content.replace(target, replacement)

target2 = """  # --- Comprehensive summary (all sensors) ---
  summary_df_all <- summary_df # keep a copy before filtering
  export_comprehensive_summary(wb, summary_df_all, output_file, header_style)

  # --- Filtered summary (sufficient data only) ---
  min_count <- 5
  summary_df_sufficient <- summary_df_all[
    summary_df_all$full_count >= min_count,
  ]
  export_sufficient_summary(wb, summary_df_sufficient, output_file,
                            header_style)"""

replacement2 = """  # --- Comprehensive summary (all sensors) ---
  summary_df_all <- summary_df # keep a copy before filtering
  export_summary_sheet_and_csv(wb, summary_df_all, output_file, header_style,
                               "Summary_All", "_all.csv",
                               "Comprehensive summary")

  # --- Filtered summary (sufficient data only) ---
  min_count <- 5
  summary_df_sufficient <- summary_df_all[
    summary_df_all$full_count >= min_count,
  ]
  export_summary_sheet_and_csv(wb, summary_df_sufficient, output_file,
                               header_style, "Summary_Sufficient",
                               "_sufficient.csv", "Filtered summary")"""

content = content.replace(target2, replacement2)

with open("Updated_Seatek_Analysis.R", "w") as f:
    f.write(content)

print("Refactored Updated_Seatek_Analysis.R")
