#!/usr/bin/env python3
import pandas as pd
import numpy as np
import argparse
import re
import os
import matplotlib.pyplot as plt
import logging


def parse_args():
    parser = argparse.ArgumentParser(
        description="Series 27 Outlier Analysis and Correction"
    )
    parser.add_argument(
        '-i', '--input', required=True,
        help="Path to Seatek Comprehensive Analysis workbook"
    )
    parser.add_argument(
        '-s', '--sheet_summary', default='Year-to-Year Differences',
        help="Summary sheet name containing year-to-year diffs"
    )
    parser.add_argument(
        '-m', '--method', choices=['abs','zscore','iqr'], default='abs',
        help="Outlier detection method: abs (|Δ|>=thr), zscore, or iqr"
    )
    parser.add_argument(
        '-t', '--threshold', type=float, default=0.1,
        help="Threshold for absolute method (cm)"
    )
    parser.add_argument(
        '-z', '--zscore', type=float, default=3.0,
        help="Z-score threshold for zscore method"
    )
    parser.add_argument(
        '-q', '--iqr_factor', type=float, default=1.5,
        help="IQR factor for iqr method"
    )
    parser.add_argument(
        '-o', '--output', default='output',
        help="Directory to save corrected files and summaries"
    )
    return parser.parse_args()


def detect_outliers(df, method, abs_thr, z_thr, iqr_fac):
    """Detects outliers in a DataFrame based on a specified method.

    Args:
        df (pd.DataFrame): DataFrame containing a 'Difference' column to check for outliers.
        method (str): The outlier detection method. Choices: 'abs', 'zscore', 'iqr'.
        abs_thr (float): Absolute threshold for the 'abs' method.
                         Outliers are where abs(Difference) >= abs_thr.
        z_thr (float): Z-score threshold for the 'zscore' method.
                       Outliers are where abs(Z-score of Difference) >= z_thr.
        iqr_fac (float): IQR factor for the 'iqr' method.
                         Outliers are < Q1 - iqr_fac * IQR or > Q3 + iqr_fac * IQR.

    Returns:
        pd.DataFrame: A DataFrame containing only the rows identified as outliers.
    
    Raises:
        ValueError: If an unknown method is specified.
    """
    col = df['Difference']
    if method == 'abs':
        return df[col.abs() >= abs_thr]
    if method == 'zscore':
        return df[(col - col.mean()).abs() >= z_thr * col.std()]
    if method == 'iqr':
        q1, q3 = col.quantile([0.25,0.75])
        iqr = q3 - q1
        lower, upper = q1 - iqr_fac * iqr, q3 + iqr_fac * iqr
        return df[(col < lower) | (col > upper)]
    raise ValueError(f"Unknown method: {method}")


def main():
    args = parse_args()
    os.makedirs(args.output, exist_ok=True)
    logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

    logging.info("Loading year-to-year differences")
    diff_df = pd.read_excel(args.input, sheet_name=args.sheet_summary)
    long_df = diff_df.melt(
        id_vars='Year_Pair', var_name='Sensor', value_name='Difference'
    )
    outliers = detect_outliers(
        long_df, args.method, args.threshold, args.zscore, args.iqr_factor
    ).reset_index(drop=True)
    logging.info(f"Detected {len(outliers)} outliers using '{args.method}' method")

    # ⚡ Bolt: Group outliers by target sheet to batch Excel I/O and prevent overriding corrections
    # We extract target year and group by sheet name to read/write each file exactly once.
    outliers_to_process = []
    for _, row in outliers.iterrows():
        pair = row['Year_Pair']
        sensor = int(row['Sensor'].split()[-1])
        diff = row['Difference']
        years = re.findall(r'(\d{4})', pair)
        if len(years) != 2:
            continue
        next_year = int(years[0])
        sheet = f"Raw Data {next_year}"
        outliers_to_process.append({
            'Year_Pair': pair,
            'Sensor': sensor,
            'Difference': diff,
            'next_year': next_year,
            'sheet': sheet
        })

    outliers_df = pd.DataFrame(outliers_to_process)
    corrections = []

    if not outliers_df.empty:
        # Group by sheet to minimize expensive I/O operations
        grouped = outliers_df.groupby('sheet')
        for sheet, group in grouped:
            try:
                # Read once per sheet
                df_raw = pd.read_excel(args.input, sheet_name=sheet)
            except Exception as e:
                logging.warning(f"Could not read sheet '{sheet}': {e}")
                continue

            if df_raw.empty:
                logging.info(f"Sheet '{sheet}' is empty, skipping.")
                continue

            # Drop the last column if its name contains 'time' (case-insensitive)
            last_col = df_raw.columns[-1]
            if 'time' in last_col.lower():
                df_raw = df_raw.iloc[:, :-1].copy()

            next_year = group.iloc[0]['next_year']
            out_file = os.path.join(
                args.output,
                f"{os.path.splitext(os.path.basename(args.input))[0]}_{next_year}_corrected.xlsx"
            )

            # Apply all corrections for this sheet in memory
            # First, aggregate total offset per sensor to avoid repeated full-column writes
            sensor_diffs = group.groupby('Sensor')['Difference'].sum()
            for sensor, total_diff in sensor_diffs.items():
                col = f"V{sensor}"
                # Original per-row offset is -Difference, so total offset is -sum(Difference)
                df_raw[col] = df_raw[col] - total_diff

            # Record per-row corrections (for reporting) without re-modifying df_raw
            for _, row in group.iterrows():
                offset = -row['Difference']
                corrections.append({
                    'Year_Pair': row['Year_Pair'],
                    'Sensor': row['Sensor'],
                    'OrigDiff': row['Difference'],
                    'OffsetApplied': offset,
                    'CorrectedFile': out_file
                })

            # Write once per sheet
            df_raw.to_excel(out_file, sheet_name=sheet, index=False)

    corr_df = pd.DataFrame(corrections)
    corr_file = os.path.join(args.output, 'corrections_summary.xlsx')
    corr_df.to_excel(corr_file, index=False)
    logging.info(f"Saved corrections summary to '{corr_file}'")

    # Plotting
    plt.figure(figsize=(12,6))
    plt.scatter(range(len(outliers)), outliers['Difference'], s=50)
    plt.axhline(0, color='gray')
    if args.method == 'abs':
        plt.axhline(args.threshold, linestyle='--', color='red')
        plt.axhline(-args.threshold, linestyle='--', color='red')
    plt.xticks(
        range(len(outliers)),
        [f"{r['Year_Pair']}/S{int(r['Sensor'].split()[-1])}" for _,r in outliers.iterrows()],
        rotation=90
    )
    plt.ylabel('Difference (cm)')
    plt.title('Outlier Differences')
    plt.tight_layout()
    plot_file = os.path.join(args.output, 'outliers_plot.png')
    plt.savefig(plot_file)
    logging.info(f"Saved plot to '{plot_file}'")

    # Display table
    print(corr_df.to_string(index=False))


if __name__ == '__main__':
    main()
