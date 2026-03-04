## 2025-05-06 - Batching Excel I/O
**Learning:** Pandas `read_excel` and `to_excel` are extremely expensive I/O operations. Modifying Excel files inside a loop over individual rows (O(N) operations) causes massive slowdowns and can accidentally overwrite previous corrections if the original file is read each time.
**Action:** Always group dataframe operations by the target file/sheet first. Read the file once, apply all operations in memory, and write it back out once (O(1) per sheet).

## 2025-05-06 - Optimize NA filtering in R inner loops
**Learning:** `which(x > 0)` is substantially faster than `!is.na(x) & x > 0` for finding positive, non-NA elements in an R vector because it inherently drops NA values and avoids computing an element-wise logical `&` operation.
**Action:** When filtering out NAs and matching a condition in a high-frequency loop, use `which(condition)` over `!is.na(x) & condition`.

## 2025-05-06 - Grouping Redundancy in data.table Aggregations
**Learning:** Performing multiple statistical aggregations on a column with `na.rm = TRUE` repeatedly traverses the vector to remove NAs, compounding iteration cost per group.
**Action:** Extract the non-NA values once per group `v <- na.omit(Value)` and apply the statistical functions on `v` directly.
