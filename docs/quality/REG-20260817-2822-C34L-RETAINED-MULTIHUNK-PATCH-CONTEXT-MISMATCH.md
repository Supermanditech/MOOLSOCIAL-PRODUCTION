# REG2822 — C34L retained multihunk patch-context mismatch

Date: 17 August 2026
State: registered atomic patch rejection; zero writes

## Mistake

The first post-REG2821 patch combined three distant checker hunks and used
transcribed expected-label ordering that did not match the live file. The patch
was atomically rejected with zero writes; no retry or mutation followed.

## Prevention

Read fresh exact bounded line slices for each target and apply one separately
anchored patch per local section. Never combine distant negative-fixture edits
under remembered or transcribed context.
