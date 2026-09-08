# Qodo review + CI fixes (PR #812)

- [x] PR template: add general Python pytest checklist; keep Series 27 item
- [x] pr-validation.yml: fail the job when pytest fails (remove `|| echo` swallow)
- [x] README: mark Series 26/27 `processing_log.txt` as optional local/gitignored artifacts
- [x] Confirm `.gitignore` recursive `**/processing_log.txt` remains
- [x] Run pytest (61 passed); scan secrets (clean)
- [x] Note: CodeQL js/c-cpp failures are default-setup config (no source); not fixed via app code
