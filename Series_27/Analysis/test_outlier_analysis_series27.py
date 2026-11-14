import os
import sys
from unittest.mock import MagicMock, patch

# Add the current directory to sys.path so we can import outlier_analysis_series27
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Mock dependencies that might be missing in the environment
try:
    import numpy as np
    import pandas as pd

    HAS_PANDAS = True
except ImportError:
    HAS_PANDAS = False
    # Mock pandas
    pd = MagicMock()
    pd.DataFrame = MagicMock
    pd.Series = MagicMock
    sys.modules["pandas"] = pd

    # Mock numpy
    np = MagicMock()
    sys.modules["numpy"] = np

    # Mock matplotlib
    sys.modules["matplotlib"] = MagicMock()
    sys.modules["matplotlib.pyplot"] = MagicMock()

import pytest
from outlier_analysis_series27 import (
    _is_safe_path,
    apply_corrections,
    detect_outliers,
    parse_args,
    secure_filename,
)


@pytest.mark.skipif(
    not HAS_PANDAS, reason="Pandas not available, using mocks for logic check"
)
def test_detect_outliers_abs_real():
    df = pd.DataFrame({"Difference": [0.05, 0.15, -0.02, -0.2, 0.1]})
    # Method 'abs': Outliers are where abs(Difference) >= abs_thr
    result = detect_outliers(df, "abs", abs_thr=0.1, z_thr=3.0, iqr_fac=1.5)
    assert len(result) == 3
    assert all(result["Difference"].abs() >= 0.1)


@pytest.mark.skipif(
    not HAS_PANDAS, reason="Pandas not available, using mocks for logic check"
)
def test_detect_outliers_zscore_real():
    # Create a distribution where one value is far out
    data = [10, 10.1, 10.2, 10, 9.9, 10, 10, 10, 20]  # 20 is the outlier
    df = pd.DataFrame({"Difference": data})
    # Mean is ~11.1, Std is ~3.3. (20 - 11.1) / 3.3 = 2.69
    # If we set z_thr = 2.0, 20 should be an outlier.
    result = detect_outliers(df, "zscore", abs_thr=0.1, z_thr=2.0, iqr_fac=1.5)
    assert len(result) == 1
    assert result.iloc[0]["Difference"] == 20


@pytest.mark.skipif(
    not HAS_PANDAS, reason="Pandas not available, using mocks for logic check"
)
def test_detect_outliers_iqr_real():
    # IQR method
    data = [10, 10.1, 10.2, 10, 9.9, 10, 10, 10, 20]
    df = pd.DataFrame({"Difference": data})
    # Q1=10, Q3=10.1, IQR=0.1. Upper = 10.1 + 1.5*0.1 = 10.25. 20 is > 10.25
    result = detect_outliers(df, "iqr", abs_thr=0.1, z_thr=3.0, iqr_fac=1.5)
    assert len(result) == 1
    assert result.iloc[0]["Difference"] == 20


def test_detect_outliers_invalid_method():
    df = MagicMock()
    if HAS_PANDAS:
        df = pd.DataFrame({"Difference": [1, 2]})

    with pytest.raises(ValueError, match="Unknown method: invalid"):
        detect_outliers(df, "invalid", 0.1, 3.0, 1.5)


# Mocked tests for when pandas is missing or for pure logic verification
def test_detect_outliers_abs_mock():
    mock_df = MagicMock()
    mock_col = MagicMock()
    mock_df.__getitem__.return_value = mock_col

    # In the code: return df[col.abs() >= abs_thr]
    mock_abs = MagicMock()
    mock_col.abs.return_value = mock_abs

    # mock_abs >= 0.1
    mock_mask = MagicMock()
    mock_abs.__ge__.return_value = mock_mask

    detect_outliers(mock_df, "abs", abs_thr=0.1, z_thr=3.0, iqr_fac=1.5)

    mock_col.abs.assert_called_once()
    mock_abs.__ge__.assert_called_once_with(0.1)
    mock_df.__getitem__.assert_any_call("Difference")
    mock_df.__getitem__.assert_any_call(mock_mask)


def test_detect_outliers_zscore_mock():
    mock_df = MagicMock()
    mock_col = MagicMock()
    mock_df.__getitem__.return_value = mock_col

    # In code: return df[(col - col.mean()).abs() >= z_thr * col.std()]
    mock_mean = MagicMock()
    mock_col.mean.return_value = mock_mean
    mock_diff = MagicMock()
    mock_col.__sub__.return_value = mock_diff
    mock_abs = MagicMock()
    mock_diff.abs.return_value = mock_abs
    mock_std = MagicMock()
    mock_col.std.return_value = mock_std

    mock_mask = MagicMock()
    mock_abs.__ge__.return_value = mock_mask

    detect_outliers(mock_df, "zscore", abs_thr=0.1, z_thr=3.0, iqr_fac=1.5)

    mock_col.mean.assert_called_once()
    mock_col.std.assert_called_once()
    mock_col.__sub__.assert_called_with(mock_mean)
    mock_diff.abs.assert_called_once()


