import pytest
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../.github/scripts')))
from repository_automation import main, TASK_RUNNERS

@patch('sys.argv', ['repository_automation.py', 'unknown-task'])
def test_main_unknown_task(capsys):
    assert main() == 1
    captured = capsys.readouterr()
    assert "Unknown task: unknown-task" in captured.out

@patch('sys.argv', ['repository_automation.py', 'enforce'])
def test_main_enforce_no_result_path(capsys):
    assert main() == 1
    captured = capsys.readouterr()
    assert "enforce requires a result path" in captured.out

@patch('sys.argv', ['repository_automation.py', 'enforce', 'path/to/result.json'])
@patch('repository_automation.enforce_result')
def test_main_enforce_with_result_path(mock_enforce_result):
    mock_enforce_result.return_value = 0
    assert main() == 0
    mock_enforce_result.assert_called_once_with('path/to/result.json')

@patch('sys.argv', ['repository_automation.py', 'quality-assurance'])
@patch('repository_automation.load_config')
def test_main_valid_task(mock_load_config):
    mock_config = MagicMock()
    mock_load_config.return_value = mock_config

    # We mock the specific runner we are calling
    with patch.dict(TASK_RUNNERS, {'quality-assurance': MagicMock()}) as mock_runners:
        assert main() == 0
        mock_load_config.assert_called_once()
        mock_runners['quality-assurance'].assert_called_once_with(mock_config)
