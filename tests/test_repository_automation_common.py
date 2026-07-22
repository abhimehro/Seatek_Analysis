import os
import sys
from unittest.mock import MagicMock, patch

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.github/scripts"))
)
from repository_automation_common import (
    BASH_BIN,
    is_commit_sha,
    numeric_version,
    run_shell_command,
    target_ref,
)


@patch("repository_automation_common.run_process")
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


@patch("repository_automation_common.run_process")
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


@patch("repository_automation_common.subprocess.run")
def test_run_process_allowlist(mock_run):
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "output"
    mock_proc.stderr = ""
    mock_run.return_value = mock_proc

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
    mock_proc = MagicMock()
    mock_proc.returncode = 0
    mock_proc.stdout = "output"
    mock_proc.stderr = ""
    mock_run_process.return_value = mock_proc

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
