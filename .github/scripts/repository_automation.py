#!/usr/bin/env python3
from __future__ import annotations

import argparse
import difflib
import sys

from repository_automation_common import enforce_result, load_config
from repository_automation_tasks import (
    run_backlog_manager,
    run_daily_status_report,
    run_performance_optimizer,
    run_quality_assurance,
    run_weekly_retrospective,
    run_workflow_updater,
)

TASK_RUNNERS = {
    "workflow-updater": run_workflow_updater,
    "performance-optimizer": run_performance_optimizer,
    "quality-assurance": run_quality_assurance,
    "backlog-manager": run_backlog_manager,
    "daily-status-report": run_daily_status_report,
    "weekly-retrospective": run_weekly_retrospective,
}
ENFORCE_TASK = "enforce"
SCRIPT_INVOCATION = "python .github/scripts/repository_automation.py"


def _handle_enforce(result_path: str | None) -> int:
    if not result_path:
        print("enforce requires a result path")
        print("Action: Provide the path to the result JSON file.")
        return 1
    return enforce_result(result_path)


def _handle_unknown_task(task: str) -> int:
    print(f"Unknown task: {task}. Run with --help to see available tasks.")
    candidates = [*TASK_RUNNERS, ENFORCE_TASK]
    matches = difflib.get_close_matches(task, candidates)
    if matches:
        print(f"Action: Did you mean '{matches[0]}'? Verify the task name.")
    else:
        print("Action: Verify the task name.")
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Consolidated repository automation runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Available tasks:\n  "
        + "\n  ".join(TASK_RUNNERS.keys())
        + f"\n  {ENFORCE_TASK}\n\nExamples:\n"
        + f"  {SCRIPT_INVOCATION} quality-assurance\n"
        + f"  {SCRIPT_INVOCATION} {ENFORCE_TASK} path/to/result.json",
    )
    parser.add_argument(
        "task", help="The automation task to run, or 'enforce' to evaluate results."
    )
    parser.add_argument(
        "result_path",
        nargs="?",
        help="Path to result JSON file (required for 'enforce').",
    )

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        return 1

    args = parser.parse_args()

    if args.task == ENFORCE_TASK:
        return _handle_enforce(args.result_path)

    runner = TASK_RUNNERS.get(args.task)
    if runner is None:
        return _handle_unknown_task(args.task)

    runner(load_config())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
