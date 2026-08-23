# C09 first host-gate working-directory failure

Date: 7 August 2026

The first combined C09 host-gate invocation used
`apps/mobile` as its working directory for Flutter, but also referenced the
repository-level PowerShell gates as relative `scripts/...` paths. PowerShell
could not resolve the first gate and stopped before any contract or Flutter
test executed. No source, runtime, build or device state changed.

REG-20260807-133 registers the recurrence. Repository gates now use absolute
canonical repository paths, while Flutter commands alone use the exact mobile
package working directory.
