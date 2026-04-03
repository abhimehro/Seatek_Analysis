## 2025-05-06 - CLI Input Validation Error UX

**Learning:** Allowing standard library exceptions (like FileNotFoundError) to bubble up directly to the user creates a poor CLI experience filled with scary stack traces.
**Action:** Explicitly validate user-provided file paths early and provide a clean, human-readable error message.

## 2025-05-06 - Preventing Empty Output Directories on Failure

**Learning:** Creating output directories (like using `os.makedirs(args.output, exist_ok=True)`) _before_ validating input files causes the application to generate empty directory clutter on the file system if the script subsequently fails to find or process the input.
**Action:** Always validate input files (e.g., using `os.path.isfile()`) and verify that core data loading can begin _before_ executing side effects like creating output directories or creating file artifacts.
