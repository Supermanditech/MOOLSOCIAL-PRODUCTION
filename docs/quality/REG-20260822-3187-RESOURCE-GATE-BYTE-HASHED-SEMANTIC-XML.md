# REG3187 - Resource gate byte-hashed semantic XML

## Classification

Registered new static-gate false rejection before Gradle link preflight, with
zero new APK, install or device action.

## Evidence

The base and restored v21 launch-background XML owners express the same
layer-list and `@color/mool_navy` item, but their line-ending serialization
differs. The first gate compared raw SHA-256 hashes and rejected this harmless
byte difference. The public-auth control and failed-build lifecycle gates were
green.

## Prevention

Validate both files as XML and compare normalized XML semantics rather than raw
line-ending bytes. Retain exact packaged-resource equality against the base
owner only where Gradle copies that source file byte-for-byte.
