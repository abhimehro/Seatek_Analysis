Rscript -e 'lintr::lint_dir(".")' > lint_report.txt 2>&1
echo "Linting output saved to lint_report.txt"
