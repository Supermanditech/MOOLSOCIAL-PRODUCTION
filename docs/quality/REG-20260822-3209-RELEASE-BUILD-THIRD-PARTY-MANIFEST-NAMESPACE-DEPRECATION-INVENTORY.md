# REG-20260822-3209 — Release build third-party manifest namespace deprecation inventory

## Incident

The r60.81 release build emitted obsolete source-manifest `package` namespace
warnings for 14 third-party Android plugins. These warnings were discovered
during Gradle packaging rather than blocked during preflight.

## Impact

- Current APK assembly exit: `0`
- Current artifact qualification affected: `warning inventory only`
- Additional APK or AAB builds: `0`
- OPPO actions: `0`

## Root cause

The resolved third-party plugin set still contains Android manifests with
`package` attributes that AGP ignores, and no prebuild inventory gate blocked
future packaging while that migration debt remained.

## Permanent prevention

Inventory resolved Android plugin manifests before every APK or AAB build and
block packaging while any obsolete package namespace declaration remains.
Migrate only through repository dependency upgrades or controlled overrides;
never patch the machine Pub cache in place.
