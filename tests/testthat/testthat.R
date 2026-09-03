library(testthat)

# When sourcing testthat.R, it sources the main file into the parent environment
# so the test scripts have access to it.
env <- globalenv()

if (file.exists("Updated_Seatek_Analysis.R")) {
  source("Updated_Seatek_Analysis.R", local=env)
} else if (file.exists("../../Updated_Seatek_Analysis.R")) {
  source("../../Updated_Seatek_Analysis.R", local=env)
} else {
  stop("Main analysis script not found.")
}

if (interactive()) {
  test_dir(".", stop_on_failure = TRUE)
  print("testthat.R executed: All tests in tests/testthat will be run.")
}
