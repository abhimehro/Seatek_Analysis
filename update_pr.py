import subprocess
import json

def run_command(cmd):
    return subprocess.check_output(cmd, shell=True).decode('utf-8')

# The branch currently contains a commit that has conflict markers removed.
# It also has the code from `.github/scripts/repository_automation_tasks.py` which was refactored.
