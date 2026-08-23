# REG2863 — C34L transition FIX2 prior-root cleanup policy block

Date: 17 August 2026
State: registered pre-execution cleanup rejection; prior root unchanged

## Mistake

After correcting the checker to unlink its verified junction with the .NET API,
the agent attempted a standalone cleanup of the exact prior failed fixture root.
Command policy rejected the process before execution despite literal root/link/
target checks. The prior root remains unchanged; no retry, test, or later mutation
followed. The checker patch had already applied before the blocked command.

## Prevention

Do not issue a standalone recursive cleanup command after policy rejection. Let
each fresh checker own and clean its new exact root with verified nonrecursive
junction unlink and absence assertions. Preserve/report the prior exact orphan
for primary inventory; remove it only through an explicitly approved repository
fixture-cleanup owner that validates every target and never traverses a reparse link.
