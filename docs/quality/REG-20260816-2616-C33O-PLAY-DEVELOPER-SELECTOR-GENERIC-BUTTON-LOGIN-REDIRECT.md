# REG-20260816-2616 — Play developer-selector generic button was login

Date: 2026-08-16 IST

During the read-only C33O pre-seal Play Console check, both available browser
surfaces reached the developer selector without exposing a MoolSocial app or
Internal Testing route. The Chrome page had one generic button. Clicking that
role-only control navigated to `accounts.google.com`; it was a login boundary,
not a uniquely proved developer-account selection. No form was filled, no
credential was accessed, and no Play draft, upload, activation or other write
occurred.

The correction is to count no live browser-workflow qualification. Never click
a generic selector control by role/count alone. The founder must complete the
visible Google sign-in and, if presented, choose the intended developer account.
Only then may Codex resume from the visible signed-in Play Console and require
semantic `MoolSocial` and `Internal testing` evidence before the C33O source
seal. No account identifier, credential or session store may be inspected.
