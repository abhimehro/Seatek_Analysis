## 2025-05-06 - CLI Visual Feedback in Muffled Contexts
**Learning:** In CLI applications (like R scripts) where standard output or message streams are suppressed or redirected (e.g., using `invokeRestart("muffleMessage")`), long-running iterations can appear frozen to the user. This creates poor UX and uncertainty.
**Action:** When designing or refactoring long-running loops (like file processing), always inject visual feedback that bypasses or operates alongside standard streams, such as `txtProgressBar` in R, to ensure the user receives consistent progress updates.