def test_detect_outliers_iqr_mock():
    mock_df = MagicMock()
    mock_col = MagicMock()
    mock_df.__getitem__.return_value = mock_col

    # In code:
    # q1, q3 = col.quantile([0.25, 0.75])
    # iqr = q3 - q1
    # lower, upper = q1 - iqr_fac * iqr, q3 + iqr_fac * iqr
    # return df[(col < lower) | (col > upper)]

    mock_col.quantile.return_value = [10, 20]  # q1, q3

    mock_lower_mask = MagicMock()
    mock_upper_mask = MagicMock()
    mock_col.__lt__.return_value = mock_lower_mask
    mock_col.__gt__.return_value = mock_upper_mask

    mock_or_mask = MagicMock()
    mock_lower_mask.__or__.return_value = mock_or_mask

    detect_outliers(mock_df, "iqr", abs_thr=0.1, z_thr=3.0, iqr_fac=1.5)

    mock_col.quantile.assert_called_once_with([0.25, 0.75])
    mock_col.__lt__.assert_called()
    mock_col.__gt__.assert_called()
    mock_lower_mask.__or__.assert_called_with(mock_upper_mask)
    mock_df.__getitem__.assert_any_call(mock_or_mask)


def test_secure_filename():
    assert (
        secure_filename("../../../outside/traversal_target")
        == "outside_traversal_target"
    )
    assert secure_filename("C:\\Windows\\System32") == "C__Windows_System32"
    assert secure_filename("..") == "unnamed"
    assert secure_filename(".hidden") == "hidden"
    assert secure_filename("valid-name_1.2.3") == "valid-name_1.2.3"
    assert secure_filename("Raw Data 2024") == "Raw Data 2024"
    assert secure_filename("") == "unnamed"


@pytest.mark.skipif(not HAS_PANDAS, reason="Pandas not available")
def test_apply_corrections_path_traversal(tmp_path):
    # Create dummy outliers df with malicious sheet name
    outliers_df = pd.DataFrame(
        {
            "Year_Pair": ["2023-2024"],
            "Sensor": [1],
            "Difference": [0.5],
            "next_year": ["2024"],
            "sheet": ["../../../outside/traversal_target"],
        }
    )

    output_dir = str(tmp_path)

    with patch("pandas.ExcelFile") as mock_excel:
        mock_xls = MagicMock()
        mock_excel.return_value.__enter__.return_value = mock_xls

        mock_df_raw = MagicMock()
        mock_df_raw.empty = False
        mock_df_raw.columns = ["V1"]
        mock_xls.parse.return_value = mock_df_raw

        # Exercise the real os.path.join / _is_safe_path defense-in-depth check
        result = apply_corrections(b"dummy", "dummy.xlsx", output_dir, outliers_df)

        # The MagicMock-based df_raw still records the to_excel call
        assert mock_df_raw.to_excel.called, "to_excel should be invoked"
        out_file = mock_df_raw.to_excel.call_args[0][0]
        filename = os.path.basename(out_file)
        assert "/" not in filename, f"Path traversal character / found in {filename}"
        assert "\\" not in filename, f"Path traversal character \\ found in {filename}"
        assert "outside_traversal_target" in filename

        # Defense-in-depth: resolved path must remain within output_dir
        assert os.path.realpath(out_file).startswith(os.path.realpath(output_dir)), (
            f"Output path {out_file} escapes {output_dir}"
        )

        # The corrections summary should also reference the safe path
        assert not result.empty
        assert result.iloc[0]["CorrectedFile"] == out_file


def test_parse_args_defaults():
    # Test parse_args with required -i argument and verify default options
    test_args = ["outlier_analysis_series27.py", "-i", "data.xlsx"]
    with patch.object(sys, "argv", test_args):
        args = parse_args()
        assert args.input == "data.xlsx"
        assert args.sheet_summary == "Year-to-Year Differences"
        assert args.method == "abs"
        assert args.threshold == 0.1
        assert args.zscore == 3.0
        assert args.iqr_factor == 1.5
        assert args.output == "output"


def test_parse_args_custom_values():
    # Test parse_args with all custom arguments supplied
    test_args = [
        "outlier_analysis_series27.py",
        "-i",
        "custom_data.xlsx",
        "-s",
        "Custom Differences",
        "-m",
        "zscore",
        "-t",
        "0.25",
        "-z",
        "2.5",
        "-q",
        "2.0",
        "-o",
        "custom_output",
    ]
    with patch.object(sys, "argv", test_args):
        args = parse_args()
        assert args.input == "custom_data.xlsx"
        assert args.sheet_summary == "Custom Differences"
        assert args.method == "zscore"
        assert args.threshold == 0.25
        assert args.zscore == 2.5
        assert args.iqr_factor == 2.0
        assert args.output == "custom_output"


