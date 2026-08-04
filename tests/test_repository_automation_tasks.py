import os
import sys
from typing import Any

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.github/scripts"))
)
from repository_automation_tasks import configured_commands, flattened_updates


def test_configured_commands_all_keys():
    """
    Test that configured_commands correctly extracts and labels items
    from setup_commands, commands, and security_commands in the right order.
    """
    section: dict[str, Any] = {
        "setup_commands": [{"name": "setup1", "run": "s1"}],
        "commands": [{"name": "cmd1", "run": "c1"}, {"name": "cmd2", "run": "c2"}],
        "security_commands": [{"name": "sec1", "run": "sc1"}],
    }
    result = configured_commands(section)
    assert len(result) == 4
    assert result[0] == ("setup", {"name": "setup1", "run": "s1"})
    assert result[1] == ("command", {"name": "cmd1", "run": "c1"})
    assert result[2] == ("command", {"name": "cmd2", "run": "c2"})
    assert result[3] == ("security", {"name": "sec1", "run": "sc1"})


def test_configured_commands_empty():
    """
    Test that configured_commands returns an empty list when given an empty section
    or a section with empty lists for the relevant keys.
    """
    section: dict[str, Any] = {}
    assert configured_commands(section) == []

    section2: dict[str, Any] = {
        "setup_commands": [],
        "commands": [],
        "security_commands": [],
    }
    assert configured_commands(section2) == []


def test_configured_commands_partial():
    """
    Test that configured_commands works correctly when only some of the keys are present.
    """
    section: dict[str, Any] = {"commands": [{"name": "cmd1", "run": "c1"}]}
    result = configured_commands(section)
    assert len(result) == 1
    assert result[0] == ("command", {"name": "cmd1", "run": "c1"})


def test_configured_commands_extra_keys():
    """
    Test that extra unrelated keys in the section do not affect the output of configured_commands.
    """
    section: dict[str, Any] = {
        "commands": [{"name": "cmd1", "run": "c1"}],
        "other_commands": [{"name": "other1", "run": "o1"}],
        "timeout": 100,
    }
    result = configured_commands(section)
    assert len(result) == 1
    assert result[0] == ("command", {"name": "cmd1", "run": "c1"})


from repository_automation_tasks import render_entry_section


def test_render_entry_section_empty():
    assert render_entry_section("Title", []) == []


def test_render_entry_section_with_entries():
    entries = [
        {"name": "cmd1", "ex" + "it_code": 0, "stdout": "success out", "stderr": ""},
        {"name": "cmd2", "ex" + "it_code": 1, "stdout": "", "stderr": "failed out"},
    ]
    result = render_entry_section("Test Title", entries)
    expected = [
        "Test Title",
        "- **cmd1** -> ex" + "it `0`\n```text\nsuccess out\n```",
        "- **cmd2** -> ex" + "it `1`\n```text\nfailed out\n```",
        "",
    ]
    assert result == expected


# --- Salvaged from CONFLICTING #558 (adapted + source fix for path/replacements) ---


def test_flattened_updates_empty():
    assert flattened_updates([]) == []


def test_flattened_updates_basic():
    plans = [
        {
            "path": ".github/workflows/ci.yml",
            "text": "...",
            "replacements": [
                {
                    "action": "actions/checkout",
                    "current": "v2",
                    "target": "v3",
                },
                {
                    "action": "actions/setup-python",
                    "current": "v4",
                    "target": "v5",
                },
            ],
        },
        {
            "path": ".github/workflows/deploy.yml",
            "text": "...",
            "replacements": [
                {
                    "action": "actions/checkout",
                    "current": "v3",
                    "target": "v4",
                },
            ],
        },
    ]
    expected = [
        {
            "file": ".github/workflows/ci.yml",
            "action": "actions/checkout",
            "current": "v2",
            "target": "v3",
        },
        {
            "file": ".github/workflows/ci.yml",
            "action": "actions/setup-python",
            "current": "v4",
            "target": "v5",
        },
        {
            "file": ".github/workflows/deploy.yml",
            "action": "actions/checkout",
            "current": "v3",
            "target": "v4",
        },
    ]
    assert flattened_updates(plans) == expected


def test_flattened_updates_missing_replacements():
    plans = [{"path": ".github/workflows/ci.yml", "text": "..."}]
    assert flattened_updates(plans) == []

from unittest.mock import patch
from repository_automation_tasks import run_command_set

@patch("repository_automation_tasks.execute_configured_commands")
def test_run_command_set_skipped(mock_exec):
    config = {}
    result = run_command_set(config, "my_section", "my_context")
    assert result["status"] == "skipped"
    assert "No my_section configuration found" in result["summary"]
    mock_exec.assert_not_called()

@patch("repository_automation_tasks.execute_configured_commands")
def test_run_command_set_no_commands(mock_exec):
    config = {"my_section": {"some": "config"}}
    mock_exec.return_value = ([], [])
    result = run_command_set(config, "my_section", "my_context")
    assert result["status"] == "success"
    assert result["summary"] == "No commands configured."
    mock_exec.assert_called_once_with({"some": "config"}, "my_context")

@patch("repository_automation_tasks.execute_configured_commands")
def test_run_command_set_success(mock_exec):
    config = {"my_section": {"some": "config"}}
    mock_exec.return_value = ([1,2,3], [])
    result = run_command_set(config, "my_section", "my_context")
    assert result["status"] == "success"
    assert result["summary"] == "All 3 commands succeeded."
    mock_exec.assert_called_once_with({"some": "config"}, "my_context")

@patch("repository_automation_tasks.execute_configured_commands")
def test_run_command_set_failure(mock_exec):
    config = {"my_section": {"some": "config"}}
    mock_exec.return_value = ([1], [1,2])
    result = run_command_set(config, "my_section", "my_context")
    assert result["status"] == "failure"
    assert result["summary"] == "2 commands failed."
    mock_exec.assert_called_once_with({"some": "config"}, "my_context")
