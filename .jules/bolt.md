## 2024-08-26 - Negligible S3 Dispatch Overhead in Base R Statistics

**Learning:** While `mean.default()` bypasses S3 generic dispatch and executes slightly faster than `mean()` (~1-2 microseconds faster in microbenchmarks), this optimization is negligible and potentially considered an anti-pattern when the inner loop calls much heavier functions like `mad()` or `median()`. The S3 overhead is miniscule compared to the sorting and allocation costs of robust statistics.

**Action:** Avoid micro-optimizing generic S3 function calls (like `mean` -> `mean.default`) unless they are the *only* operation inside a massive, highly critical inner loop. Prioritize algorithmic improvements (e.g., O(n²) to O(n)), memory allocation reduction, or vectorization over microsecond-level dispatch bypasses.
