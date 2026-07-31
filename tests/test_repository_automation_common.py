import datetime as dt
import os
import sys
from unittest.mock import MagicMock, patch

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.github/scripts"))
)
from repository_automation_common import (
    BASH_BIN,
    command_env,
    filter_env_securely,
    is_commit_sha,
    iso_day,
    numeric_version,
    run_shell_command,
    target_ref,
    truncate,
)


def setup_mock_process(mock_run_process):
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "output"
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc


@patch("repository_automation_common.run_process")
def test_run_shell_command_string(mock_run_process):
    setup_mock_process(mock_run_process)

    result = run_shell_command("echo hello")

    # Assert that bash -c is used instead of bash -lc
    mock_run_process.assert_called_once()
    args = mock_run_process.call_args[0][0]
    assert args == [BASH_BIN, "-c", "echo hello"]
    assert result["exit_code"] == 0


@patch("repository_automation_common.run_process")
def test_run_shell_command_list(mock_run_process):
    setup_mock_process(mock_run_process)

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


@patch("repository_automation_common.subprocess.run")
def test_run_process_allowlist(mock_run):
    setup_mock_process(mock_run)

    from repository_automation_common import run_process

    # Test that standard env vars are kept and sensitive ones are stripped
    test_env = {
        "PATH": "/usr/bin",
        "HOME": "/home/user",
        "AWS_ACCESS_KEY_ID": "DUMMY_VALUE_1",
        "NPM_TOKEN": "DUMMY_VALUE_2",
        "GH_TOKEN": "DUMMY_VALUE_3",
        "GITHUB_TOKEN": "DUMMY_VALUE_4",
        "GITHUB_WORKSPACE": "/workspace",
    }

    run_process(["echo", "hello"], env=test_env)

    mock_run.assert_called_once()
    passed_env = mock_run.call_args[1].get("env", {})

    # Check safe vars
    assert passed_env.get("PATH") == "/usr/bin"
    assert passed_env.get("HOME") == "/home/user"
    assert passed_env.get("GITHUB_WORKSPACE") == "/workspace"

    # Check sensitive vars are stripped
    assert "AWS_ACCESS_KEY_ID" not in passed_env
    assert "NPM_TOKEN" not in passed_env
    assert "GH_TOKEN" not in passed_env
    assert "GITHUB_TOKEN" not in passed_env


@patch("repository_automation_common.run_process")
def test_run_shell_command_allowlist_and_custom(mock_run_process):
    setup_mock_process(mock_run_process)

    # Ensure os.environ has some sensitive stuff for the default safe_env grab
    with patch.dict(os.environ, {"AWS_ACCESS_KEY_ID": "DUMMY_VALUE_1", "PATH": "/bin"}):
        run_shell_command(
            "echo hello",
            custom_env={"MY_VAR": "custom_val", "GH_TOKEN": "should_be_stripped"},
        )

        mock_run_process.assert_called_once()
        passed_env = mock_run_process.call_args[1].get("env", {})

        # Check that os.environ sensitive is stripped by command_env -> allowlist logic
        assert "AWS_ACCESS_KEY_ID" not in passed_env
        assert passed_env.get("PATH") == "/bin"

        # Check custom_env is respected
        assert passed_env.get("MY_VAR") == "custom_val"

        # Check GH_TOKEN explicitly stripped even if in custom_env
        assert "GH_TOKEN" not in passed_env


def test_command_env() -> None:
    # Test that existing env is preserved and GH_PAGER is forced to cat
    with patch.dict(
        os.environ, {"MY_TEST_VAR": "hello", "GH_PAGER": "less"}, clear=True
    ):
        env = command_env()
        assert env.get("MY_TEST_VAR") == "hello"
        assert env.get("GH_PAGER") == "cat"


# --- Salvaged from CONFLICTING #551 / #553 / #557 (adapted to main APIs) ---


def test_iso_day_with_value():
    known_time = dt.datetime(2024, 10, 15, 12, 30, 45, tzinfo=dt.UTC)
    assert iso_day(known_time) == "2024-10-15"


@patch("repository_automation_common.now_utc")
def test_iso_day_default(mock_now_utc):
    mock_now_utc.return_value = dt.datetime(2023, 5, 2, 8, 15, 0, tzinfo=dt.UTC)
    assert iso_day() == "2023-05-02"
    mock_now_utc.assert_called_once()


def test_truncate() -> None:
    assert truncate("hello", 10) == "hello"
    exact_match = "1234567890"
    assert truncate(exact_match, 10) == exact_match
    long_text = "This is a very long text that needs to be truncated"
    truncated = truncate(long_text, 20)
    # Implementation: text[: limit - 15] + "\n... [truncated]"
    assert truncated == long_text[: 20 - 15] + "\n... [truncated]"
    assert truncated.endswith("\n... [truncated]")
    assert len(truncated) < len(long_text)


def test_filter_env_securely():
    base_env = {
        "PATH": "/usr/bin",
        "HOME": "/home/user",
        "GITHUB_WORKSPACE": "/workspace",
        "UNSAFE_VAR": "secret_data",
        "MY_TOKEN": "DUMMY_VALUE_1",
        "RANDOM_PASSWORD": "DUMMY_VALUE_2",
        "AWS_SECRET_KEY": "DUMMY_VALUE_3",
        "GITHUB_SECRET": "should_be_stripped",
        "GITHUB_PASSWORD": "dummy",
        "GITHUB_KEY": "dummy",
    }
    custom_env = {
        "MY_CUSTOM_VAR": "custom_value",
        "GH_TOKEN": "should_be_stripped",
        "GITHUB_TOKEN": "should_be_stripped_too",
    }

    result = filter_env_securely(base_env, custom_env)

    assert result.get("PATH") == "/usr/bin"
    assert result.get("HOME") == "/home/user"
    assert result.get("GITHUB_WORKSPACE") == "/workspace"
    assert "UNSAFE_VAR" not in result
    assert "MY_TOKEN" not in result
    assert "RANDOM_PASSWORD" not in result
    assert "AWS_SECRET_KEY" not in result
    assert "GITHUB_SECRET" not in result
    assert "GITHUB_PASSWORD" not in result
    assert "GITHUB_KEY" not in result
    assert result.get("MY_CUSTOM_VAR") == "custom_value"
    assert "GH_TOKEN" not in result
    assert "GITHUB_TOKEN" not in result
