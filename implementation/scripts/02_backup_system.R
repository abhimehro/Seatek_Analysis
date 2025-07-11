# Seatek R Repository - Backup System
# Phase 1.2: Backup System Implementation
# Author: AI Assistant
# Date: 2025-07-11

# This script provides robust backup and restore functionality for the Seatek repository.
# It supports timestamp-based backup naming, listing, restoration, and cleanup with retention policy.

#' Create a backup of the specified directory or file
#' @param target_path Path to file or directory to backup
#' @param backup_dir Directory where backups are stored (default: 'backups')
#' @return Path to created backup or error message
create_backup <- function(target_path, backup_dir = "backups") {
  tryCatch({
    if (!file.exists(target_path)) {
      stop(sprintf("Target path does not exist: %s", target_path))
    }
    if (!dir.exists(backup_dir)) {
      dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
    }
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    base_name <- basename(normalizePath(target_path))
    backup_name <- sprintf("%s_%s.tar.gz", base_name, timestamp)
    backup_path <- file.path(backup_dir, backup_name)
    
    # Use tar for both files and directories
    tar_result <- utils::tar(backup_path, files = target_path, compression = "gzip", tar = "internal")
    if (!file.exists(backup_path)) {
      stop("Backup creation failed: ", backup_path)
    }
    message(sprintf("Backup created: %s", backup_path))
    return(backup_path)
  }, error = function(e) {
    message(sprintf("[ERROR] create_backup: %s", e$message))
    return(NULL)
  })
}

#' Restore a backup to the specified location
#' @param backup_file Path to backup file (.tar.gz)
#' @param restore_dir Directory to restore into (default: current working directory)
#' @return TRUE if successful, FALSE otherwise
restore_backup <- function(backup_file, restore_dir = getwd()) {
  tryCatch({
    if (!file.exists(backup_file)) {
      stop(sprintf("Backup file does not exist: %s", backup_file))
    }
    if (!dir.exists(restore_dir)) {
      dir.create(restore_dir, recursive = TRUE, showWarnings = FALSE)
    }
    utils::untar(backup_file, exdir = restore_dir)
    # Verify restoration
    contents <- utils::untar(backup_file, list = TRUE)
    restored <- all(file.exists(file.path(restore_dir, contents)))
    if (!restored) {
      stop("Restore verification failed: Not all files restored.")
    }
    message(sprintf("Backup restored to: %s", restore_dir))
    return(TRUE)
  }, error = function(e) {
    message(sprintf("[ERROR] restore_backup: %s", e$message))
    return(FALSE)
  })
}

#' List available backups in the backup directory
#' @param backup_dir Directory where backups are stored (default: 'backups')
#' @return Data frame of available backups
list_backups <- function(backup_dir = "backups") {
  tryCatch({
    if (!dir.exists(backup_dir)) {
      message(sprintf("Backup directory does not exist: %s", backup_dir))
      return(data.frame())
    }
    files <- list.files(backup_dir, pattern = "\.tar\.gz$", full.names = TRUE)
    if (length(files) == 0) {
      message("No backups found.")
      return(data.frame())
    }
    info <- data.frame(
      file = basename(files),
      path = files,
      size_MB = round(file.info(files)$size / 1e6, 2),
      modified = file.info(files)$mtime,
      stringsAsFactors = FALSE
    )
    info <- info[order(info$modified, decreasing = TRUE), ]
    return(info)
  }, error = function(e) {
    message(sprintf("[ERROR] list_backups: %s", e$message))
    return(data.frame())
  })
}

#' Cleanup old backups based on retention policy
#' @param backup_dir Directory where backups are stored (default: 'backups')
#' @param days_to_keep Number of days to retain backups (default: 30)
#' @return Vector of deleted backup file names
cleanup_old_backups <- function(backup_dir = "backups", days_to_keep = 30) {
  tryCatch({
    if (!dir.exists(backup_dir)) {
      message(sprintf("Backup directory does not exist: %s", backup_dir))
      return(character(0))
    }
    files <- list.files(backup_dir, pattern = "\.tar\.gz$", full.names = TRUE)
    if (length(files) == 0) {
      message("No backups to clean up.")
      return(character(0))
    }
    now <- Sys.time()
    file_info <- file.info(files)
    age_days <- as.numeric(difftime(now, file_info$mtime, units = "days"))
    to_delete <- files[age_days > days_to_keep]
    deleted <- character(0)
    for (f in to_delete) {
      result <- tryCatch({
        file.remove(f)
        deleted <- c(deleted, f)
      }, error = function(e) {
        message(sprintf("[ERROR] cleanup_old_backups: %s", e$message))
      })
    }
    if (length(deleted) > 0) {
      message(sprintf("Deleted %d old backups.", length(deleted)))
    } else {
      message("No old backups deleted.")
    }
    return(deleted)
  }, error = function(e) {
    message(sprintf("[ERROR] cleanup_old_backups: %s", e$message))
    return(character(0))
  })
}

#' Example usage (uncomment to run)
# create_backup("Data")
# list_backups()
# restore_backup("backups/Data_20250711_120000.tar.gz", "Data_restored")
# cleanup_old_backups()