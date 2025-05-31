#!/bin/bash

echo "Starting dependency setup..."

# Check for R installation
if ! command -v R &> /dev/null
then
    echo "R could not be found. Please install R and try again."
    exit 1
fi

echo "R is installed. Proceeding with R package restoration..."

# Restore R packages using renv
Rscript -e "renv::restore()"

echo "R package restoration complete."

echo "Starting Python dependency setup..."

# Check for Python 3 installation
if ! command -v python3 &> /dev/null
then
    echo "Python 3 could not be found. Please install Python 3 and try again."
    exit 1
fi

echo "Python 3 is installed."

VENV_DIR="Series_27/Analysis/venv"
REQUIREMENTS_FILE="Series_27/Analysis/requirements.txt"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment at $VENV_DIR..."
    python3 -m venv $VENV_DIR
else
    echo "Python virtual environment already exists at $VENV_DIR."
fi

# Activate virtual environment, install packages, then deactivate
echo "Installing Python packages from $REQUIREMENTS_FILE..."
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "Error: Requirements file $REQUIREMENTS_FILE not found. Please ensure the file exists and try again."
    exit 1
fi
source "$VENV_DIR/bin/activate" && pip install -r "$REQUIREMENTS_FILE"
deactivate

echo "Python package installation complete."
echo "Setup script finished."
