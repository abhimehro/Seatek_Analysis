import logging
import os


def get_repo_info():
    try:
        # Dummy code
        return "account", "project", "hash"
    except Exception as e:
        # SECURITY: Fail securely, don't expose internal exception details
        logging.error(
            f"Error getting repo info: Internal error occurred ({type(e).__name__})."
        )
        return "account", "project", "hash"


MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def read_file_safe(filepath):
    try:
        # SECURITY: Prevent path traversal by ensuring the file is within the current directory.
        # Uses commonpath and realpath to securely prevent directory prefix bypass and symlink escape attacks.
        cwd = os.path.realpath(os.getcwd())
        resolved_filepath = os.path.realpath(filepath)
        if os.path.commonpath([cwd, resolved_filepath]) != cwd:
            return []

        # SECURITY: Prevent Out-Of-Memory (OOM) DoS attacks by limiting file size
        if os.path.getsize(resolved_filepath) > MAX_FILE_SIZE:
            return []

        with open(resolved_filepath, "r", encoding="utf-8") as f:
            return f.readlines()
    except (OSError, UnicodeDecodeError):
        return []


def get_language(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    lang_map = {".py": "python", ".r": "r", ".js": "javascript", ".ts": "typescript"}
    return lang_map.get(ext, "unknown")


def scan_file(filepath, lines, account, project, commit_hash):
    issues = []

    # Determine language
    lang = get_language(filepath)

    if lang == "unknown":
        return issues

    # Analyze the file...
    # (Pretend there is a lot of logic here for different languages)
    if lang == "python":
        for i, line in enumerate(lines, 1):
            if line.strip() == "print('TODO')":
                issues.append(f"TODO in {filepath}:{i}")

    return issues


if __name__ == "__main__":
    pass
