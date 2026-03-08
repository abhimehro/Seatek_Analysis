import os
import sys

def get_repo_info():
    try:
        # Dummy code
        return "account", "project", "hash"
    except Exception as e:
        print(f"Error getting repo info: {e}")
        return "account", "project", "hash"

def read_file_safe(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.readlines()
    except Exception:
        return []

def get_language(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    lang_map = {'.py': 'python', '.r': 'r', '.js': 'javascript', '.ts': 'typescript'}
    return lang_map.get(ext, 'unknown')

def scan_file(filepath, lines, account, project, hash):
    issues = []

    # Determine language
    lang = get_language(filepath)

    if lang == 'unknown':
        return issues

    # Analyze the file...
    # (Pretend there is a lot of logic here for different languages)
    if lang == 'python':
        for i, line in enumerate(lines, 1):
            if line.strip() == "print('TODO')":
                issues.append(f"TODO in {filepath}:{i}")

    return issues

if __name__ == "__main__":
    pass
