# REG3192 — source seal preceded lifecycle-gate update

## Finding

The first repair manifest (`20260822-04`) was sealed before the existing C34P
FIX5 lifecycle checker was extended to recognize the truthful
repair-qualified/new-authority-pending state. Because that checker is a sealed
build input, the subsequent checker edit invalidated the new manifest.

## Root cause

The transition checker was treated as post-seal state bookkeeping even though
the manifest generator correctly includes it as an executable build-control
owner.

## Permanent prevention

Complete all executable gate and lifecycle-checker edits before generating a
source seal. After sealing, independently hash every row against its live owner
and permanently reject any seal with a changed owner; never overwrite or reuse
the invalidated output.

## Action truth

- Invalidated repair seal: `20260822-04`; never reusable.
- APK build count remains `1` (the earlier failed action).
- APK produced: `0`.
- OPPO install/update count: `0`.
- No APK, install, Play, Production, provider-login, email, SMS or SQL Connect
  action occurred.
