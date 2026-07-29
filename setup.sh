#!/bin/bash
set -euo pipefail

echo "Starting dependency setup..."

# Update package index and install build/system libraries (if apt is available)
if command -v apt-get &>/dev/null; then
	apt-get update
	apt-get install -y -qq libcurl4-openssl-dev libxml2-dev libssl-dev \
		libfontconfig1-dev libharfbuzz-dev libfribidi-dev libuv1-dev \
		libzip-dev zlib1g-dev libgit2-dev pandoc cmake

	# Install R if missing (version is OS/repo dependent; lockfile target is 4.3.3)
	if ! command -v R &>/dev/null; then
		echo "R not found. Installing R and build tools..."
		apt-get install -y -qq r-base r-base-dev
	fi
fi

# Ensure Python and venv/pip tooling are available
if command -v apt-get &>/dev/null; then
	echo "Ensuring Python3, venv, and pip are installed..."
	apt-get install -y -qq python3 python3-venv python3-pip
fi

# Restore R packages from the lockfile
echo "Restoring R packages with renv..."
Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos = 'https://cloud.r-project.org'); renv::restore()" | tee renv_restore.log

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
	pip install bandit
	deactivate
else
	echo "Warning: Requirements file $REQUIREMENTS_FILE not found."
fi

echo "Dependency setup complete."
