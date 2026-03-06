## 2025-05-06 - Progress Bar and Standard Output Garbling
**Learning:** In interactive console applications, interleaving `cat` (standard output) statements within a loop that also updates a progress bar (e.g., `txtProgressBar` in R) causes the progress bar to become garbled and split across multiple lines, resulting in a confusing and messy UI.
**Action:** When using a progress bar in a loop, ensure that all standard output or `cat` statements inside the loop are suppressed or redirected so the progress bar can render cleanly.

## 2025-05-06 - CLI Visual Feedback in Muffled Contexts
**Learning:** In CLI applications (like R scripts) where message conditions are muffled (e.g., `message()` output via `invokeRestart("muffleMessage")`) or standard output is suppressed or redirected, long-running iterations can appear frozen to the user. This creates poor UX and uncertainty.
**Action:** When designing or refactoring long-running loops (like file processing), always inject visual feedback that bypasses or operates alongside standard streams, such as `txtProgressBar` in R, to ensure the user receives consistent progress updates.
