#!/usr/bin/env python3
from __future__ import annotations

import argparse

from repository_automation_common import enforce_result, load_config
from repository_automation_tasks import (
    run_backlog_manager,
    run_daily_status_report,
    run_performance_optimizer,
    run_quality_assurance,
    run_weekly_retrospective,
    run_workflow_updater,
)

class CustomHelpFormatter(
    argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter
):
    pass


TASK_RUNNERS = {
    "workflow-updater": run_workflow_updater,
    "performance-optimizer": run_performance_optimizer,
    "quality-assurance": run_quality_assurance,
    "backlog-manager": run_backlog_manager,
    "daily-status-report": run_daily_status_report,
    "weekly-retrospective": run_weekly_retrospective,
}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Consolidated repository automation runner",
        formatter_class=CustomHelpFormatter,
        epilog="Available tasks:\n  "
        + "\n  ".join(TASK_RUNNERS.keys())
        + "\n  enforce\n\nExamples:\n  repository_automation.py quality-assurance\n  repository_automation.py enforce path/to/result.json",
    )
    parser.add_argument(
        "task", help="The automation task to run, or 'enforce' to evaluate results."
    )
    parser.add_argument(
        "result_path",
        nargs="?",
        help="Path to result JSON file (required for 'enforce').",
    )

    import sys

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        return 1

    args = parser.parse_args()

    if args.task == "enforce":
        if not args.result_path:
            print("enforce requires a result path")
            print("Action: Provide the path to the result JSON file.")
            return 1
        return enforce_result(args.result_path)

    runner = TASK_RUNNERS.get(args.task)
    if runner is None:
        print(f"Unknown task: {args.task}. Run with --help to see available tasks.")
        import difflib

        matches = difflib.get_close_matches(args.task, TASK_RUNNERS.keys())
        if matches:
            print(f"Action: Did you mean '{matches[0]}'? Verify the task name.")
        else:
            print("Action: Verify the task name.")
        return 1

    runner(load_config())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
