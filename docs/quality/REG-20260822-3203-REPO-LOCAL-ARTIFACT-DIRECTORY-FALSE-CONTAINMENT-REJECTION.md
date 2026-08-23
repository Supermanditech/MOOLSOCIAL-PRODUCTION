# REG-20260822-3203 — Repo-local artifact directory false containment rejection

## Incident

The authorized r60.81 device-review wrapper rejected its intended
repository-local artifact directory as outside the production repository. The
exception occurred before Gradle started.

## Impact

- Fresh build authorization consumed: `false`
- Gradle build actions: `0`
- APKs or AABs produced: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The wrapper passed a repository-relative artifact target directly to
`IO.Path.GetFullPath`, which resolves against the process-level .NET current
directory. That directory can remain `C:\WINDOWS\system32` even when the
PowerShell location and prompt are inside the repository.

## Permanent prevention

Centralize canonical descendant-path validation. Test existing and
not-yet-created repository-local targets, exact-root rejection where required,
path traversal, sibling prefix collision, and absolute outside targets. Require
the same verified helper in every APK and AAB artifact-producing wrapper before
any build action.
