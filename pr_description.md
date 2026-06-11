🎯 **What:**
Added unit tests for the main `run_pipeline` function. Previously, this function lacked direct test coverage, leading to a gap in ensuring the top-level execution and error handling flow functions as expected.

📊 **Coverage:**
The new test file (`tests/testthat/test-run_pipeline.R`) covers the following scenarios:
1. `run_pipeline handles missing data directory correctly`: Verifies that the pipeline correctly halts and logs an error when the `Data` directory is missing.
2. `run_pipeline captures warnings and dependency errors`: Mocks `process_all_data` to generate warnings and dependency errors to confirm they are captured by `withCallingHandlers` and logged correctly via `log_handler`.
3. `run_pipeline executes successfully with valid data`: Mocks downstream functions and ensures the pipeline runs successfully to completion without errors when the environment is properly configured.

✨ **Result:**
Enhanced the robustness of the testing suite by explicitly testing the primary execution path and its logging integration. Test coverage is increased and ensures future refactors do not break top-level execution flows.
