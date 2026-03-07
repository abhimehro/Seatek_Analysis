## 2025-05-06 - Batching Excel I/O
**Learning:** Pandas `read_excel` and `to_excel` are extremely expensive I/O operations. Modifying Excel files inside a loop over individual rows (O(N) operations) causes massive slowdowns and can accidentally overwrite previous corrections if the original file is read each time.
**Action:** Always group dataframe operations by the target file/sheet first. Read the file once, apply all operations in memory, and write it back out once (O(1) per sheet).

## 2025-05-06 - Optimize NA filtering in R inner loops
**Learning:** `which(x > 0)` is substantially faster than `!is.na(x) & x > 0` for finding positive, non-NA elements in an R vector because it inherently drops NA values and avoids computing an element-wise logical `&` operation.
**Action:** When filtering out NAs and matching a condition in a high-frequency loop, use `which(condition)` over `!is.na(x) & condition`.

## 2025-05-06 - Grouping Redundancy in data.table Aggregations
**Learning:** Performing multiple statistical aggregations on a column with `na.rm = TRUE` repeatedly traverses the vector to remove NAs, compounding iteration cost per group.
**Action:** Extract the non-NA values once per group `v <- na.omit(Value)` and apply the statistical functions on `v` directly.

## 2025-05-06 - Prevent Re-parsing Excel Files in Loops
**Learning:** `pd.read_excel(file_path, sheet_name=sheet)` re-parses the entire zip-like structure of the `.xlsx` file from scratch every single time it's called. When looping over multiple sheets in the same file, this becomes an O(N * M) operation (where N is sheets and M is file size).
**Action:** When reading multiple sheets from the same Excel file inside a loop, always instantiate a `pd.ExcelFile(file_path)` object outside the loop first, and use `pd.read_excel(xls, sheet_name=sheet)` inside the loop. This reduces the parsing overhead to O(M).

## 2025-05-06 - Avoid Repeated Column Subsetting in data.table
**Learning:** Using `sapply(df[, cols, with=FALSE], ...)` combined with row-based subsetting functions inside the loop like `head(x, N)` forces the creation of a subset `data.frame` first, then sequentially traverses each column and slices it. For large rows/columns, this is an O(M * N) operation.
**Action:** Use data.table's native optimized `i` row filters along with `.SDcols` (e.g., `df[1:10, lapply(.SD, function), .SDcols = cols]`). This subsets the rows once in C (O(1) operation), and evaluates the function seamlessly across all targets, drastically reducing memory allocation and iteration cost.

## 2025-05-06 - Avoid .iterrows() in Pandas DataFrame processing
**Learning:** Iterating over a DataFrame using `.iterrows()` is extremely slow (O(N) operations in Python) and defeats the purpose of pandas, especially when dealing with row-wise string manipulations or conditional extractions (e.g., regex matching).
**Action:** Replace `iterrows()` with Pandas vectorized `.str` accessor methods (like `.str.findall()`, `.str.len()`, `.str.split()`) and boolean masking. This leverages underlying optimized C code and scales efficiently (O(1) from Python's perspective).
