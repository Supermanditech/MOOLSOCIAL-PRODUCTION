# C25E negative ripgrep no-match exit — rejection

Date: 2026-08-09

A bare ripgrep audit searched the migrated Buy test for predecessor keys. It found none and returned its normal no-match exit code 1, which the shell reported as a failed script. That call is not recorded as qualifying absence evidence.

Future absence checks must explicitly interpret ripgrep exit 0 as a rejected match, exit 1 as a pass and any other exit as an execution error.
