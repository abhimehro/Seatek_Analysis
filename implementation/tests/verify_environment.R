# Seatek R Repository - Environment Verification Script
# Phase 1.1: Environment Verification
# Author: AI Assistant
# Date: 2025-07-11

# This script verifies that the R environment is properly set up for the Seatek repository
# It loads all packages, checks R version compatibility, and verifies write permissions

# Source the environment setup script
source("../scripts/01_environment_setup.R")

#' Comprehensive environment verification
#' 
#' @return List with verification results
verify_environment <- function() {
  
  cat("=== Seatek R Environment Verification ===\n")
  cat("Starting comprehensive environment verification...\n\n")
  
  # Initialize results
  verification_results <- list(
    r_version_check = NULL,
    package_loading = NULL,
    write_permissions = NULL,
    overall_success = FALSE,
    verification_timestamp = Sys.time()
  )
  
  # Step 1: Check R version compatibility
  cat("Step 1: R Version Compatibility Check\n")
  r_version_check <- check_r_version()
  verification_results$r_version_check <- r_version_check
  
  if (r_version_check$success) {
    cat("  ✓ R version compatible: ", R.version.string, "\n")
  } else {
    cat("  ✗ R version incompatible: ", r_version_check$message, "\n")
  }
  
  # Step 2: Load and verify all packages
  cat("\nStep 2: Package Loading Verification\n")
  package_loading <- load_and_verify_packages()
  verification_results$package_loading <- package_loading
  
  # Count successful package loads
  successful_loads <- sum(sapply(package_loading, function(x) x$success))
  total_packages <- length(package_loading)
  
  cat("  Package loading summary: ", successful_loads, "/", total_packages, " successful\n")
  
  # Step 3: Check write permissions
  cat("\nStep 3: Write Permission Verification\n")
  write_permissions <- check_write_permissions()
  verification_results$write_permissions <- write_permissions
  
  # Count successful permission checks
  successful_permissions <- sum(sapply(write_permissions, function(x) x$success))
  total_directories <- length(write_permissions)
  
  cat("  Permission check summary: ", successful_permissions, "/", total_directories, " successful\n")
  
  # Step 4: Additional verification checks
  cat("\nStep 4: Additional Verification Checks\n")
  
  # Check if package manifest exists
  manifest_path <- PACKAGE_MANIFEST_PATH
  manifest_exists <- file.exists(manifest_path)
  cat("  Package manifest exists: ", ifelse(manifest_exists, "✓ YES", "✗ NO"), "\n")
  
  if (manifest_exists) {
    tryCatch({
      manifest <- readRDS(manifest_path)
      cat("  Manifest timestamp: ", format(manifest$setup_timestamp), "\n")
      cat("  R version in manifest: ", manifest$r_version, "\n")
      cat("  Packages in manifest: ", length(manifest$installed_packages), "\n")
    }, error = function(e) {
      cat("  ✗ Failed to read manifest: ", e$message, "\n")
    })
  }
  
  # Check key directories exist
  key_dirs <- KEY_DIRECTORIES
  dir_check_results <- sapply(key_dirs, dir.exists)
  cat("  Key directories exist: ", sum(dir_check_results), "/", length(key_dirs), "\n")
  
  # Check if main analysis script exists
  main_script_exists <- file.exists("Updated_Seatek_Analysis.R")
  cat("  Main analysis script exists: ", ifelse(main_script_exists, "✓ YES", "✗ NO"), "\n")
  
  # Determine overall success
  r_version_ok <- r_version_check$success
  all_packages_loaded <- successful_loads == total_packages
  all_permissions_ok <- successful_permissions == total_directories
  key_components_exist <- manifest_exists && main_script_exists
  
  overall_success <- r_version_ok && all_packages_loaded && all_permissions_ok && key_components_exist
  
  verification_results$overall_success <- overall_success
  
  # Print final summary
  cat("\n=== Verification Summary ===\n")
  cat("R Version Compatibility: ", ifelse(r_version_ok, "✓ PASS", "✗ FAIL"), "\n")
  cat("Package Loading: ", ifelse(all_packages_loaded, "✓ PASS", "✗ FAIL"), " (", successful_loads, "/", total_packages, ")\n")
  cat("Write Permissions: ", ifelse(all_permissions_ok, "✓ PASS", "✗ FAIL"), " (", successful_permissions, "/", total_directories, ")\n")
  cat("Key Components: ", ifelse(key_components_exist, "✓ PASS", "✗ FAIL"), "\n")
  cat("Overall Status: ", ifelse(overall_success, "✓ PASS", "✗ FAIL"), "\n")
  
  if (overall_success) {
    cat("\n🎉 Environment verification completed successfully!\n")
    cat("The Seatek R repository environment is ready for use.\n")
  } else {
    cat("\n⚠ Environment verification completed with issues.\n")
    cat("Please review the failures above and resolve them.\n")
  }
  
  # Save verification results
  verification_path <- VERIFICATION_RESULTS_PATH
  tryCatch({
    saveRDS(verification_results, verification_path)
    cat("  Verification results saved to: ", verification_path, "\n")
  }, error = function(e) {
    cat("  ✗ Failed to save verification results: ", e$message, "\n")
  })
  
  return(verification_results)
}

