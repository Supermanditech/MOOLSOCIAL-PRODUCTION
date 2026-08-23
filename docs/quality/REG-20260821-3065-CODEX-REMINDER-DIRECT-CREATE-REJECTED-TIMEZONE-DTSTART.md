# REG-20260821-3065 Codex reminder direct create rejected timezone DTSTART

## Observed failure

The first Codex heartbeat reminder used direct create with a timezone-anchored
DTSTART. The automation service rejected it and instructed anchored reminders
to use suggested-create mode. No reminder was created.

## Root cause

The invocation selected the immediate-create mode for an intentionally anchored
one-time wall-clock reminder.

## Impact

- no duplicate or incorrect reminder exists;
- no repository, Play, build, OPPO or provider state changed.

## Prevention and authorized retry

Use suggested-create for timezone-specific DTSTART semantics, keep the exact
Asia/Kolkata activation time, and verify the returned automation state before
claiming success.
