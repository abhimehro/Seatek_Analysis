🧹 [code health] Remove useless pass block in code_health_scanner.py

🎯 **What:** Removed the empty `if __name__ == "__main__": pass` block from the end of `code_health_scanner.py`.
💡 **Why:** This block was useless dead code that served no functional purpose. Removing it improves code maintainability and cleanliness.
✅ **Verification:** Ran the test suite (`pytest tests/test_code_health_scanner.py`) which completed successfully. No functionality was altered.
✨ **Result:** A slightly cleaner and more concise file without unnecessary boilerplate.
