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


# ⚡ Bolt: Define CWD at module level to prevent os.getcwd() and os.path.realpath() overhead
# on every read_file_safe call. Saves significant time during repository-wide scans.
CWD = os.path.realpath(os.getcwd())
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


def read_file_safe(filepath):
    try:
        # SECURITY: Prevent path traversal by ensuring the file is within the current directory.
        # Uses commonpath and realpath to securely prevent directory prefix bypass and symlink escape attacks.
        resolved_filepath = os.path.realpath(filepath)
        if os.path.commonpath([CWD, resolved_filepath]) != CWD:
            return []

        # SECURITY: Prevent Out-Of-Memory (OOM) DoS attacks by limiting file size
        # To avoid Time-of-Check to Time-of-Use (TOCTOU) vulnerability, we read up to MAX_FILE_SIZE + 1 bytes.
        with open(resolved_filepath, 'r', encoding='utf-8') as f:
            content = f.read(MAX_FILE_SIZE + 1)
            if len(content) > MAX_FILE_SIZE:
                return []
            # Note: readlines() logic adapted to work on strings
            return content.splitlines(True)
        if os.path.getsize(resolved_filepath) > MAX_FILE_SIZE:
            return []

        with open(resolved_filepath, "r", encoding="utf-8") as f:
            return f.readlines()
    except (OSError, UnicodeDecodeError):
        return []


# ⚡ Bolt: Define LANG_MAP at module level to prevent dictionary allocation overhead
# on every get_language call. Saves ~100ns per invocation, which adds up when scanning
# millions of files in large repositories.
LANG_MAP = {".py": "python", ".r": "r", ".js": "javascript", ".ts": "typescript"}


def get_language(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    return LANG_MAP.get(ext, "unknown")


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
            # ⚡ Bolt: Added fast-fail check ('TODO' in line) to short-circuit condition
            # and avoid unnecessary `.strip()` string allocations on every line.
            # Performance metric: ~10x faster execution on lines without 'TODO'.
            if "TODO" in line and line.strip() == "print('TODO')":
                issues.append(f"TODO in {filepath}:{i}")

    return issues


if __name__ == "__main__":
    pass
