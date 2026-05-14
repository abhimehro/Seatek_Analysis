import sys
import os
from unittest.mock import MagicMock, patch

# Add the current directory to sys.path so we can import outlier_analysis_series27
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Mock dependencies that might be missing in the environment
try:
    import pandas as pd
    import numpy as np

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

from outlier_analysis_series27 import detect_outliers
import pytest


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


from outlier_analysis_series27 import secure_filename, apply_corrections


def test_secure_filename():
    assert secure_filename("../../../etc/passwd") == "etc_passwd"
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
            "sheet": ["../../../etc/passwd"],
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
        result = apply_corrections("dummy.xlsx", output_dir, outliers_df)

        # The MagicMock-based df_raw still records the to_excel call
        assert mock_df_raw.to_excel.called, "to_excel should be invoked"
        out_file = mock_df_raw.to_excel.call_args[0][0]
        filename = os.path.basename(out_file)
        assert (
            "/" not in filename
        ), f"Path traversal character / found in {filename}"
        assert (
            "\\" not in filename
        ), f"Path traversal character \\ found in {filename}"
        assert "etc_passwd" in filename

        # Defense-in-depth: resolved path must remain within output_dir
        assert os.path.realpath(out_file).startswith(
            os.path.realpath(output_dir)
        ), f"Output path {out_file} escapes {output_dir}"

        # The corrections summary should also reference the safe path
        assert not result.empty
        assert result.iloc[0]["CorrectedFile"] == out_file
