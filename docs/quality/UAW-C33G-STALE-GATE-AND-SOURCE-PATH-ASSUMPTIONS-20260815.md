# UAW C33G stale gate and source path assumptions

A read-only C33G inventory used two stale gate names and two assumed mobile source directories. The command printed partial valid output but exited nonzero when those paths were not found. No repository file was changed by the failed diagnostic.

Every later lookup must use the current repository file inventory or an explicit `Test-Path` result. Partial output from any nonzero composite command is not evidence.
