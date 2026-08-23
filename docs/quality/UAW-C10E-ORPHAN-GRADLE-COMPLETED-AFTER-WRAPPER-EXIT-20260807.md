# C10E orphan Gradle completion after wrapper exit

- Registry: `REG-20260807-234-C10E-ORPHAN-GRADLE-COMPLETED-AFTER-WRAPPER-EXIT`
- State: corrected; exact generated output under validation.

The first post-timeout reconciliation observed that the wrapper and Flutter
processes had exited and that the reserved artifact/provenance did not exist.
It prematurely classified the candidate as producing no build output. A later
exact output read proved the original Gradle descendant completed at
19:04:20 IST and wrote a new generated `app-profile.apk`: 134,427,321 bytes,
SHA-256 `666810333E99531592145ADA8B04EFDE608C796C39BB21DE3DEF78269993A947`.

No second wrapper or Flutter build was invoked. The generated output is not
accepted merely because it exists: package, version, signature, source drift
and exact single-build lineage must pass before it can be copied to the
reserved evidence path or installed. Future timeout reconciliation watches the
complete descendant tree and requires a quiet interval plus output timestamp
stability before declaring a terminal no-artifact result.
