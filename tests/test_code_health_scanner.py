import os
import pytest
from unittest.mock import patch
from code_health_scanner import read_file_safe, MAX_FILE_SIZE

def test_read_file_safe_success(tmp_path):
    test_file = tmp_path / "test.txt"
    content = "line1\nline2\n"
    test_file.write_text(content, encoding="utf-8")

    with patch("os.getcwd", return_value=str(tmp_path)):
        # We need to make sure os.path.realpath(os.getcwd()) returns tmp_path
        # tmp_path is already absolute and usually real.
        result = read_file_safe(str(test_file))
        assert result == ["line1\n", "line2\n"]

def test_read_file_safe_path_traversal(tmp_path):
    # File outside CWD
    outside_dir = tmp_path / "outside"
    outside_dir.mkdir()
    test_file = outside_dir / "secret.txt"
    test_file.write_text("secret", encoding="utf-8")

    cwd_dir = tmp_path / "cwd"
    cwd_dir.mkdir()

    with patch("os.getcwd", return_value=str(cwd_dir)):
        result = read_file_safe(str(test_file))
        assert result == []

def test_read_file_safe_too_large(tmp_path):
    test_file = tmp_path / "large.txt"
    # Write MAX_FILE_SIZE + 1 bytes
    with open(test_file, "w") as f:
        f.write("a" * (MAX_FILE_SIZE + 1))

    with patch("os.getcwd", return_value=str(tmp_path)):
        result = read_file_safe(str(test_file))
        assert result == []

def test_read_file_safe_not_found(tmp_path):
    test_file = tmp_path / "nonexistent.txt"
    with patch("os.getcwd", return_value=str(tmp_path)):
        result = read_file_safe(str(test_file))
        assert result == []

def test_read_file_safe_encoding_error(tmp_path):
    test_file = tmp_path / "binary.bin"
    with open(test_file, "wb") as f:
        f.write(b"\xff\xfe\xfd") # Invalid UTF-8

    with patch("os.getcwd", return_value=str(tmp_path)):
        result = read_file_safe(str(test_file))
        assert result == []

def test_read_file_safe_just_at_limit(tmp_path):
    test_file = tmp_path / "limit.txt"
    content = "a" * MAX_FILE_SIZE
    with open(test_file, "w") as f:
        f.write(content)

    with patch("os.getcwd", return_value=str(tmp_path)):
        result = read_file_safe(str(test_file))
        assert len(result) == 1
        assert result[0] == content
