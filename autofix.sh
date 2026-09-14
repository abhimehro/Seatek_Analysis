Rscript -e 'lintr::lint_dir(".")' > lint_report.txt 2>&1
status=$?
if [ "$status" -eq 0 ]; then
  echo "Linting output saved to lint_report.txt"
else
  echo "Linting failed; see lint_report.txt for details" >&2
fi
exit "$status"
