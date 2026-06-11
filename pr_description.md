🧪 Added tests for compute_sensor_metrics

🎯 **What:** The `compute_sensor_metrics` function lacked test coverage.
📊 **Coverage:** A new test file `tests/testthat/test-compute_sensor_metrics.R` was added covering standard calculations (>10 rows), small dataset calculations (<10 rows), and boundary/invalid mapping for year names embedded in the filenames. `suppressWarnings` is used to gracefully test handling of NAs mapped by coercion during parsing boundary values.
✨ **Result:** Test coverage significantly improved, preventing regressions on core metrics logic calculation functions.
