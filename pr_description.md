## 🎯 What

The `execute_tasks_parallel` function lacked test coverage. This pull request adds comprehensive unit tests using `mockery` to ensure the function behaves as expected across both its serial fallback and parallel execution paths, including proper error handling when core detection fails.

## 📊 Coverage

The following scenarios are now tested:
- **Empty input handling:** Returns an empty list immediately when given an empty list.
- **Serial fallback:** Verifies the function falls back to serial execution when the `parallel` package is unavailable.
- **Parallel logic (Unix & Windows):** Mocks package loading, platform detection, and the respective parallel execution engines (`mclapply` for Unix, `parLapply` for Windows) to ensure successful evaluation.
- **Core detection failure:** Asserts the function gracefully recovers when `detectCores()` fails by defaulting back to 1 core.

## ✨ Result

The `execute_tasks_parallel` function is now fully covered by unit tests, increasing the test suite's overall reliability and giving us more confidence when making any future refactoring or improvements to this utility function.

═════ ELIR ═════
PURPOSE: Add unit tests for the `execute_tasks_parallel` function to verify both serial and parallel execution paths.
SECURITY: Testing improves reliability of the parallelization engine; no new security risks introduced.
FAILS IF: The underlying implementation relies on differing system behaviors that tests don't correctly mock.
VERIFY: Tests pass in both local and CI environments without the actual parallel package disrupting other tests.
MAINTAIN: When adding new OS-specific branches, update the corresponding platform-specific mocks in these tests.
