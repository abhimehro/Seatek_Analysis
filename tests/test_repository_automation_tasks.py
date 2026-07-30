import os
import sys
from typing import Any

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.github/scripts"))
)
from repository_automation_tasks import configured_commands, classify_entries


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



def test_classify_entries_success():
    entries = [{"state": "success", "id": 1}, {"state": "success", "id": 2}]
    result = classify_entries(entries)
    assert result == {"success": entries}

def test_classify_entries_mixed():
    entries = [{"state": "success", "id": 1}, {"state": "failure", "id": 2}]
    result = classify_entries(entries)
    assert result == {"success": [{"state": "success", "id": 1}], "failure": [{"state": "failure", "id": 2}]}

def test_classify_entries_default_unknown():
    entries = [{"id": 1}]
    result = classify_entries(entries)
    assert result == {"unknown": entries}

def test_classify_entries_custom_key():
    entries = [{"status": "pass", "id": 1}, {"status": "fail", "id": 2}]
    result = classify_entries(entries, key="status")
    assert result == {"pass": [{"status": "pass", "id": 1}], "fail": [{"status": "fail", "id": 2}]}

def test_classify_entries_empty():
    assert classify_entries([]) == {}
