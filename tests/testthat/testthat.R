library(testthat)
library(Seatek_Analysis) # Assuming the main script can be sourced or treated as a package

# Get the path to the main analysis script
# This might need adjustment based on how Updated_Seatek_Analysis.R is structured
# and whether its functions are globally available or need explicit sourcing.
# For now, let's assume functions are available after sourcing.
script_path <- normalizePath("../../Updated_Seatek_Analysis.R")
if (!file.exists(script_path)) {
  stop(paste("Main analysis script not found at:", script_path))
}
source(script_path) # Source the script to make functions available

# Run all tests in the directory
test_check("Seatek_Analysis") # This assumes your tests are for a package named Seatek_Analysis
# If not a package, a more common way to run all tests in the dir is:
# test_dir(".", stop_on_failure = TRUE)
# Let's use test_dir for now as it's simpler for non-package structures.

test_dir(".", stop_on_failure = TRUE)

print("testthat.R executed: All tests in tests/testthat will be run.")
