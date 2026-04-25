💡 What: Fixed CI by pinning pandas to `<3.0.0` and updating the CI python version to `3.11`.

🎯 Why: The CI was failing during `pip install` because pandas versions `>=3.0` require `python>=3.11`, and the workflow was using `python 3.10`. Updating both fixes the conflict while preserving compatibility.

📊 Measured Improvement: Unblocks the `validate` GitHub Actions workflow.

🔬 Measurement: Verify that the GitHub Actions run completes successfully.
