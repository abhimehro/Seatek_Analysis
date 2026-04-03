## 2025-05-06 - Optimize file discovery with os.walk and early pruning

**Learning:** Using `pathlib.Path.rglob()` searches the entire tree before allowing filtering. If massive ignored directories (like `node_modules` or `.git`) exist, Python wastes significant CPU and I/O time traversing them.
**Action:** Use `os.walk(topdown=True)` and prune the `dirs` list in place (`dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]`) to prevent traversing ignored trees entirely. Also, `str.endswith(('.ext1', '.ext2'))` is faster than `fnmatch`.
