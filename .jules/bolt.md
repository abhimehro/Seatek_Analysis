## 2025-05-06 - Optimize file discovery with os.walk and early pruning

**Learning:** Using `pathlib.Path.rglob()` searches the entire tree before allowing filtering. If massive ignored directories (like `node_modules` or `.git`) exist, Python wastes significant CPU and I/O time traversing them.
**Action:** Use `os.walk(topdown=True)` and prune the `dirs` list in place (`dirs[:] = [d for d in dirs if d not in IGNORED_DIRS]`) to prevent traversing ignored trees entirely. Also, `str.endswith(('.ext1', '.ext2'))` is faster than `fnmatch`.
## 2025-05-06 - Optimize os.path.relpath with pathlib.Path\n**Learning:** Using `pathlib.Path(dir, file)` is significantly faster and more readable than redundant combinations of `os.path.join()`, `os.path.relpath()`, and division operators when constructing relative paths from `os.walk()`.\n**Action:** Use `pathlib.Path()` direct construction instead of manual standard library path manipulation.
## 2025-05-06 - Optimize string processing in parsing loops
**Learning:** Calling object-allocating methods like `.strip()`, `.lstrip()`, or `.lower()` on every line in a large file scanning loop introduces significant memory and CPU overhead.
**Action:** Use a fast-fail substring check (`if "pattern" in line:`) before executing the more expensive operations. This short-circuits the condition for lines that don't match, often yielding ~10x faster execution for non-matching lines. Remember to combine conditions with `and` on the same line to avoid increasing nested code complexity.
## 2025-05-06 - Remove unused dependencies to reduce memory overhead and load times in R scripts
**Learning:** Checking for unused heavy dependencies like `dplyr` and `tidyr` is important for reducing memory overhead and load times in R scripts optimized with `data.table` and `openxlsx`.
**Action:** In memory-constrained or performance-critical environments, review required packages and remove those that are not explicitly utilized, avoiding unnecessary dependency installation and import overhead.
## 2025-05-06 - Optimize dictionary definition in frequently called functions
**Learning:** Defining static dictionaries inside functions incurs unnecessary reallocation and setup overhead on every invocation.
**Action:** Always extract static dictionaries or complex literal structures out of the function scope and assign them to module-level constants.
## 2025-05-06 - Hoist function definitions and objects out of loops
**Learning:** Defining helper functions (`clean_vals <- function(x) ...`) or instantiating objects (like `createStyle()` in `openxlsx`) inside a loop or inside a function that is called repeatedly in a loop introduces unnecessary parsing, evaluation, and allocation overhead on every iteration.
**Action:** Always hoist static function definitions to the module/top-level scope, and move redundant object instantiations out of loops, passing them as arguments to inner functions if needed, to reduce CPU and memory overhead.
## 2026-05-09 - Optimize file extension check with endswith()
**Learning:** Checking file extensions with `.endswith()` directly in a fast if-elif block is faster than using string manipulation `os.path.splitext()` and a dictionary lookup.
**Action:** Use `.endswith()` to verify file types, which executes in C-level and avoids extra object allocations.
## 2026-05-09 - Optimize file extension check with endswith()
**Learning:** Checking file extensions with `.endswith()` directly in a fast if-elif block is faster than using string manipulation `.lower()` on the entire file path, especially avoiding unnecessary string allocations in high-volume scanning.
**Action:** Pass a tuple of case permutations directly to `.endswith()` (e.g., `filepath.endswith(('.py', '.pY', '.Py', '.PY'))`) to efficiently check file extensions without allocating new lowercase strings.
## 2025-05-20 - Optimize independent API calls with concurrent execution
**Learning:** Making multiple independent sequential API or subprocess calls (like `gh_json` requests) introduces blocking I/O bottlenecks.
**Action:** Use `concurrent.futures.ThreadPoolExecutor` to run independent network or subprocess requests concurrently. Always extract the logic into a separate helper function to avoid triggering "Large Method" static analysis violations.
## 2025-05-21 - Avoid unmaintainable `.endswith()` case permutation chains
**Learning:** Using `filepath.endswith(('.py', '.pY', '.Py', '.PY'))` to avoid `.lower()` string allocation overhead creates a combinatorial explosion of case permutations (e.g., a 4-letter extension needs 16 permutations). This is an unreadable anti-pattern that sacrifices maintainability for an imperceptible micro-optimization.
**Action:** Do not use `.endswith()` with case permutations for case-insensitive file extension checks. Instead, revert to the idiomatic `os.path.splitext(filepath)[1].lower()` pattern, as the marginal string allocation overhead is not a legitimate bottleneck compared to the loss of code readability.
## 2025-05-24 - Improve test robustness with warning suppression
**Learning:** Functions like `calculate_summary_stats` that rely on `data.table::melt` may generate expected coercion warnings during test execution.
**Action:** Use `suppressWarnings` in test cases when valid data type coercions intentionally occur, such as `data.table::melt` coercion warnings, to maintain clean and reliable test execution logs.
## 2025-05-24 - Optimize path traversal checks with string operations
**Learning:** Using `os.path.commonpath([base_path, resolved_path]) != base_path` is significantly slower (~37x) than C-level string operations because it iterates over path components in Python.
**Action:** Use `not resolved_path.startswith(base_path_plus_sep) and resolved_path != base_path` (where `base_path_plus_sep = os.path.join(base_path, '')`) to achieve the exact same path traversal protection without the performance overhead.
## 2025-05-24 - Ensure imports for concurrency
**Learning:** Using `concurrent.futures.ThreadPoolExecutor` for concurrency optimizations requires explicitly verifying that `import concurrent.futures` exists in the file, even if it passes local tests (due to mocking or environment pollution). Missing imports will cause `NameError` at runtime.
**Action:** Always verify `import concurrent.futures` is present when adding multithreading optimizations.

## 2023-10-27 - Concurrent network calls with ThreadPoolExecutor
**Learning:** Using `concurrent.futures.ThreadPoolExecutor` significantly reduces execution time when making multiple independent network or slow subprocess calls (e.g., GitHub API requests), particularly when the primary script runs sequentially and blockingly on IO operations. Always verify that `import concurrent.futures` exists when applying this optimization to avoid `NameError`s in production.
**Action:** When identifying sequentially executed network-bound API fetches (e.g., in `.github/scripts`), replace them with thread pool tasks if they don't depend on each other. Wrap the logic in a small helper function to comply with "Large Method" style rules if needed. Verify imports explicitly.
## 2025-12-15 - Concurrent GitHub Action Tag Fetching
**Learning:** Sequential network calls inside loops, like fetching GitHub Action tags for workflow updates, introduce significant blocking I/O bottlenecks.
**Action:** Extract the network fetching logic into a separate helper function (to avoid "Large Method" static analysis violations) and use `concurrent.futures.ThreadPoolExecutor` to run the independent requests concurrently. This reduces execution time substantially (e.g., from ~2.6s to ~1s). Always ensure `import concurrent.futures` is present.
