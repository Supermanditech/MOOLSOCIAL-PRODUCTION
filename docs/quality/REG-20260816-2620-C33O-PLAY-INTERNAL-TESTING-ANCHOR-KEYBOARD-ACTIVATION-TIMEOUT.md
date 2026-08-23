# REG-20260816-2620 — Internal Testing anchor keyboard activation timed out

Date: 2026-08-16 IST

The final permitted browser-control attempt used keyboard `Enter` activation
on the exact unique visible Internal Testing anchor after REG2619 prohibited
more coordinates. The control again remained visible and enabled but the
automation transport timed out, leaving the MoolSocial dashboard unchanged.
No release, draft, file attachment, upload, activation or other Play write
occurred.

The correction is to count no Internal Testing route qualification and stop
all Codex browser-control retries. Leave the signed-in MoolSocial dashboard
open with Testing expanded. The founder must click the visible
`Internal testing` navigation item, then Codex may perform a read-only route
and heading verification without further navigation attempts.
