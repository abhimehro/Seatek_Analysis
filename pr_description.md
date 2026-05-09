💡 What
Replaced a dictionary lookup with `.endswith()` string matching in the `get_language` function of `code_health_scanner.py`.

🎯 Why
Using `.endswith()` is evaluated at the C level in Python, eliminating the need to parse the path with `os.path.splitext()`, convert it to lowercase, and perform a dictionary hash lookup. This reduces string allocation overhead when scanning many files.

📊 Measured Improvement
Execution time for `get_language` is reduced by approximately 57% compared to the original `splitext` approach.

🔬 Measurement
Ran a test script processing an array of 60,000 filenames.
- `splitext` approach: 0.0872s
- `endswith` approach: 0.0372s
