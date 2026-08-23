# REG3173 - FIX8 MVP authorization combined long-context mismatch

## Classification

Registered atomic MVP patch rejection with build and install gates still closed.

## Evidence

The first MVP authorization patch combined several exact scalar transitions
with a long historical `approvalState` replacement. That long line was not
byte-identical to the projected context, so `apply_patch` rejected the entire
MVP patch. The FIX8 ticket records founder authority, but MVP build/install
booleans and the APK gate remain unchanged and therefore prevent execution.

## Prevention

Project each live scalar line and update the build flags, scopes, selected
ticket hash and narrative state in separate bounded hunks. Do not use a long
historical approval string as a multi-hunk anchor.
