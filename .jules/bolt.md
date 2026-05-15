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
## 2026-05-12 - Lowercase only the extension suffix, not the whole path
**Learning:** Calling `filepath.lower()` on a full path before checking extensions allocates a new string proportional to the path length on every invocation. Using `.endswith(('.ext', '.EXT'))` on the original string is faster but only matches all-lower/all-upper variants — mixed-case extensions like `.Py` or `.jS` are silently dropped, which is a correctness regression.
**Action:** Extract the extension with `os.path.splitext(filepath)[1]` and call `.lower()` on just the short suffix, then look it up in a module-level `dict` mapping extensions to languages. This preserves full case-insensitive matching, removes the allocation cost of lowercasing the whole path, and replaces the if/elif chain with an O(1) dispatch.
