# REG3154 - Unattended state readback wrong object depth

## Classification

Registered false absence corrected before retry, with zero duplicate mutation.

## Evidence

The first readback queried `unattendedAutomation` at top level. The live top-level inventory and parent projection proved the requested rule already existed under `comprehensiveSuccessorAudit.unattendedAutomation`, including the 08:00 IST review time, allowed and forbidden actions, and `powerOffRequested=false`.

## Prevention

Read the live parent object and exact nested path before classifying a compacted write as absent. Correct false absence before any retry.
