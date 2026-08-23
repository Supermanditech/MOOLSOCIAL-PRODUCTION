# REG2689 — C34G OPPO authorization property was mistyped

## Outcome

The in-memory reset used `oneInPlaceOppoPlayUpdateApprovedAfterPostbuildGate`; the existing property is `oneInPlaceOppoPlayUpdateApprovedAfterPostuploadGate`. The command stopped before either JSON owner was written.

## Prevention

Assert every state-only target property exists and copy its exact name from the parsed owner before assignment. No result from the failed reset is counted.
