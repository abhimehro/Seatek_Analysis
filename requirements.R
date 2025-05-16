# Package requirements for Seatek Analysis Project
# Note: Robust statistics (mean, SD, median, MAD, 3-year rolling mean) are now computed and exported for each sensor and metric. Sufficient data threshold is 5.

# Package installation function
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package)
    library(package, character.only = TRUE)
  }
}

# Core data manipulation and analysis
packages <- c(
  "tidyverse",    # Data manipulation and visualization
  "readxl",       # Excel file reading
  "writexl",      # Excel file writing
  "lubridate",    # Date/time manipulation
  "zoo",          # Time series analysis
  "openxlsx",     # Advanced Excel operations
  "data.table",   # Fast data manipulation
  "janitor",      # Data cleaning
  "stringr",      # String manipulation
  "here"          # Project relative paths
)

# Install all packages
invisible(sapply(packages, install_if_missing))

# Print session info for reproducibility
sessionInfo()

renv::restore()