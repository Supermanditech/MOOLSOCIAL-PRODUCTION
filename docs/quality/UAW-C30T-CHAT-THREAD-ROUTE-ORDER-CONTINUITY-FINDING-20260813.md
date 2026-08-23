# C30T Chat thread route-order continuity finding — 2026-08-13

## Finding

The Chat thread screen loaded only from `initState`. If router navigation reused
that State with a different thread ID while the first message request was
pending, the new thread was not loaded. The older callback also owned the later
read-state action without checking that its route remained current.

## Correction

The screen now reloads on thread/session updates, gives each load a request
generation, validates session and thread identity after every await, and marks
read only after the current thread's message load succeeds.

## Verification

A delayed two-thread widget test switches routes before the old response. The
new message renders and becomes read; the old thread remains unread, and its
late message never replaces the current screen. The production Chat suite
passed `4` tests. Evidence SHA-256:
`5FD793862990172731AFBB43314FD24703583A6B87D42D50508E8A0F282CA99A`.

No backend/provider, AAB, Play, OPPO, Hosting or communication action occurred.
