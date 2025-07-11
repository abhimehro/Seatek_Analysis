# Seatek R Repository - Backup System Test Suite
# Phase 1.2: Backup System Testing
# Author: AI Assistant
# Date: 2025-07-11

# This test suite validates the backup system for the Seatek repository.
# It covers backup creation, restore, missing file handling, and permission issues.

source("../scripts/02_backup_system.R")
library(testthat)

# Helper: Create a test file or directory
create_test_file <- function(path, content = "test content") {
  writeLines(content, path)
}

create_test_dir <- function(dir_path) {
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
  create_test_file(file.path(dir_path, "file1.txt"), "file1")
  create_test_file(file.path(dir_path, "file2.txt"), "file2")
}

# Test 1: Backup creation for a file

test_that("create_backup() creates a backup for a file", {
  test_file <- "test_file.txt"
  create_test_file(test_file)
  backup_path <- create_backup(test_file, backup_dir = "test_backups")
  expect_true(!is.null(backup_path) && file.exists(backup_path),
              info = "Backup file should be created.")
  unlink(test_file)
  unlink("test_backups", recursive = TRUE)
})

# Test 2: Backup creation for a directory

test_that("create_backup() creates a backup for a directory", {
  test_dir <- "test_dir"
  create_test_dir(test_dir)
  backup_path <- create_backup(test_dir, backup_dir = "test_backups")
  expect_true(!is.null(backup_path) && file.exists(backup_path),
              info = "Backup archive should be created for directory.")
  unlink(test_dir, recursive = TRUE)
  unlink("test_backups", recursive = TRUE)
})

# Test 3: Restore operation verification

test_that("restore_backup() restores a backup correctly", {
  test_dir <- "test_dir"
  create_test_dir(test_dir)
  backup_path <- create_backup(test_dir, backup_dir = "test_backups")
  restore_dir <- "restored_dir"
  unlink(restore_dir, recursive = TRUE)
  result <- restore_backup(backup_path, restore_dir = restore_dir)
  expect_true(result, info = "Restore should succeed.")
  expect_true(file.exists(file.path(restore_dir, "file1.txt")),
              info = "Restored file1.txt should exist.")
  expect_true(file.exists(file.path(restore_dir, "file2.txt")),
              info = "Restored file2.txt should exist.")
  unlink(test_dir, recursive = TRUE)
  unlink("test_backups", recursive = TRUE)
  unlink(restore_dir, recursive = TRUE)
})

# Test 4: Handling missing backup files

test_that("restore_backup() handles missing backup files gracefully", {
  result <- restore_backup("nonexistent_backup.tar.gz", restore_dir = "should_not_exist")
  expect_false(result, info = "Restore should fail gracefully for missing backup file.")
  unlink("should_not_exist", recursive = TRUE)
})

# Test 5: Directory permission issues (simulate by using a non-writable directory)

test_that("create_backup() handles permission errors gracefully", {
  # Simulate by using an invalid backup directory
  test_file <- "test_file.txt"
  create_test_file(test_file)
  backup_path <- create_backup(test_file, backup_dir = "/root/forbidden_backups")
  expect_true(is.null(backup_path), info = "Should fail gracefully on permission error.")
  unlink(test_file)
})

test_that("cleanup_old_backups() deletes old backups only", {
  test_file <- "test_file.txt"
  create_test_file(test_file)
  backup_path <- create_backup(test_file, backup_dir = "test_backups")
  # Set mtime to 40 days ago
  Sys.setFileTime(backup_path, Sys.time() - 40*24*3600)
  deleted <- cleanup_old_backups("test_backups", days_to_keep = 30)
  expect_true(length(deleted) == 1, info = "Old backup should be deleted.")
  unlink("test_backups", recursive = TRUE)
  unlink(test_file)
})

test_that("list_backups() lists available backups", {
  test_file <- "test_file.txt"
  create_test_file(test_file)
  backup_path <- create_backup(test_file, backup_dir = "test_backups")
  info <- list_backups("test_backups")
  expect_true(nrow(info) >= 1, info = "Should list at least one backup.")
  unlink("test_backups", recursive = TRUE)
  unlink(test_file)
})

# Clean up after all tests
unlink("test_file.txt")
unlink("test_dir", recursive = TRUE)
unlink("restored_dir", recursive = TRUE)
unlink("test_backups", recursive = TRUE)