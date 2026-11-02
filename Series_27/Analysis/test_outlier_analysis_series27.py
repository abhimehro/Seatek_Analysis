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
    _process_single_sheet,
    apply_corrections,
    detect_outliers,
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

    with patch("pandas.ExcelFile") as mock_excel, patch(
        "pandas.read_excel"
    ) as mock_read:
        mock_xls = MagicMock()
        mock_xls.sheet_names = ["../../../outside/traversal_target"]
        mock_excel.return_value.__enter__.return_value = mock_xls

        mock_df_raw = MagicMock()
        mock_df_raw.empty = False
        mock_df_raw.columns = ["V1"]
        mock_df_raw.copy.return_value = mock_df_raw
        mock_read.return_value = {"../../../outside/traversal_target": mock_df_raw}

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
        assert os.path.realpath(out_file).startswith(
            os.path.realpath(output_dir)
        ), f"Output path {out_file} escapes {output_dir}"

        # The corrections summary should also reference the safe path
        assert not result.empty
        assert result.iloc[0]["CorrectedFile"] == out_file


@pytest.mark.skipif(not HAS_PANDAS, reason="Pandas not available")
def test_process_single_sheet_empty(tmp_path):
    df_empty = pd.DataFrame()
    group = pd.DataFrame(
        {
            "Year_Pair": ["2023-2024"],
            "Sensor": [1],
            "Difference": [0.5],
            "next_year": ["2024"],
        }
    )
    result = _process_single_sheet(
        df_empty, "EmptySheet", group, "input.xlsx", str(tmp_path)
    )
    assert result is None


@pytest.mark.skipif(not HAS_PANDAS, reason="Pandas not available")
def test_process_single_sheet_success(tmp_path):
    output_dir = str(tmp_path)
    input_path = "test_run.xlsx"
    sheet = "Raw Data 2024"

    df_raw = pd.DataFrame(
        {
            "V1": [10.0, 20.0],
            "V2": [5.0, 15.0],
            "Time": ["12:00:00", "12:01:00"],
        }
    )
    group = pd.DataFrame(
        {
            "Year_Pair": ["2023-2024", "2023-2024"],
            "Sensor": [1, 2],
            "Difference": [0.5, -0.2],
            "next_year": ["2024", "2024"],
        }
    )

    with patch.object(pd.DataFrame, "to_excel") as mock_to_excel:
        corrections = _process_single_sheet(
            df_raw, sheet, group, input_path, output_dir
        )

        # "Time" column should be deleted from df_raw
        assert "Time" not in df_raw.columns
        assert list(df_raw.columns) == ["V1", "V2"]

        # Differences subtracted: V1 -> -0.5, V2 -> -(-0.2) = +0.2
        assert df_raw["V1"].tolist() == [9.5, 19.5]
        assert df_raw["V2"].tolist() == [5.2, 15.2]

        # Corrections DataFrame validation
        assert corrections is not None
        assert len(corrections) == 2
        assert corrections["Year_Pair"].tolist() == ["2023-2024", "2023-2024"]
        assert corrections["Sensor"].tolist() == [1, 2]
        assert corrections["OrigDiff"].tolist() == [0.5, -0.2]
        assert corrections["OffsetApplied"].tolist() == [-0.5, 0.2]

        expected_outfile = os.path.join(
            output_dir, "test_run_2024_Raw Data 2024_corrected.xlsx"
        )
        assert corrections["CorrectedFile"].tolist() == [
            expected_outfile,
            expected_outfile,
        ]

        # Verify to_excel was called with expected arguments
        mock_to_excel.assert_called_once_with(
            expected_outfile, sheet_name=sheet, index=False
        )


@pytest.mark.skipif(not HAS_PANDAS, reason="Pandas not available")
def test_process_single_sheet_unsafe_path(tmp_path):
    output_dir = str(tmp_path)
    input_path = "test_run.xlsx"
    sheet = "Sheet1"

    df_raw = pd.DataFrame({"V1": [10.0]})
    group = pd.DataFrame(
        {
            "Year_Pair": ["2023-2024"],
            "Sensor": [1],
            "Difference": [0.5],
            "next_year": ["2024"],
        }
    )

    # Patch _get_safe_output_path to simulate an unsafe path detection
    with patch(
        "outlier_analysis_series27._get_safe_output_path", return_value=None
    ) as mock_safe_path:
        result = _process_single_sheet(df_raw, sheet, group, input_path, output_dir)
        assert result is None
        mock_safe_path.assert_called_once()


def test_process_single_sheet_mock():
    # Verify logic branches using mocks when pandas is mocked
    mock_df_empty = MagicMock()
    mock_df_empty.empty = True
    # output_dir is a placeholder, not a temp path: the empty-frame branch
    # returns before _get_safe_output_path ever sees it. A real /tmp here would
    # trip bandit B108 for a directory that is never touched.
    assert (
        _process_single_sheet(
            mock_df_empty, "Sheet1", MagicMock(), "in.xlsx", "/never-written"
        )
        is None
    )
