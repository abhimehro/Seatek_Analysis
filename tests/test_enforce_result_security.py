import os
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.github/scripts"))
)
from repository_automation_common import enforce_result

def test_enforce_result_handles_special_files():
    # Test that enforce_result returns 1 if it is not a regular file
    # This prevents DoS via special files like /dev/zero
    with patch.object(Path, 'is_file', return_value=False):
        result = enforce_result("/dev/zero")
        assert result == 1
