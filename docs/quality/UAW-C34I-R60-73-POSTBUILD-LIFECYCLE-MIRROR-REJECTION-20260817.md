# C34I r60.73 postbuild lifecycle-mirror rejection

Date: 2026-08-17 IST

C34I r60.73 / `2026081373` built exactly once. The retained AAB has SHA-256
`FDC10D458B003280E78BBF3B11519352406ABD90AF7412204C632F38E73DAA4E`
and 94,797,571 bytes. Compilation, package/version proof, signer proof,
Crashlytics build-ID proof, Google-app-ID resource proof, split/arm64 proof and
sealed provenance completed without exposing a secret value to Codex.

The generic build wrapper consumed the aggregate build authority but did not
consume the matching detailed build authority. The immutable postbuild gate
detected this detailed/aggregate parity mismatch and failed closed; the founder
launcher truthfully reported that no success was claimed.

The permanent C34I truth is `1/0/0/0`. No Play upload, Internal Testing
activation, OPPO update or device acceptance occurred. The AAB is retained as
historical evidence only and cannot be repaired, rebuilt, uploaded, promoted
or used to claim postbuild qualification. REG2715 requires a fully fixture-
tested generic lifecycle transition owner before any successor AAB.
