# Package requirements for Seatek Analysis Project

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
