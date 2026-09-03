## Summary
<!-- What changed and why -->

## Type of change
- [ ] Bug fix
- [ ] Docs / housekeeping
- [ ] Feature
- [ ] Refactor (no behavior change)
- [ ] CI / tooling
- [ ] R analysis / data pipeline

## Checklist
- [ ] R tests: `Rscript -e "library(testthat); source('Updated_Seatek_Analysis.R', local = TRUE); testthat::test_dir('tests/testthat', reporter = 'summary')"` (or CI green)
- [ ] No venv, backups, or regenerable Data/*.xlsx committed
- [ ] No secrets or local env files included
