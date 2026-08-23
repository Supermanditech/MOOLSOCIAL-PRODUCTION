# C34H Play upload direct-file-input exact-one assumption

Date: 2026-08-17 IST

## Mistake

On the prepared Internal Testing draft, browser control required exactly one
raw `input[type=file]`. Play exposed two file inputs and the custom check
stopped before clicking or selecting a file. No AAB was transmitted by that
attempt. The mutable upload authority had been marked consumed too early and
was restored only after the no-action boundary was proved.

## Root cause

The workflow assumed Play's hidden DOM file-input count was a stable public
contract and consumed authority before verifying the visible upload control.

## Permanent prevention

Inspect the visible Upload button and file-input count before consuming
authority. When Play exposes multiple hidden inputs, use the one visible
Upload control with the documented chooser flow. Consume authority only
immediately before the first real file-selection action and never infer an
upload from a chooser-shape check.
