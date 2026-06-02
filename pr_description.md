🧪 [testing improvement description]
🎯 **What:** The testing gap addressed
- Addressed testing gap for the `clean_vals` function which extracts positive values and inherently handles NA elements using `which(x > 0)`.

📊 **Coverage:** What scenarios are now tested
- Valid numerical vectors of varying inputs including negatives and zeroes.
- Vectors containing `NA` elements.
- Empty vectors.
- Vectors with all negatives or zeros.
- Vectors with all positive numeric values.

✨ **Result:** The improvement in test coverage
- Confirms reliable dropping of un-parseable data, ensuring data processing routines using `clean_vals` perform correctly on diverse or corrupted datasets. Added five thorough test checks.
