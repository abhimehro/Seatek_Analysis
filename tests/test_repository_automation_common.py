import pytest
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../.github/scripts')))
from repository_automation_common import (
    BASH_BIN,
    is_commit_sha,
    numeric_version,
    run_shell_command,
    target_ref,
)

@patch('repository_automation_common.run_process')
def test_run_shell_command_string(mock_run_process):
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "output"
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc

    result = run_shell_command("echo hello")

    # Assert that bash -c is used instead of bash -lc
    mock_run_process.assert_called_once()
    args = mock_run_process.call_args[0][0]
    assert args == [BASH_BIN, "-c", "echo hello"]
    assert result["exit_code"] == 0

@patch('repository_automation_common.run_process')
def test_run_shell_command_list(mock_run_process):
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "output"
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc

    result = run_shell_command(["echo", "hello"])

    mock_run_process.assert_called_once()
    args = mock_run_process.call_args[0][0]
    assert args == ["echo", "hello"]
    assert result["exit_code"] == 0


def test_is_commit_sha_detects_full_length_pins() -> None:
    assert is_commit_sha("df4cb1c069e1874edd31b4311f1884172cec0e10")
    assert not is_commit_sha("v6.0.3")
    assert not is_commit_sha("bc0d8b91")


def test_target_ref_skips_commit_pins() -> None:
    sha = "df4cb1c069e1874edd31b4311f1884172cec0e10"
    assert numeric_version(sha) is None
    assert target_ref(sha, "v6.0.4") is None


def test_numeric_version_extracts_tuples_and_handles_edge_cases() -> None:
    # Full versions
    assert numeric_version("v1.2.3") == (1, 2, 3)
    assert numeric_version("1.2.3") == (1, 2, 3)

    # Partial versions (missing patch, missing minor)
    assert numeric_version("v1.2") == (1, 2, 0)
    assert numeric_version("v1") == (1, 0, 0)
    assert numeric_version("4.5") == (4, 5, 0)
    assert numeric_version("4") == (4, 0, 0)

    # Versions with prefixes or suffixes
    assert numeric_version("v2.0.0-rc.1") == (2, 0, 0)
    assert numeric_version("v5.6.7-beta") == (5, 6, 7)
    assert numeric_version("pkg-v3.4.5") == (3, 4, 5)

    # Invalid formats
    assert numeric_version("invalid") is None
    assert numeric_version("v") is None
    assert numeric_version("a.b.c") is None
    assert numeric_version("") is None

    # Commit SHA
    sha = "df4cb1c069e1874edd31b4311f1884172cec0e10"
    assert numeric_version(sha) is None
