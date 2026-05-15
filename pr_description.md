💡 What
Modified `get_language` in `code_health_scanner.py` to avoid lowercasing the entire filepath. Instead, only the small extension suffix returned by `os.path.splitext()` is lowercased, and the result is looked up in a module-level dictionary. This preserves full case-insensitive matching (including mixed-case extensions like `.Py` or `.jS`) while removing the allocation overhead of lowercasing the whole path.

🎯 Why
Calling `filepath.lower()` on the full path inside the high-volume scanning loop allocates a new string proportional to the path length on every invocation. Lowercasing only the short extension suffix (typically 2–4 characters) avoids that overhead without sacrificing correctness.

📊 Measured Improvement
The extension suffix returned by `os.path.splitext()` is short, so `.lower()` on it is effectively free compared to lowercasing the whole path. A module-level `dict` lookup replaces the previous if/elif chain with O(1) dispatch.

🔬 Measurement
Run the existing test suite via `PYTHONPATH=. pytest tests/` to confirm functionality. The test suite now also covers mixed-case extensions (`.Py`, `.pY`, `.Js`, `.jS`, `.Ts`, `.tS`) to lock in the case-insensitive contract.

═════ ELIR ═════
PURPOSE: Reduce per-call string allocation in `get_language` while preserving full case-insensitive extension matching.
SECURITY: N/A - internal string comparison update.
FAILS IF: A supported extension is added to `_LANG_BY_EXT` without a lowercase key (lookup is on the lowercased suffix).
VERIFY: Ensure standard extensions (.py, .r, .js, .ts) and mixed-case variants (.Py, .jS, etc.) correctly map to languages.
MAINTAIN: Keys in `_LANG_BY_EXT` must always be lowercase, since the suffix is lowercased before lookup.
