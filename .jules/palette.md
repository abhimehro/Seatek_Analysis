## 2025-05-06 - Excel Accessibility for Background Colors

**Learning:** When generating Excel reports, using background fill colors (`bgFill`) without explicitly setting a text color (`fontColour`) can result in poor contrast and accessibility issues (e.g., black text on dark colored backgrounds). **Action:** Always explicitly pair `bgFill` with a high-contrast `fontColour` (like `fontColour = "#000000"` for light backgrounds or `fontColour = "#FFFFFF"` for dark ones) when creating styles in `openxlsx` to ensure proper readability and accessibility.
## 2025-05-06 - CLI Input Validation Error UX

**Learning:** Allowing standard library exceptions (like FileNotFoundError) to
bubble up directly to the user creates a poor CLI experience filled with scary
stack traces. **Action:** Explicitly validate user-provided file paths early and
provide a clean, human-readable error message.

## 2025-05-06 - Preventing Empty Output Directories on Failure

**Learning:** Creating output directories (like using
`os.makedirs(args.output, exist_ok=True)`) _before_ validating input files
causes the application to generate empty directory clutter on the file system if
the script subsequently fails to find or process the input. **Action:** Always
validate input files (e.g., using `os.path.isfile()`) and verify that core data
loading can begin _before_ executing side effects like creating output
directories or creating file artifacts.

## 2025-05-06 - CLI Empty State UX

**Learning:** When a CLI script requires arguments, the default `argparse`
behavior of throwing a "missing arguments" error on a bare run provides a poor
first impression and lacks guidance. **Action:** Always intercept a bare run
(e.g., `len(sys.argv) == 1`) and print the full help menu
(`parser.print_help()`) so users immediately see usage examples and available
options without needing to guess the `--help` flag.
