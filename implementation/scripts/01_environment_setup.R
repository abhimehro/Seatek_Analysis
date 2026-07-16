# Seatek R Repository - Environment Setup Script
# Phase 1.1: Environment Setup and Dependency Management
# Author: AI Assistant
# Date: 2025-07-11

# This script sets up the R environment for the Seatek sensor data
# processing repository. It installs required packages, verifies
# installations, and creates a package manifest

# Suppress warnings during package installation
options(warn = -1)

# Required packages for Seatek analysis
REQUIRED_PACKAGES <- c( # nolint: object_name_linter.
  "data.table",    # Fast data manipulation
  "openxlsx",      # Excel file operations
  "tidyverse",     # Data manipulation and visualization
  "testthat",      # Testing framework
  "logger",        # Structured logging
  "config"         # Configuration management
)

# Package installation sources
CRAN_REPO <- "https://cloud.r-project.org" # nolint: object_name_linter.

# Configuration Constants
# nolint next: object_name_linter.
PACKAGE_MANIFEST_PATH <- "implementation/package_manifest.rds"
# nolint next: object_name_linter.
VERIFICATION_RESULTS_PATH <- "implementation/verification_results.rds"
KEY_DIRECTORIES <- c( # nolint: object_name_linter.
  "Data",
  "implementation",
  "implementation/scripts",
  "implementation/tests",
  "logs"
)

#' Process package installations
#'
#' @param packages Vector of package names to install
#' @param cran_repo CRAN repository URL
#' @param results List for tracking installation results
#' @return Updated results list
process_package_installations <- function(packages, cran_repo, results) {
  for (pkg in packages) {
    cat("   Processing package: ", pkg, "\n")
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("     ✓ Already installed\n")
      results$installed_packages <- c(results$installed_packages, pkg)
      pkg_version <- packageVersion(pkg)
      results$package_versions[[pkg]] <- as.character(pkg_version)
      cat("     Version: ", as.character(pkg_version), "\n")
    } else {
      cat("     Installing...\n")
      install_result <- tryCatch({
        install.packages(pkg, repos = cran_repo, dependencies = TRUE)
        TRUE
      }, error = function(e) {
        cat("     ✗ Installation failed: ", e$message, "\n")
        FALSE
      })
      if (install_result) {
        if (requireNamespace(pkg, quietly = TRUE)) {
          cat("     ✓ Installation successful\n")
          results$installed_packages <- c(results$installed_packages, pkg)
          pkg_version <- packageVersion(pkg)
          results$package_versions[[pkg]] <- as.character(pkg_version)
          cat("     Version: ", as.character(pkg_version), "\n")
        } else {
          cat("     ✗ Installation verification failed\n")
          results$failed_packages <- c(results$failed_packages, pkg)
        }
      } else {
        results$failed_packages <- c(results$failed_packages, pkg)
      }
    }
  }
  results
}

#' Save package manifest
#'
#' @param results List containing installation results
#' @param manifest_path Path to save the package manifest
save_package_manifest <- function(results, manifest_path) {
  cat("\n3. Creating package manifest...\n")
  tryCatch({
    saveRDS(results, manifest_path)
    cat("   ✓ Package manifest saved to: ", manifest_path, "\n")
  }, error = function(e) {
    cat("   ✗ Failed to save package manifest: ", e$message, "\n")
  })
}

#' Print installation summary
#'
#' @param results List containing installation results
print_installation_summary <- function(results) {
  cat("\n=== Installation Summary ===\n")
  cat("Installed: ", length(results$installed_packages), " packages\n")
  if (length(results$failed_packages) > 0) {
    cat("Failed to install: ", length(results$failed_packages), " packages\n")
    cat("Failed pkgs: ", paste(results$failed_packages, collapse = ", "), "\n")
  }

  if (length(results$failed_packages) == 0) {
    cat("✓ All packages installed successfully!\n")
  } else {
    cat("⚠ Some packages failed to install. Check the list above.\n")
  }

  cat("\nR Version: ", R.version.string, "\n")
  cat("Setup completed at: ", format(results$setup_timestamp), "\n")
}

#' Install and verify required packages
#'
#' @param packages Vector of package names to install
#' @param cran_repo CRAN repository URL
#' @param manifest_path Path to save the package manifest
#' @return List with installation status and package manifest
install_and_verify <- function(packages = REQUIRED_PACKAGES, # nolint: object_name_linter, line_length_linter.
                               cran_repo = CRAN_REPO,
                               manifest_path = PACKAGE_MANIFEST_PATH) {

  cat("=== Seatek R Environment Setup ===\n")
  cat("Starting package installation and verification...\n\n")

  results <- list(
    installed_packages = character(0),
    failed_packages = character(0),
    package_versions = list(),
    r_version = R.version.string,
    setup_timestamp = Sys.time()
  )

  cat("1. Checking R version compatibility...\n")
  r_version_check <- check_r_version()
  if (!r_version_check$success) {
    stop("R version compatibility check failed: ", r_version_check$message)
  }
  cat("   ✓ R version compatible (", R.version.string, ")\n\n")

  cat("2. Checking and installing required packages...\n")
  results <- process_package_installations(packages, cran_repo, results)
  save_package_manifest(results, manifest_path)
  print_installation_summary(results)

  results
}

