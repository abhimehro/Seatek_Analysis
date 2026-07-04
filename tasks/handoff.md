═════ ELIR ═════
PURPOSE: Extracted sensor file validation logic out of `read_sensor_data` into a self-contained helper function `validate_sensor_file` to improve code maintainability and readability.
SECURITY: Maintained existing path traversal and OOM DOS checks for the `.txt` extension and `max_file_size`.
FAILS IF: Validation constraints change but are only applied to the new helper and somehow bypassed by other logic, though `validate_sensor_file` guarantees validation at the entry of `read_sensor_data`.
VERIFY: Ensure the validation occurs before reading `fread()` and that `stop()` halts execution gracefully on bad files.
MAINTAIN: The `validate_sensor_file` function handles pre-read checks. Additional format or permissions checks should be added there.
