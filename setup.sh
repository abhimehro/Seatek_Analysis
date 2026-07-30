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

	# Ensure Python and venv/pip tooling are available before the version guard.
	echo "Ensuring Python3, venv, and pip are installed..."
	apt-get install -y -qq python3 python3-venv python3-pip
fi

# Restore R packages from the lockfile (core pipeline, independent of Python)
echo "Restoring R packages with renv..."
Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv', repos = 'https://cloud.r-project.org'); renv::restore()" | tee renv_restore.log

# Optional Series 27 Python environment
VENV_DIR="Series_27/Analysis/venv"
REQUIREMENTS_FILE="Series_27/Analysis/requirements.txt"
REQUIREMENTS_DEV_FILE="requirements-dev.txt"

# Ensure a Python 3.11/3.12 interpreter is available for the Series 27 analysis
# environment. The pinned numpy==1.26.0 only ships wheels for 3.11/3.12, so we
# restrict the guard to that range to avoid a source-build failure on 3.13+.
# Because the Python analysis is optional, a missing/unsupported interpreter is
# treated as a warning rather than a fatal error.
PYTHON_BIN=""
for py in python3.11 python3.12 python3; do
	if command -v "$py" &>/dev/null; then
		if "$py" -c "import sys; sys.exit(0 if (3, 11) <= sys.version_info[:2] <= (3, 12) else 1)" 2>/dev/null; then
			PYTHON_BIN="$py"
			break
		fi
	fi
done

if [ -z "$PYTHON_BIN" ]; then
	echo "Warning: No Python 3.11 or 3.12 interpreter found; skipping optional Series 27 Python venv setup." >&2
	echo "Dependency setup complete (R packages restored; Series 27 Python venv skipped)."
	exit 0
fi

echo "Using Python interpreter: $PYTHON_BIN ($($PYTHON_BIN --version))"

# Setup or validate the Series 27 virtual environment
if [ ! -d "$VENV_DIR" ]; then
	echo "Creating Python virtual environment at $VENV_DIR..."
	"$PYTHON_BIN" -m venv "$VENV_DIR"
else
	# If a venv already exists (e.g. the tracked placeholder), verify it uses a
	# compatible Python before installing into it.
	VENV_PYTHON="$VENV_DIR/bin/python"
	if [ -f "$VENV_PYTHON" ]; then
		if ! "$VENV_PYTHON" -c "import sys; sys.exit(0 if (3, 11) <= sys.version_info[:2] <= (3, 12) else 1)" 2>/dev/null; then
			echo "Warning: Existing venv at $VENV_DIR does not use Python 3.11/3.12. Recreate it with:" >&2
			echo "  rm -rf $VENV_DIR && $PYTHON_BIN -m venv $VENV_DIR" >&2
			PYTHON_BIN=""
		fi
	else
		echo "Warning: Existing venv at $VENV_DIR is missing its python binary; skipping Python package install." >&2
		PYTHON_BIN=""
	fi
fi

if [ -n "$PYTHON_BIN" ]; then
	echo "Installing Python packages from $REQUIREMENTS_FILE..."
	if [ -f "$REQUIREMENTS_FILE" ]; then
		if [ -f "$VENV_DIR/bin/activate" ]; then
			source "$VENV_DIR/bin/activate"
			python -m pip install --upgrade pip
			python -m pip install -r "$REQUIREMENTS_FILE"
			if [ -f "$REQUIREMENTS_DEV_FILE" ]; then
				python -m pip install -r "$REQUIREMENTS_DEV_FILE"
			fi
			deactivate
		else
			echo "Warning: activate script missing in $VENV_DIR; skipping Python package install."
		fi
	else
		echo "Warning: Requirements file $REQUIREMENTS_FILE not found."
	fi
fi

echo "Dependency setup complete."
