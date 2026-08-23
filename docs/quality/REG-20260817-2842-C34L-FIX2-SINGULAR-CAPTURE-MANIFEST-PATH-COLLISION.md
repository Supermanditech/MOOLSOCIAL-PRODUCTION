# REG2842 — C34L FIX2 singular capture-manifest path collision

Date: 17 August 2026
State: registered pre-mutation cross-owner contract rejection

## Mistake

The initial FIX2 capture-artifact contract assigned every evidence type the same
immutable path, `<evidenceRoot>/captures/attempt-N/capture-manifest.json`.
Play, OPPO, and journey evidence are produced at different lifecycle preimages
with different exact role sets, producer/session identities, and capture
schemas, so the combined chain cannot truthfully retain all three at one
immutable owner. The incompatibility was found before producer/OPPO mutation.

## Prevention

Version the contract to exact per-kind directories:
`.../attempt-N/play/`, `.../attempt-N/oppo/`, and
`.../attempt-N/journey/`. Each kind owns its own `capture-manifest.json` and
fixed artifacts; journey row artifacts live under its own `journeys/` child.
Every validator must bind the revised contract hash and reject cross-kind aliasing.
