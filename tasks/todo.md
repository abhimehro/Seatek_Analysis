# Qodo review + CI fixes (PR #812)

- [ ] PR template: add general Python pytest checklist; keep Series 27 item
- [ ] pr-validation.yml: fail the job when pytest fails (remove `|| echo` swallow)
- [ ] README: mark Series 26/27 `processing_log.txt` as optional local/gitignored artifacts
- [ ] Confirm `.gitignore` recursive `**/processing_log.txt` remains
- [ ] Run pytest; scan secrets; report progress / open PR if needed
