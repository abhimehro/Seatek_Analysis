import os
import subprocess
from unittest.mock import patch

from code_health_scanner import (
    MAX_FILE_SIZE,
    get_repo_info,
    read_file_safe,
)


def test_get_repo_info_https():
    with patch("subprocess.check_output") as mock_run:
        mock_run.side_effect = ["https://github.com/account/project.git\n", "hash\n"]
        account, project, commit_hash = get_repo_info()
        assert account == "account"
        assert project == "project"
        assert commit_hash == "hash"


def test_get_repo_info_ssh():
    with patch("subprocess.check_output") as mock_run:
        mock_run.side_effect = ["git@github.com:account/project.git\n", "hash\n"]
        account, project, commit_hash = get_repo_info()
        assert account == "account"
        assert project == "project"
        assert commit_hash == "hash"


def test_get_repo_info_no_dot_git():
    with patch("subprocess.check_output") as mock_run:
        mock_run.side_effect = ["https://github.com/account/project\n", "hash\n"]
        account, project, commit_hash = get_repo_info()
        assert account == "account"
        assert project == "project"
        assert commit_hash == "hash"


def test_get_repo_info_failure():
    with patch("subprocess.check_output") as mock_run:
        mock_run.side_effect = subprocess.CalledProcessError(1, "git")
        account, project, commit_hash = get_repo_info()
        assert account == "unknown"
        assert project == "unknown"
        assert commit_hash == "unknown"


def test_read_file_safe_happy_path():
    test_file = "test_happy.txt"
    content = "line1\nline2\n"
    with open(test_file, "w") as f:
        f.write(content)
    try:
        read_lines = read_file_safe(test_file)
        assert read_lines == ["line1\n", "line2\n"]
    finally:
        if os.path.exists(test_file):
            os.remove(test_file)


def test_read_file_safe_path_traversal():
    # Attempting to read a file outside CWD should return empty list
    assert read_file_safe("/etc/passwd") == []


def test_read_file_safe_too_large():
    test_file = "test_large.txt"
    # Create a file exactly MAX_FILE_SIZE + 1 bytes
    with open(test_file, "w") as f:
        f.write("a" * (MAX_FILE_SIZE + 1))
    try:
        assert read_file_safe(test_file) == []
    finally:
        if os.path.exists(test_file):
            os.remove(test_file)


def test_read_file_safe_non_existent():
    assert read_file_safe("non_existent_file_12345.txt") == []


def test_get_repo_info_exception_logging(caplog):
    import logging

    with patch("subprocess.check_output") as mock_run:
        mock_run.side_effect = Exception("Some hidden internal error")
        with caplog.at_level(logging.ERROR):
            account, project, commit_hash = get_repo_info()

        assert account == "unknown"
        assert project == "unknown"
        assert commit_hash == "unknown"

        assert (
            "Error getting repo info: Internal error occurred (Exception)."
            in caplog.text
        )
        assert "Some hidden internal error" not in caplog.text


def test_read_file_safe_null_byte():
    # Attempting to read a file with an embedded null character should return empty list
    # and not raise a ValueError (ValueError: lstat: embedded null character in path)
    assert read_file_safe("test\0.txt") == []


def test_read_file_safe_null_byte_pathlib():
    # Validates that path-like objects (e.g. pathlib.Path) are cast to strings
    # correctly during the null byte check, preventing TypeErrors in Python 3.12+
    class MockPath:
        def __str__(self):
            return "test\0.txt"

    assert read_file_safe(MockPath()) == []


def test_read_file_safe_restricted_permissions():
    test_file = "test_restricted.txt"
    with open(test_file, "w") as f:
        f.write("test content")
    try:
        # Remove read permissions
        os.chmod(test_file, 0o000)
        assert read_file_safe(test_file) == []
    finally:
        # Restore permissions so it can be deleted
        if os.path.exists(test_file):
            os.chmod(test_file, 0o644)
            os.remove(test_file)
