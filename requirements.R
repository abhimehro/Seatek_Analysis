# Package requirements for Seatek Analysis Project
# Runtime (analysis): data.table, openxlsx
# Test / lint:        testthat, lintr

install_if_missing <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    # Use HTTPS to prevent MITM attacks
    install.packages(package, repos = "https://cloud.r-project.org")
  }
}

packages <- c("data.table", "openxlsx", "testthat", "lintr")
invisible(sapply(packages, install_if_missing))

# Load packages (also declares them for renv dependency discovery)
library(data.table)
library(openxlsx)
library(testthat)
library(lintr)

# Print session info for reproducibility
sessionInfo()
