# UAW C30T preserved-AAB guessed-filename rejection — 2026-08-13

## Outcome

The release-state readback reconstructed the preserved C30S AAB name as
`moolsocial-r60.44-c30s.aab`. That file does not exist. The durable C30S machine
state identifies the exact artifact as
`MoolSocial-1.0.0-r60.44-2026081244-release.aab`.

The failed combined readback is rejected even though its plugin predicates had
passed. No file was modified by the lookup.

## Permanent prevention

Resolve preserved release artifacts exclusively from the predecessor machine
state `buildResult.artifactPath`, and compare its stored byte length and SHA-256.
Never infer a release artifact filename from a ticket or evidence-directory
name.
