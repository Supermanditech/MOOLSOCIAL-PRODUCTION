# UAW C30T Create-draft test hidden-rail assumption — 2026-08-13

## Outcome

The first draft-retention widget test attempted to tap
`screen04-rail-feed` while the full-screen Create composer was open. The
composer intentionally hides the local rail and exposes
`screen04-create-close` instead, so the finder returned zero widgets.

The test run is rejected despite preceding passes. The implementation failure
was not established.

## Permanent prevention

Exercise the actual visible user path: close the composer with its owned close
control, verify Feed, and reopen through the Feed `Create a post` action. Never
assume controls outside a full-screen composer remain mounted or visible.
