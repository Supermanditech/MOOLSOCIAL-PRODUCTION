# C34H stale OPPO mirror handle captured the wrong Windows surface

Date: 2026-08-17 IST

## Mistake

After the founder manually updated and opened MoolSocial, the previously held
computer-control window handle returned a screenshot of a different Windows
surface rather than the OPPO mirror. No input was sent from that observation.
The handle and all prior coordinates were discarded, the running scrcpy app
was re-listed, and a freshly rehydrated exact `CPH2375` window restored the
device view.

## Root cause

The workflow assumed a pre-handoff window binding remained safe after manual
user interaction instead of reselecting the returned live window before
capture.

## Permanent prevention

After any founder/device takeover, re-list the exact mirroring app, require
one returned `CPH2375` window, rehydrate it, activate it, and capture a fresh
state before reading or acting. A mismatched capture invalidates every prior
screenshot id, coordinate and element index.
