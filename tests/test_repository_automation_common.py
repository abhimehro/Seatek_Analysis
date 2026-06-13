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
