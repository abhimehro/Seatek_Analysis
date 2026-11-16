import datetime as dt
import os
import subprocess  # nosec B404
import sys
from unittest.mock import MagicMock, patch

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.github/scripts"))
)

import json

import pytest
from repository_automation_common import (
    _remove_heuristic_secrets,
    command_env,
    filter_env_securely,
    gh_json,
    is_commit_sha,
    iso_day,
    now_utc,
    numeric_version,
    run_checked,
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
def test_run_shell_command_string_raises_value_error(mock_run_process):
    import pytest

    with pytest.raises(
        ValueError,
        match="command must be a list of arguments to avoid shell injection",
    ):
        run_shell_command("echo hello")

    mock_run_process.assert_not_called()


@patch("repository_automation_common.run_process")
def test_run_shell_command_list(mock_run_process):
    setup_mock_process(mock_run_process)

    result = run_shell_command(["echo", "hello"])

    mock_run_process.assert_called_once()
    args = mock_run_process.call_args[0][0]
    assert args == ["echo", "hello"]
    assert result["exit_code"] == 0


@patch("repository_automation_common.run_process")
def test_run_checked_success(mock_run_process):
    """Test run_checked delegates to run_process with check=True."""
    setup_mock_process(mock_run_process)

    result = run_checked(["git", "status"])

    mock_run_process.assert_called_once_with(["git", "status"], check=True)
    assert result == mock_run_process.return_value
    assert not result.returncode
    assert result.stdout == "output"


@patch("repository_automation_common.run_process")
def test_run_checked_failure(mock_run_process):
    """Test run_checked propagates CalledProcessError on non-zero exit."""
    mock_run_process.side_effect = subprocess.CalledProcessError(
        returncode=1, cmd=["git", "status"], output="", stderr="error"
    )

    with pytest.raises(subprocess.CalledProcessError) as exc_info:
        run_checked(["git", "status"])

    assert exc_info.value.returncode == 1
    mock_run_process.assert_called_once_with(["git", "status"], check=True)


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
            ["echo", "hello"],
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


def test_now_utc():
    now = now_utc()
    assert isinstance(now, dt.datetime)
    assert now.tzinfo == dt.UTC


def test_now_utc_mocked():
    with patch("repository_automation_common.dt.datetime") as mock_datetime:
        expected = dt.datetime(2025, 1, 1, 12, 0, 0, tzinfo=dt.UTC)
        mock_datetime.now.return_value = expected
        assert now_utc() == expected
        mock_datetime.now.assert_called_once_with(dt.UTC)


@patch("repository_automation_common.Path.read_text")
def test_load_config_with_automation(mock_read_text):
    mock_read_text.return_value = "automation:\n  enabled: true\n  key: value\n"
    from repository_automation_common import load_config

    result = load_config()

    assert result == {"enabled": True, "key": "value"}
    mock_read_text.assert_called_once()


@patch("repository_automation_common.Path.read_text")
def test_load_config_without_automation(mock_read_text):
    mock_read_text.return_value = "other_section:\n  some_key: 123\n"
    from repository_automation_common import load_config

    result = load_config()

    assert result == {}
    mock_read_text.assert_called_once()


@patch("repository_automation_common.Path.read_text")
def test_load_config_empty_file(mock_read_text):
    mock_read_text.return_value = ""
    from repository_automation_common import load_config

    result = load_config()

    assert result == {}
    mock_read_text.assert_called_once()


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


def test_remove_heuristic_secrets():
    env = {
        "SAFE_VAR": "keep_me",
        "AWS_TOKEN": "remove_me",
        "my_secret_key": "remove_me",
        "DB_PASSWORD_PROD": "remove_me",
        "AUTH_BEARER": "remove_me",
        "GITHUB_CRED": "remove_me",
        "REGULAR_SETTING": "keep_me_too",
    }

    _remove_heuristic_secrets(env)

    assert env.get("SAFE_VAR") == "keep_me"
    assert env.get("REGULAR_SETTING") == "keep_me_too"
    assert "AWS_TOKEN" not in env
    assert "my_secret_key" not in env
    assert "DB_PASSWORD_PROD" not in env
    assert "AUTH_BEARER" not in env
    assert "GITHUB_CRED" not in env


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


@pytest.mark.parametrize(
    "used_val, context, expected_err",
    [
        ("default_val", "", "Warning: Using default value 'default_val' for MY_VAR\n"),
        (
            "default_val",
            "unit-test",
            "Warning: Using default value 'default_val' for MY_VAR in unit-test\n",
        ),
        ("other", "", ""),
    ],
)
def test_warn_on_default_param(used_val, context, expected_err, capsys):
    from repository_automation_common import warn_on_default

    warn_on_default("MY_VAR", used_val, "default_val", context)
    captured = capsys.readouterr()
    assert captured.err == expected_err


def test_warn_on_failure_emits(capsys):
    from repository_automation_common import warn_on_failure

    # MagicMock imported at module scope

    proc = MagicMock()
    proc.returncode = 1
    proc.stderr = "boom"
    proc.stdout = ""
    warn_on_failure("gh", ["api"], proc)
    err = capsys.readouterr().err
    assert "gh" in err
    assert "boom" in err


def test_task_dir(tmp_path):
    from repository_automation_common import task_dir

    with patch("repository_automation_common.OUTPUT_ROOT", tmp_path):
        result = task_dir("test_task")
        assert result == tmp_path / "test_task"
        assert result.is_dir()


def test_enforce_result_missing_file(tmp_path, capsys):
    from repository_automation_common import enforce_result

    missing_path = tmp_path / "nonexistent" / "result.json"
    result = enforce_result(str(missing_path))

    assert result == 1
    captured = capsys.readouterr()
    assert f"Missing task result: {missing_path}" in captured.out


@pytest.mark.parametrize(
    "status, expected_exit_code",
    [
        ("failure", 1),
        ("needs_review", 1),
        ("success", 0),
        ("warning", 0),
        ("skipped", 0),
        (None, 0),
    ],
)
def test_enforce_result_statuses(tmp_path, status, expected_exit_code):
    import json
    from repository_automation_common import enforce_result

    result_file = tmp_path / "result.json"
    data = {}
    if status is not None:
        data["status"] = status
    result_file.write_text(json.dumps(data))

    exit_code = enforce_result(str(result_file))
    assert exit_code == expected_exit_code


@patch("repository_automation_common.run_process")
def test_gh_json_invalid_json_raises_decode_error(mock_run_process):
    """Test gh_json raises JSONDecodeError when output is invalid JSON."""
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "not valid json {["
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc

    with pytest.raises(json.JSONDecodeError):
        gh_json(["repo", "view"])

    mock_run_process.assert_called_once()


@patch("repository_automation_common.run_process")
def test_gh_json_success(mock_run_process):
    """Test gh_json successfully decodes valid JSON."""
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = '{"name": "test-repo", "stars": 42}\n'
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc

    result = gh_json(["repo", "view"])
    assert result == {"name": "test-repo", "stars": 42}
    mock_run_process.assert_called_once()


@patch("repository_automation_common.run_process")
def test_gh_json_empty_output_returns_default(mock_run_process):
    """Test gh_json returns default when stdout is empty."""
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "   \n"
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc

    result = gh_json(["issue", "list"], default=[])
    assert result == []
    mock_run_process.assert_called_once()


@patch("repository_automation_common.run_process")
def test_gh_json_nonzero_exit_raises_runtime_error(mock_run_process):
    """Test gh_json raises RuntimeError on non-zero exit when default is None."""
    mock_proc = MagicMock()
    mock_proc.returncode = 1
    mock_proc.stdout = ""
    mock_proc.stderr = "graphql error: unauthorized"
    mock_run_process.return_value = mock_proc

    with pytest.raises(RuntimeError, match="graphql error: unauthorized"):
        gh_json(["api", "graphql"])

    mock_run_process.assert_called_once()


@patch("repository_automation_common.warn_on_failure")
@patch("repository_automation_common.run_process")
def test_gh_json_nonzero_exit_returns_default(mock_run_process, mock_warn):
    """Test gh_json warns and returns default on non-zero exit when default is provided."""
    mock_proc = MagicMock()
    mock_proc.returncode = 1
    mock_proc.stdout = ""
    mock_proc.stderr = "api error"
    mock_run_process.return_value = mock_proc

    result = gh_json(["issue", "list"], default={"items": []})
    assert result == {"items": []}
    mock_run_process.assert_called_once()
    mock_warn.assert_called_once_with("gh", ["issue", "list"], mock_proc)
