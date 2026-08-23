# C30Q OPPO Play-link combined shell policy rejection

Date: 2026-08-12

## Mistake

The first OPPO Play-link navigation attempt combined an Android intent write, a wait, activity inspection and UIAutomator XML capture in one nested shell command. The local command policy rejected the complete command before execution.

## Impact

- The OPPO remained on its prior screen.
- No link opened, app installed, package changed, data cleared, credential exposed, or provider state changed.

## Permanent prevention

Keep the authorized Android intent action in one minimal command. Run subsequent activity and visible-UI inspections as separate read-only commands. Do not combine device mutation and evidence collection into one nested shell invocation.
