# 🔒 Sentinel: [HIGH] Fix Path Traversal Vulnerability in Excel Sheet Parsing

## 🚨 Severity
HIGH

## 💡 Vulnerability
The `apply_corrections` function in `Series_27/Analysis/outlier_analysis_series27.py` contained a path traversal vulnerability. It used a weak denylist (replacing `/` and `\` with `_`) to sanitize user-provided Excel sheet names. An attacker could craft an Excel file with a malicious sheet name (e.g., `../../../etc/passwd` or hidden files like `.bashrc`) which, when passed to `os.path.join`, could cause the output corrected file to be written outside the intended `output_dir`.

## 🎯 Impact
If exploited, this could allow an attacker to overwrite arbitrary files on the system where the script is executed, leading to potential remote code execution or denial of service by overwriting critical system/application files.

## 🔧 Fix
1. Introduced a `secure_filename()` function that strictly allowlists alphanumeric characters, dashes, dots, and underscores (`[\w\.\- ]`).
2. The function explicitly strips leading dots and hyphens to prevent the creation of hidden files or option-injection attacks.
3. Implemented Defense-in-Depth in `apply_corrections`: verified that the newly constructed `out_file`'s absolute path originates from `output_dir` via `os.path.commonpath()`, logging and skipping if a path traversal attempt is detected.

## ✅ Verification
- Wrote tests in `test_outlier_analysis_series27.py` confirming `secure_filename()` correctly mitigates attacks.
- Tested `apply_corrections()` with mocked inputs simulating a malicious sheet name.
- Ran the existing test suite to ensure no regressions in current functionality. All tests pass.
