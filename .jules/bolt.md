## 2025-05-06 - Optimize file discovery with os.walk and early pruning

**Learning:** Using `pathlib.Path.rglob()` searches the entire tree before allowing filtering. If massive ignored directories (like `node_modules` or `.git`) exist, Python wastes significant CPU and I/O time traversing them.
**Action:** Use `os.walk(topdown=True)` and prune the `dirs` list in place (`dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]`) to prevent traversing ignored trees entirely. Also, `str.endswith(('.ext1', '.ext2'))` is faster than `fnmatch`.
## 2025-05-06 - Optimize os.path.relpath with pathlib.Path\n**Learning:** Using `pathlib.Path(dir, file)` is significantly faster and more readable than redundant combinations of `os.path.join()`, `os.path.relpath()`, and division operators when constructing relative paths from `os.walk()`.\n**Action:** Use `pathlib.Path()` direct construction instead of manual standard library path manipulation.
## 2025-05-06 - Optimize string parsing in loops with fast-fail checks
**Learning:** Calling object-allocating methods like `.strip()` on every line in a tight loop creates unnecessary overhead when the vast majority of lines won't match the final condition.
**Action:** Use a fast-fail substring check (e.g., `if "TODO" in line:`) before doing more expensive string manipulation to quickly bypass irrelevant strings and save CPU/memory resources.
