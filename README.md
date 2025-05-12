# Seatek Analysis (R-Tier)

[![CodeQL Advanced](https://github.com/abhimehro/Seatek_Analysis/actions/workflows/codeql.yml/badge.svg)](https://github.com/abhimehro/Seatek_Analysis/actions/workflows/codeql.yml)
[![renv Reproducibility](https://img.shields.io/badge/reproducible%20environment-renv-blue?logo=R)](https://rstudio.github.io/renv/)

## Project Overview

This repository contains the R-based analysis tier for processing Seatek sensor data and generating Excel workbooks. It is part of a three-tier analysis system:

1. **R-Tier (This Repository):** Ingests, validates, and processes raw Seatek sensor data (`S28_Yxx.txt`), exports cleaned data and summary metrics to Excel, and generates a combined summary workbook. Robust logging and error handling are included.
2. **Excel-Tier:** Manages intermediate data processing and basic visualizations.
3. **Python-Tier:** Handles advanced data visualization and large-scale data processing.

## Repository Structure

```Markdown
├── Data/
│   ├── Series_26/              # Series 26 sensor data and analysis
│   ├── Series_27/              # Series 27 sensor data and analysis
│   ├── Raw_Data_*.xlsx         # Raw data files by year (auto-generated)
│   ├── S26_*.txt / S28_*.txt   # Raw sensor text files (Series 26/28)
│   └── *_Data.xlsx             # Processed data workbooks (auto-generated)
├── Seatek_Analysis.R           # Main analysis script (entry point)
├── Updated_Seatek_Analysis.R   # Alternate/newer analysis script
├── requirements.R              # R package requirements and setup
├── seatek_analysis.log         # Log file for analysis runs
├── processing_log.txt          # Detailed processing log
├── analysis_report_log.txt     # Analysis report generation log
├── Seatek_Analysis.Rproj       # R project configuration
└── README.md                   # Project documentation
```

## Setup and Usage

1. Clone this repository.
2. Open the project in RStudio using `Seatek_Analysis.Rproj`.
3. Install required R packages by running `source("requirements.R")` in your R console. This will also restore the `renv` environment for reproducibility.
4. Run the main analysis script: `source("Seatek_Analysis.R")` (or `Updated_Seatek_Analysis.R` for the latest workflow).
5. Outputs (raw and summary Excel files) will be generated in the `Data/` directory. Logs are written to `seatek_analysis.log` and `processing_log.txt`.
6. For troubleshooting, consult the log files (`seatek_analysis.log`, `processing_log.txt`, `analysis_report_log.txt`) in the project root. These provide detailed error and status messages for each run.

## Data Flow

1. Raw sensor data (`S28_Yxx.txt`) is processed and validated by R scripts.
2. Cleaned data and summary metrics are exported to Excel workbooks (one per year, plus a combined summary).
3. Logs and reports are generated for traceability and debugging.
4. Excel outputs are used by the Python tier for advanced visualization.
5. Results feed into the broader analysis system.

## Related Repositories

- [Hydrograph_Versus_Seatek_Sensors_Project](https://github.com/abhimehro/Hydrograph_Versus_Seatek_Sensors_Project) - Python visualization tier

## Requirements

- R >= 4.0.0
- RStudio (recommended)
- Required R packages (see `requirements.R` for a full list, including: `tidyverse`, `data.table`, `openxlsx`, `janitor`, `here`, `lubridate`, `writexl`, `stringr`, `zoo`, etc.)
- [renv](https://rstudio.github.io/renv/) for reproducible environments (auto-restored by `requirements.R`)

## Troubleshooting

- If you encounter missing package errors, re-run `source("requirements.R")`.
- For issues with data files, check that your `Data/` directory contains the expected raw `.txt` files.
- Review log files for detailed error messages and processing steps.

## Changelog

### 2025-05-10

- README.md updated: added changelog, renv badge, troubleshooting, and clarified setup steps.
- Enhanced logging and error handling in analysis scripts.
- Added `Updated_Seatek_Analysis.R` as an alternative workflow.
- Expanded package requirements and reproducibility via `renv`.
- Improved Excel output structure and summary generation.

### 2025-04-07

- Major refactor of data processing scripts for Series 26/27.
- Added comprehensive logging and analysis report generation.
- Improved directory structure and output file naming.

### 2024-12-15

- Initial public release of Seatek Analysis R-Tier.

## Contributing

1. Create a feature branch.
2. Make your changes.
3. Submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Verify license compatibility before use.