#' Quick environment check
#' 
#' @return Boolean indicating if environment is ready
quick_check <- function() {
  
  cat("=== Quick Environment Check ===\n")
  
  # Check R version
  r_ok <- check_r_version()$success
  cat("R Version: ", ifelse(r_ok, "✓ OK", "✗ FAIL"), "\n")
  
  # Check if key packages can be loaded
  key_packages <- c("data.table", "openxlsx", "dplyr")
  package_ok <- all(sapply(key_packages, function(pkg) {
    tryCatch({
      requireNamespace(pkg, quietly = TRUE)
    }, error = function(e) FALSE)
  }))
  cat("Key Packages: ", ifelse(package_ok, "✓ OK", "✗ FAIL"), "\n")
  
  # Check write permissions in Data directory
  data_ok <- tryCatch({
    test_file <- file.path("Data", "quick_test.tmp")
    writeLines("test", test_file)
    file.remove(test_file)
    TRUE
  }, error = function(e) FALSE)
  cat("Write Permissions: ", ifelse(data_ok, "✓ OK", "✗ FAIL"), "\n")
  
  overall_ok <- r_ok && package_ok && data_ok
  
  cat("Overall Status: ", ifelse(overall_ok, "✓ READY", "✗ NOT READY"), "\n")
  
  return(overall_ok)
}

#' Test specific functionality
#' 
#' @param test_name Name of the test to run
#' @return Test result
run_specific_test <- function(test_name = "all") {
  
  cat("=== Running Specific Test: ", test_name, " ===\n")
  
  if (test_name == "r_version" || test_name == "all") {
    cat("Testing R version compatibility...\n")
    result <- check_r_version()
    cat("Result: ", ifelse(result$success, "✓ PASS", "✗ FAIL"), "\n")
    return(result)
  }
  
  if (test_name == "packages" || test_name == "all") {
    cat("Testing package loading...\n")
    result <- load_and_verify_packages()
    cat("Result: ", ifelse(all(sapply(result, function(x) x$success)), "✓ PASS", "✗ FAIL"), "\n")
    return(result)
  }
  
  if (test_name == "permissions" || test_name == "all") {
    cat("Testing write permissions...\n")
    result <- check_write_permissions()
    cat("Result: ", ifelse(all(sapply(result, function(x) x$success)), "✓ PASS", "✗ FAIL"), "\n")
    return(result)
  }
  
  cat("Unknown test: ", test_name, "\n")
  return(NULL)
}

# Main verification function
if (!interactive()) {
  # Run full verification
  verify_environment()
} else {
  cat("Environment verification script loaded.\n")
  cat("Available functions:\n")
  cat("  verify_environment() - Full environment verification\n")
  cat("  quick_check() - Quick environment check\n")
  cat("  run_specific_test('r_version') - Test R version\n")
  cat("  run_specific_test('packages') - Test package loading\n")
  cat("  run_specific_test('permissions') - Test write permissions\n")
}