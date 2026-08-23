# C30T Chat message-load error thread-isolation finding — 2026-08-13

## Finding

Chat stored every message-list failure in one global `errorMessage`. A delayed
failure from a conversation that was no longer visible could therefore render
the global failure banner over the newly opened, successfully loaded thread.

## Correction

Message-load errors are now owned by thread ID. Starting or succeeding a load
clears only that thread's error, and the thread body reads only its own failure.
Send and inbox errors retain their existing global ownership.

## Verification

The delayed route-change widget test successfully loads the new thread, then
fails the old request with private exception text. The new message remains
visible, no failure banner appears, the old thread owns the fixed sanitized
error and no private detail is exposed. The production Chat suite passed `4`
tests. Evidence SHA-256:
`5FD793862990172731AFBB43314FD24703583A6B87D42D50508E8A0F282CA99A`.

No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