#' Check R version compatibility
#'
#' @param r_version_data List containing R version info (defaults to R.version)
#' @return List with success status and message
check_r_version <- function(r_version_data = R.version) {
  major_version <- as.numeric(r_version_data$major)
  minor_version <- as.numeric(r_version_data$minor)

  # Check if R version is >= 4.0.0
  if (major_version > 4 || (major_version == 4 && minor_version >= 0)) {
    list(success = TRUE, message = "R version compatible")
  } else {
    list(
      success = FALSE,
      message = paste("R version", r_version_data$version.string,
                      "is not compatible. Required: >= 4.0.0")
    )
  }
}

#' Load and verify all packages
#'
#' @param packages Vector of package names to load
#' @return List with loading status for each package
load_and_verify_packages <- function(packages = REQUIRED_PACKAGES) {

  cat("Loading and verifying packages...\n")

  load_results <- list()

  for (pkg in packages) {
    cat("  Loading package: ", pkg, "\n")

    load_result <- tryCatch({
      library(pkg, character.only = TRUE)
      list(success = TRUE, message = "Loaded successfully")
    }, error = function(e) {
      list(success = FALSE, message = e$message)
    })

    load_results[[pkg]] <- load_result

    if (load_result$success) {
      cat("    ✓ Loaded successfully\n")
    } else {
      cat("    ✗ Failed to load: ", load_result$message, "\n")
    }
  }

  load_results
}

#' Check write permissions in key directories
#'
#' @param key_directories Vector of directories to check
#' @return List with permission status for each directory
check_write_permissions <- function(key_directories = KEY_DIRECTORIES) {

  cat("Checking write permissions in key directories...\n")

  permission_results <- list()

  for (dir in key_directories) {
    cat("  Checking directory: ", dir, "\n")

    # Create directory if it doesn't exist
    if (!dir.exists(dir)) {
      tryCatch({
        dir.create(dir, recursive = TRUE, showWarnings = FALSE)
        cat("    ✓ Created directory\n")
      }, error = function(e) {
        cat("    ✗ Failed to create directory: ", e$message, "\n")
      })
    }

    # Test write permission
    test_file <- file.path(dir, "write_test.tmp")
    permission_result <- tryCatch({
      writeLines("test", test_file)
      file.remove(test_file)
      list(success = TRUE, message = "Write permission granted")
    }, error = function(e) {
      list(success = FALSE, message = e$message)
    })

    permission_results[[dir]] <- permission_result

    if (permission_result$success) {
      cat("    ✓ Write permission granted\n")
    } else {
      cat("    ✗ Write permission denied: ", permission_result$message, "\n")
    }
  }

  permission_results
}

#' Main setup function
#'
#' @return List with overall setup status
main_setup <- function() {

  cat("=== Seatek R Environment Setup ===\n")
  cat("Starting comprehensive environment setup...\n\n")

  # Step 1: Install and verify packages
  cat("Step 1: Package Installation\n")
  install_results <- install_and_verify()

  # Step 2: Load and verify packages
  cat("\nStep 2: Package Loading\n")
  load_results <- load_and_verify_packages()

  # Step 3: Check write permissions
  cat("\nStep 3: Permission Verification\n")
  permission_results <- check_write_permissions()

  # Determine overall success
  all_packages_installed <- length(install_results$failed_packages) == 0
  all_packages_loaded <- all(sapply(load_results, function(x) x$success))
  all_permissions_granted <- all(sapply(
    permission_results, function(x) x$success
  ))

  overall_success <- all_packages_installed && all_packages_loaded &&
    all_permissions_granted

  # Print final summary
  cat("\n=== Final Setup Summary ===\n")
  cat(
    "Pkg Install: ",
    ifelse(all_packages_installed, "✓ SUCCESS", "✗ FAILED"),
    "\n"
  )
  cat("Pkg Load: ", ifelse(all_packages_loaded, "✓ SUCCESS", "✗ FAILED"), "\n")
  cat(
    "Write Perms: ",
    ifelse(all_permissions_granted, "✓ SUCCESS", "✗ FAILED"),
    "\n"
  )
  cat("Status: ", ifelse(overall_success, "✓ SUCCESS", "✗ FAILED"), "\n")

  if (overall_success) {
    cat("\n🎉 Environment setup completed successfully!\n")
    cat("The Seatek R repository is ready for use.\n")
  } else {
    cat("\n⚠ Environment setup completed with issues.\n")
    cat("Please review the errors above and resolve them.\n")
  }

  list(
    success = overall_success,
    install_results = install_results,
    load_results = load_results,
    permission_results = permission_results
  )
}

# Run setup if script is executed directly
if (sys.nframe() == 0 && !interactive()) {
  main_setup()
} else if (interactive()) {
  cat("Environment setup script loaded.\n")
  cat("Run main_setup() to execute the complete setup.\n")
}
