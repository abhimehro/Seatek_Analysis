🎯 **What:**
Added a test to cover the memory boundary check (max file size constraint) in `read_sensor_data`.

📊 **Coverage:**
- Ensures the 50MB maximum file limit check correctly throws an error.
- Validates that `MAX_FILE_SIZE` handling in `Updated_Seatek_Analysis.R` works and catches large files.

✨ **Result:**
The `read_sensor_data` function is now fully covered regarding the security constraint of out-of-memory denial of service prevention, increasing overall test reliability.
