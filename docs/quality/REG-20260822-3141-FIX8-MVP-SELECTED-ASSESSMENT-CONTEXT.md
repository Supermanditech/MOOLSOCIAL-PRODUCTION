# REG-20260822-3141 — FIX8 MVP selected-assessment context rejection

Date: 22 August 2026

State: registered; zero scope-state mutation

The first FIX8 MVP-selection patch combined the current-ticket scalar and a
complete selected-assessment replacement. One remembered assessment line did
not match the live JSON byte context, so `apply_patch` rejected the operation
atomically. Readback confirmed that current ticket, selected assessment and
top-level ticket all remain FIX5.

No source, test, scope authorization, build, APK, OPPO, provider, account,
email/SMS, Play or cloud state changed from the rejected patch.

Root cause: the replacement used a rendered excerpt as though every long line
were copied byte-exactly from the current state owner.

Prevention: patch the unique current-ticket scalar independently, then replace
the selected assessment through smaller freshly read exact field/array hunks.
Parse and project each accepted transition before touching the next subtree.