def test_parse_args_no_args_exits(capsys):
    # Test parse_args exits with status 1 when len(sys.argv) == 1
    test_args = ["outlier_analysis_series27.py"]
    with patch.object(sys, "argv", test_args):
        with pytest.raises(SystemExit) as exc_info:
            parse_args()
        assert exc_info.value.code == 1
    captured = capsys.readouterr()
    assert "usage:" in captured.err.lower() or "examples:" in captured.err.lower()


def test_parse_args_missing_required_input():
    # Test parse_args exits when required argument -i is missing but other arguments are present
    test_args = ["outlier_analysis_series27.py", "-m", "iqr"]
    with patch.object(sys, "argv", test_args):
        with pytest.raises(SystemExit) as exc_info:
            parse_args()
        assert exc_info.value.code == 2


def test_safe_path_valid_contained(tmp_path):
    """Test path containment for valid subpaths and exact base path."""
    base_dir = tmp_path / "basedir"
    base_dir.mkdir()
    child_file = base_dir / "report.xlsx"
    child_file.touch()
    nested_dir = base_dir / "sub" / "folder"
    nested_dir.mkdir(parents=True)
    nested_file = nested_dir / "data.csv"
    nested_file.touch()

    # Exact base path is considered contained
    assert _is_safe_path(str(base_dir), str(base_dir))
    # Directly contained file
    assert _is_safe_path(str(base_dir), str(child_file))
    # Deeply nested file
    assert _is_safe_path(str(base_dir), str(nested_file))
    # Relative path within base directory
    rel_path = os.path.join(str(base_dir), ".", "report.xlsx")
    assert _is_safe_path(str(base_dir), rel_path)


def test_safe_path_traversal(tmp_path):
    """Test that path traversal using parent directory dots is blocked."""
    base_dir = tmp_path / "basedir"
    base_dir.mkdir()

    # Direct parent traversal escape
    escape_path = str(base_dir / ".." / "escaped.txt")
    assert not _is_safe_path(str(base_dir), escape_path)

    # Multi-level parent traversal escape
    deep_escape = str(base_dir / "sub" / ".." / ".." / "etc" / "passwd")
    assert not _is_safe_path(str(base_dir), deep_escape)

    # Completely external path
    outside_dir = tmp_path / "other"
    outside_dir.mkdir()
    assert not _is_safe_path(str(base_dir), str(outside_dir))


def test_safe_path_sibling_prefix(tmp_path):
    """Test that sibling directories sharing prefix name are rejected."""
    # basedir: /tmp/.../base
    # sibling: /tmp/.../base_evil (starts with prefix but not inside)
    base_dir = tmp_path / "data"
    base_dir.mkdir()
    sibling_dir = tmp_path / "data_extra"
    sibling_dir.mkdir()
    sibling_file = sibling_dir / "leak.txt"
    sibling_file.touch()

    assert not _is_safe_path(str(base_dir), str(sibling_file))
    assert not _is_safe_path(str(base_dir), str(sibling_dir))


def test_safe_path_null_byte(tmp_path):
    """Test that null byte injection in either argument is rejected."""
    base_dir = tmp_path / "basedir"
    base_dir.mkdir()

    # Null byte in target path
    assert not _is_safe_path(str(base_dir), f"{base_dir}/file.xlsx\0.evil")
    assert not _is_safe_path(str(base_dir), "\0/etc/passwd")

    # Null byte in base directory
    valid_file = str(base_dir / "test.txt")
    assert not _is_safe_path(f"{base_dir}\0", valid_file)


def test_safe_path_symlink(tmp_path):
    """Test symlinks resolving outside versus inside basedir."""
    base_dir = tmp_path / "basedir"
    base_dir.mkdir()
    outside_dir = tmp_path / "outside"
    outside_dir.mkdir()
    secret_file = outside_dir / "secret.txt"
    secret_file.touch()

    # Symlink inside basedir pointing to outside target should be rejected
    symlink_escape = base_dir / "symlink_to_secret"
    try:
        os.symlink(str(secret_file), str(symlink_escape))
    except (OSError, NotImplementedError):
        pytest.skip("Symlink creation not supported in this environment")

    assert not _is_safe_path(str(base_dir), str(symlink_escape))

    # Symlink inside basedir pointing to inside target should be accepted
    internal_file = base_dir / "internal.txt"
    internal_file.touch()
    internal_symlink = base_dir / "symlink_to_internal"
    os.symlink(str(internal_file), str(internal_symlink))

    assert _is_safe_path(str(base_dir), str(internal_symlink))


def test_parse_args_invalid_method():
    # Test parse_args exits when invalid choice for -m is provided
    test_args = [
        "outlier_analysis_series27.py",
        "-i",
        "data.xlsx",
        "-m",
        "invalid_method",
    ]
    with patch.object(sys, "argv", test_args):
        with pytest.raises(SystemExit) as exc_info:
            parse_args()
        assert exc_info.value.code == 2
