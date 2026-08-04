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


from repository_automation_tasks import render_command_entry_section, render_entry_section, render_review_section


def test_render_command_entry_section_empty():
    assert render_command_entry_section("Title", []) == []


def test_render_command_entry_section_with_entries():
    entries = [
        {"name": "cmd1", "ex" + "it_code": 0, "stdout": "success out", "stderr": ""},
        {"name": "cmd2", "ex" + "it_code": 1, "stdout": "", "stderr": "failed out"},
    ]
    result = render_command_entry_section("Test Title", entries)
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


def test_render_entry_section_empty():
    assert render_entry_section("Title", []) == []

def test_render_entry_section_with_entries():
    entries = [
        {
            "number": 123,
            "title": "Fix bug",
            "url": "https://github.com/org/repo/pull/123",
            "author": {"login": "johndoe"}
        },
        {
            "number": 124,
            "title": "Add feature",
            # missing url to test edge case
            "author": {"login": "janedoe"}
        }
    ]
    result = render_entry_section("PRs", entries)
    expected = [
        "PRs",
        "- [#123](https://github.com/org/repo/pull/123) **Fix bug** (@johndoe)",
        "- #124 **Add feature** (@janedoe)",
        ""
    ]
    assert result == expected

def test_render_review_section_empty():
    assert render_review_section("Title", [], "APPROVED") == []

def test_render_review_section_filtering():
    entries = [
        {
            "number": 101,
            "title": "PR 1",
            "url": "http://example.com/101",
            "author": {"login": "alice"},
            "reviewDecision": "APPROVED"
        },
        {
            "number": 102,
            "title": "PR 2",
            "url": "http://example.com/102",
            "author": {"login": "bob"},
            "reviewDecision": "CHANGES_REQUESTED"
        },
        {
            "number": 103,
            "title": "PR 3",
            "url": "http://example.com/103",
            "author": {"login": "charlie"},
            "reviewDecision": "APPROVED"
        }
    ]

    # Should only return APPROVED PRs
    result = render_review_section("Approved PRs", entries, "APPROVED")
    expected = [
        "Approved PRs",
        "- [#101](http://example.com/101) **PR 1** (@alice)",
        "- [#103](http://example.com/103) **PR 3** (@charlie)",
        ""
    ]
    assert result == expected

def test_render_review_section_no_match():
    entries = [
        {
            "number": 101,
            "title": "PR 1",
            "url": "http://example.com/101",
            "author": {"login": "alice"},
            "reviewDecision": "CHANGES_REQUESTED"
        }
    ]

    result = render_review_section("Approved PRs", entries, "APPROVED")
    assert result == []
