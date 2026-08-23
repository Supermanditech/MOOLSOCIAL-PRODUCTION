# UAW C16H unstable cross-route capture admission rejection — 2026-08-08

## Rejection

A diagnostic screenshot appeared to show Work/Workspace, but the next fresh paired UIAutomator sample identified Mool Home as current. The capture validator rejected `16-work-workspace` and it is excluded from the accepted matrix.

## Prevention

Following a global-route event, C16H now requires two consecutive fresh semantic samples with the same family/local identity before capturing. A screenshot alone is not a stable-state proof. Any unexpected continuing route movement is investigated before another family capture.

No second install/build or protected mutation occurred.
