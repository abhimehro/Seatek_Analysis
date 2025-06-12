#!/bin/bash
set -euo pipefail

echo "Starting dependency setup..."

# Update package index
apt-get update

# Install R and required system libraries if R is missing
if ! command -v R &> /dev/null; then
    echo "R not found. Installing R and system libraries..."
    apt-get install -y r-base r-base-dev libgit2-dev pandoc
fi

# Ensure python and venv tools are available
if ! command -v python3 &> /dev/null; then
    echo "Python3 not found. Installing Python3..."
    apt-get install -y python3 python3-venv python3-pip
else
    apt-get install -y python3-venv python3-pip
fi

# Restore R packages using renv
echo "Restoring R packages with renv..."
Rscript -e "if(!'renv' %in% rownames(installed.packages())) install.packages('renv', repos='https://cloud.r-project.org'); renv::restore()" || echo "renv restore failed - proceeding with base install"

# Install additional packages needed for linting and testing
echo "Installing core R packages for linting and testing..."
Rscript - <<'EOF'
packages <- c('testthat', 'data.table', 'openxlsx', 'dplyr', 'tidyr', 'logger', 'lintr')
install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = 'https://cloud.r-project.org')
  }
}
invisible(lapply(packages, install_if_missing))
EOF

# Setup Python virtual environment
VENV_DIR="Series_27/Analysis/venv"
REQUIREMENTS_FILE="Series_27/Analysis/requirements.txt"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment at $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
fi

echo "Installing Python packages from $REQUIREMENTS_FILE..."
if [ -f "$REQUIREMENTS_FILE" ]; then
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install -r "$REQUIREMENTS_FILE"
    deactivate
else
    echo "Warning: Requirements file $REQUIREMENTS_FILE not found."
fi

echo "Dependency setup complete."
