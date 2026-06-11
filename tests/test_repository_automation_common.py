import pytest
import sys

# Mock yaml module before any imports
sys.modules['yaml'] = type('MockYaml', (), {'safe_load': lambda x: {}, 'dump': lambda x, y: None})()

from unittest.mock import patch, MagicMock
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../.github/scripts')))
from repository_automation_common import run_shell_command, BASH_BIN

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
