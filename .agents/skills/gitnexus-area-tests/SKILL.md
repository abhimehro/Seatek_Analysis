---
name: gitnexus-area-tests
description: "Skill for the Tests area of Seatek_Analysis. 22 symbols across 4 files."
---

# Tests

22 symbols | 4 files | Cohesion: 100%

## When to Use

- Working with code in `tests/`
- Understanding how read_file_safe, test_read_file_safe_happy_path,
  test_read_file_safe_non_existent work
- Modifying tests-related functionality

## Key Files

| File                                         | Symbols                                                                                                                                                                                                                                                |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `tests/test_code_health_scanner.py`          | test_read_file_safe_happy_path, test_read_file_safe_non_existent, test_read_file_safe_null_byte, test_read_file_safe_path_traversal, test_read_file_safe_restricted_permissions (+6)                                                                   |
| `tests/test_refactoring_agent_workflow.py`   | load_workflow, test_prepare_command_extracts_first_cs_agent_line_from_multiline_comment, test_prepare_command_fails_when_no_cs_agent_line_present, test_refactoring_agent_enforces_concurrency_per_pr, test_refactoring_agent_retries_failed_push_once |
| `tests/test_repository_automation_common.py` | setup_mock_process, test_run_process_allowlist, test_run_shell_command_allowlist_and_custom, test_run_shell_command_list                                                                                                                               |
| `code_health_scanner.py`                     | read_file_safe, get_repo_info                                                                                                                                                                                                                          |

## Entry Points

Start here when exploring this area:

- **`read_file_safe`** (Function) — `code_health_scanner.py:81`
- **`test_read_file_safe_happy_path`** (Function) —
  `tests/test_code_health_scanner.py:47`
- **`test_read_file_safe_non_existent`** (Function) —
  `tests/test_code_health_scanner.py:77`
- **`test_read_file_safe_null_byte`** (Function) —
  `tests/test_code_health_scanner.py:100`
- **`test_read_file_safe_path_traversal`** (Function) —
  `tests/test_code_health_scanner.py:60`

## Key Symbols

| Symbol                                                                     | Type     | File                                         | Line |
| -------------------------------------------------------------------------- | -------- | -------------------------------------------- | ---- |
| `read_file_safe`                                                           | Function | `code_health_scanner.py`                     | 81   |
| `test_read_file_safe_happy_path`                                           | Function | `tests/test_code_health_scanner.py`          | 47   |
| `test_read_file_safe_non_existent`                                         | Function | `tests/test_code_health_scanner.py`          | 77   |
| `test_read_file_safe_null_byte`                                            | Function | `tests/test_code_health_scanner.py`          | 100  |
| `test_read_file_safe_path_traversal`                                       | Function | `tests/test_code_health_scanner.py`          | 60   |
| `test_read_file_safe_restricted_permissions`                               | Function | `tests/test_code_health_scanner.py`          | 106  |
| `test_read_file_safe_too_large`                                            | Function | `tests/test_code_health_scanner.py`          | 65   |
| `get_repo_info`                                                            | Function | `code_health_scanner.py`                     | 18   |
| `test_get_repo_info_exception_logging`                                     | Function | `tests/test_code_health_scanner.py`          | 81   |
| `test_get_repo_info_failure`                                               | Function | `tests/test_code_health_scanner.py`          | 38   |
| `test_get_repo_info_https`                                                 | Function | `tests/test_code_health_scanner.py`          | 11   |
| `test_get_repo_info_no_dot_git`                                            | Function | `tests/test_code_health_scanner.py`          | 29   |
| `test_get_repo_info_ssh`                                                   | Function | `tests/test_code_health_scanner.py`          | 20   |
| `load_workflow`                                                            | Function | `tests/test_refactoring_agent_workflow.py`   | 16   |
| `test_prepare_command_extracts_first_cs_agent_line_from_multiline_comment` | Function | `tests/test_refactoring_agent_workflow.py`   | 57   |
| `test_prepare_command_fails_when_no_cs_agent_line_present`                 | Function | `tests/test_refactoring_agent_workflow.py`   | 99   |
| `test_refactoring_agent_enforces_concurrency_per_pr`                       | Function | `tests/test_refactoring_agent_workflow.py`   | 20   |
| `test_refactoring_agent_retries_failed_push_once`                          | Function | `tests/test_refactoring_agent_workflow.py`   | 29   |
| `setup_mock_process`                                                       | Function | `tests/test_repository_automation_common.py` | 23   |
| `test_run_process_allowlist`                                               | Function | `tests/test_repository_automation_common.py` | 69   |

## How to Explore

1. `context({name: "read_file_safe"})` — see callers and callees
2. `query({search_query: "tests"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings
   (source→sink data flows), when indexed with `--pdg`
