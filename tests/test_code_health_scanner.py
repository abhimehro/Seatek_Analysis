import os
import pytest
from code_health_scanner import get_repo_info, read_file_safe, get_language, scan_file, MAX_FILE_SIZE

def test_get_repo_info():
    account, project, commit_hash = get_repo_info()
    assert account == "account"
    assert project == "project"
    assert commit_hash == "hash"

def test_get_language():
    assert get_language("test.py") == "python"
    assert get_language("test.R") == "r"
    assert get_language("test.js") == "javascript"
    assert get_language("test.ts") == "typescript"
    assert get_language("test.txt") == "unknown"

def test_get_language_mixed_case_extensions():
    # Ensure case-insensitive matching covers mixed-case extensions too.
    assert get_language("test.Py") == "python"
    assert get_language("test.pY") == "python"
    assert get_language("test.PY") == "python"
    assert get_language("test.Js") == "javascript"
    assert get_language("test.jS") == "javascript"
    assert get_language("test.Ts") == "typescript"
    assert get_language("test.tS") == "typescript"

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
    # We use a path that is guaranteed to be outside CWD
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

def test_scan_file_python_todo():
    filepath = "test.py"
    lines = ["print('hello')\n", "print('TODO')\n", "TODO\n"]
    issues = scan_file(filepath, lines, "acc", "proj", "hash")
    assert len(issues) == 1
    assert "TODO in test.py:2" in issues[0]

def test_scan_file_python_no_todo():
    filepath = "test.py"
    lines = ["print('hello')\n", "# TODO: fix this\n"]
    issues = scan_file(filepath, lines, "acc", "proj", "hash")
    assert issues == []

def test_scan_file_unknown_lang():
    filepath = "test.unknown"
    lines = ["print('TODO')\n"]
    issues = scan_file(filepath, lines, "acc", "proj", "hash")
    assert issues == []
