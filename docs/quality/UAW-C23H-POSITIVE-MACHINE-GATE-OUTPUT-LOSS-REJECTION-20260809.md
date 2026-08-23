# C23H positive machine-gate output loss rejection

Date: 2026-08-09

The first positive C23H machine-gate command returned only a truncated-output
notice. It produced no execution-cell identifier, no bounded pass line and no
retained positive-gate evidence. The result is rejected and authorizes neither
the APK build nor installation.

The recovery audit established that no app terminal was attached, the r60.22
APK did not exist, machine state remained `prebuild_passed`, the one-build
authorization remained `approved_for_one_build`, and no install authorization
was open. The read-only gate must be rerun with bounded retained output before
the unique build wrapper may be invoked.
