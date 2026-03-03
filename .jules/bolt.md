## 2025-05-06 - Batching Excel I/O
**Learning:** Pandas `read_excel` and `to_excel` are extremely expensive I/O operations. Modifying Excel files inside a loop over individual rows (O(N) operations) causes massive slowdowns and can accidentally overwrite previous corrections if the original file is read each time.
**Action:** Always group dataframe operations by the target file/sheet first. Read the file once, apply all operations in memory, and write it back out once (O(1) per sheet).
