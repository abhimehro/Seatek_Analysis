## 2025-05-06 - Replacing x[which(x > 0)] with x[x > 0] when there are NAs
**Learning:** R's `which()` naturally drops NAs (because `NA > 0` is `NA`, and `which(NA)` drops it). So `v[which(v > 0)]` drops `NA` values without needing an explicit `na.rm` or `!is.na()` filter. If you simply replace it with `v[v > 0]`, then `NA`s in the indexing vector will return `NA` elements in the output, which completely breaks the calculation (yielding `NA` for the mean). To correctly avoid `which()`, we would need to check `v > 0 & !is.na(v)`, which actually ends up slower or barely faster than `which()`.
**Action:** Do not "optimize" `which()` out of logical subsetting when the data contains `NA`s, as it handles them elegantly and efficiently.

## 2025-05-06 - range() vs min()/max()
**Learning:** In base R, calling `min(x)` and `max(x)` separately is actually slightly faster than calling `range(x)` and extracting `[1]` and `[2]`. Calling `range()` is not an optimization in this context.
**Action:** Keep `min()` and `max()` separate in loops.

