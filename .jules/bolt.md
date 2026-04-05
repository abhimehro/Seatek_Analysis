## 2026-04-05 - Optimize string parsing for file extensions

**Learning:** Chaining `.endswith()` calls with `or` in Python (e.g. `file.endswith(".py") or file.endswith(".sh")`) requires multiple method lookups and boolean evaluations in Python space. Using a tuple like `file.endswith((".py", ".sh"))` is evaluated at the C level, making it faster and more memory-efficient. This is a common performance anti-pattern in scripts that do bulk file processing like `repository_automation_tasks.py`.
**Action:** Always prefer passing a tuple of extensions to `.endswith()` rather than chaining logical `or` statements when filtering files by extension.

## 2025-05-06 - Optimize file discovery with os.walk and early pruning

**Learning:** Using `pathlib.Path.rglob()` searches the entire tree before allowing filtering. If massive ignored directories (like `node_modules` or `.git`) exist, Python wastes significant CPU and I/O time traversing them.
**Action:** Use `os.walk(topdown=True)` and prune the `dirs` list in place (`dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]`) to prevent traversing ignored trees entirely. Also, `str.endswith(('.ext1', '.ext2'))` is faster than `fnmatch`.
