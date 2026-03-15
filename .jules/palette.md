## 2025-05-06 - Progress Bar and Standard Output Garbling
**Learning:** In interactive console applications, interleaving `cat` (standard output) statements within a loop that also updates a progress bar (e.g., `txtProgressBar` in R) causes the progress bar to become garbled and split across multiple lines, resulting in a confusing and messy UI.
**Action:** When using a progress bar in a loop, ensure that all standard output or `cat` statements inside the loop are suppressed or redirected so the progress bar can render cleanly.

## 2025-05-06 - CLI Visual Feedback in Muffled Contexts
**Learning:** In CLI applications (like R scripts) where message conditions are muffled (e.g., `message()` output via `invokeRestart("muffleMessage")`) or standard output is suppressed or redirected, long-running iterations can appear frozen to the user. This creates poor UX and uncertainty.
**Action:** When designing or refactoring long-running loops (like file processing), always inject visual feedback that bypasses or operates alongside standard streams, such as `txtProgressBar` in R, to ensure the user receives consistent progress updates.

## 2025-05-06 - Explicit Progress Bar Closure
**Learning:** Depending on standard error cleanup (`on.exit`) to close a progress bar delays the final newline output until the entire function exits. This can cause subsequent CLI output (like status messages or parallel processing logs) to become garbled or appended to the same line as the finished progress bar, significantly degrading the user experience.
**Action:** Always explicitly call `close()` on the progress bar immediately after its loop finishes to flush the stream and output a clean newline, before proceeding to other tasks in the same function. Retain the `on.exit()` cleanup for error handling, but do not rely on it for normal control flow.
