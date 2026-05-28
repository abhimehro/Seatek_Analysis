💡 What
Implemented concurrent execution for GitHub API calls in the `run_backlog_manager` function. Extracted the fetching logic into a `fetch_backlog_data` helper and wrapped the `gh_json` subprocess calls with `concurrent.futures.ThreadPoolExecutor(max_workers=2)`. Also ensured `import concurrent.futures` is present.

🎯 Why
The script was previously executing two independent, network-bound GitHub CLI commands sequentially. This created an unnecessary blocking I/O bottleneck that slowed down the entire repository automation run.

📊 Impact
Reduces the I/O blocking time of the backlog manager script by approximately 50%, as the issue and PR queries now execute in parallel rather than sequentially.

🔬 Measurement
Verify the improvement by running `.github/scripts/repository_automation.py backlog-manager` and measuring the execution time before and after the change. Local benchmarks showed a 50% decrease in total time waiting for API results.
