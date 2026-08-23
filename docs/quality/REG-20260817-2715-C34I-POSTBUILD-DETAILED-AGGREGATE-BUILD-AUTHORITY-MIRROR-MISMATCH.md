# REG2715 — C34I postbuild detailed/aggregate build-authority mismatch

Date: 2026-08-17 IST

The one authorized C34I r60.73 AAB invocation completed compilation, retained
the sealed bundle and wrote matching provenance. The generic wrapper then set
aggregate `releaseAuthorities.build` to `consumed` but left detailed
`releaseAuthorities.build` at `available_once`. The postbuild parity gate
correctly rejected the mismatch and the founder launcher reported no success.

The authoritative action counts are `1/0/0/0`. No Play upload, Internal
Testing activation, OPPO update, device acceptance, deployment, email or SMS
occurred. Known founder-input transient files were absent after cleanup, and no
secret or private value was inspected or retained by Codex.

C34I is permanently non-reusable. It must not be rebuilt, repaired, uploaded
or promoted. Before a successor build, the generic wrapper must use one
executable transition owner that advances every detailed and aggregate mirror
atomically and passes positive plus fail-closed fixtures for every release
phase on both supported PowerShell hosts.
