with open('.github/scripts/repository_automation_tasks.py', 'r') as f:
    lines = f.readlines()

out_lines = []
import_os_count = 0
import_pathlib_count = 0
for line in lines:
    if line.startswith("import os"):
        import_os_count += 1
        if import_os_count > 1:
            continue
    if line.startswith("import pathlib"):
        import_pathlib_count += 1
        if import_pathlib_count > 1:
            continue
    out_lines.append(line)

with open('.github/scripts/repository_automation_tasks.py', 'w') as f:
    f.writelines(out_lines)
