🧪 Testing Improvement: calculate_summary_stats coverage

🎯 What: The testing gap addressed
The `calculate_summary_stats` function in `Updated_Seatek_Analysis.R` lacked unit tests, making it vulnerable to undetected regressions when changing how statistics (mean, SD, count, rollmean3, etc.) are computed.

📊 Coverage: What scenarios are now tested
A new test suite (`tests/testthat/test-calculate_summary_stats.R`) has been added. It covers:
- **Happy Path**: Proper calculation of metrics (count, mean, sd, median, mad, min, max, rollmean3) using mocked multi-year sensor data.
- **NA Handling**: Correct omission of `NA` values and proper counts/metrics calculation when data points are missing.
- **Empty / NA Edge Case**: Handling data sets where sensor data is entirely missing (`NA`), confirming metrics fall back to `NA_real_` and count is `0`.

✨ Result: The improvement in test coverage
The `calculate_summary_stats` function is now fully covered, adding robust guardrails around statistical aggregations.
