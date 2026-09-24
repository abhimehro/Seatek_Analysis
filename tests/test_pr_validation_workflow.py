import os
import shutil
import subprocess  # nosec B404
from pathlib import Path

import pytest
import yaml

WORKFLOW_PATH = (
    Path(__file__).resolve().parents[1] / ".github" / "workflows" / "pr-validation.yml"
)


def test_pr_validation_propagates_pytest_failures(tmp_path):
    workflow = yaml.safe_load(WORKFLOW_PATH.read_text(encoding="utf-8"))
    steps = workflow["jobs"]["validate"]["steps"]
    test_step = next(step for step in steps if step["name"] == "Run tests")

    bash = shutil.which("bash")
    if bash is None:
        pytest.fail("bash not found in PATH; cannot run workflow shell test")

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()
    fake_python = fake_bin / "python"
    fake_python.write_text("#!/bin/sh\nexit 17\n", encoding="utf-8")
    fake_python.chmod(0o755)
    (tmp_path / "tests").mkdir()

    result = subprocess.run(  # nosec B603
        [bash, "-e", "-c", test_step["run"]],
        check=False,
        cwd=tmp_path,
        env={"PATH": f"{fake_bin}{os.pathsep}{os.environ.get('PATH', '')}"},
        shell=False,
    )

    assert result.returncode == 17  # nosec B101
