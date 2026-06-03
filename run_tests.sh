#!/bin/bash
docker run --rm -v $(pwd):/app -w /app rocker/r-ver:4.3.0 Rscript -e 'install.packages(c("testthat", "openxlsx", "data.table")); testthat::test_dir("tests/testthat")'
