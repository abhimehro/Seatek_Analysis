🎯 **What:** Removed unused `import pytest` from `tests/test_code_health_scanner.py`.
💡 **Why:** The `pytest` module was imported but not referenced anywhere in the file. Removing unused imports reduces clutter, improves namespace cleanliness, and slightly decreases module loading overhead, enhancing overall code maintainability and readability.
✅ **Verification:** Ran the full test suite (`PYTHONPATH=. pytest tests/`) to confirm that all tests continue to pass without the import.
✨ **Result:** The code is cleaner without any change to the existing test functionality or behavior.
