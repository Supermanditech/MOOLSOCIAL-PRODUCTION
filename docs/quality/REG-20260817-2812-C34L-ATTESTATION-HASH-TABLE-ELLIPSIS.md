# REG2812 — C34L attestation hash-table ellipsis

Date: 17 August 2026
State: registered read-only final-evidence formatting defect; zero mutation

## Mistake

The attestation agent's scoped four-owner hash read piped results through
`Format-Table -AutoSize`, which ellipsized every SHA-256 value. The result is
not admissible as exact owner identity evidence. No repository or external
state changed and no hash retry followed.

## Prevention

Emit each final owner identity as one plain
`relativePath=FULL_SHA256;bytes=N;lines=N` record without table formatting or
width-dependent rendering.
