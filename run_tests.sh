#!/bin/bash
set -euo pipefail

Rscript -e "renv::restore(); library(testthat); source('Updated_Seatek_Analysis.R', local = TRUE); testthat::test_dir('tests/testthat', reporter = 'summary')"
