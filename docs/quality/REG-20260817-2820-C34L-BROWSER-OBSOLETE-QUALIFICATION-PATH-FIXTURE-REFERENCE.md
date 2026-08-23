# REG2820 — C34L browser obsolete qualification-path fixture reference

Date: 17 August 2026
State: registered fresh PS7 blocker fixture failure; zero external action

## Mistake

The fresh PS7 blocker run passed the raw-nonce boundary, then StrictMode found
unset `$expectedBrowserQualificationPath`. The 23-field schema repair removed
the obsolete production qualification constants but left one later traversal
negative assigning that deleted variable to `ValidationBrowserProofPath`.
Unique fixture cleanup completed and no external/browser/provider/release/private
action occurred.

## Prevention

After removing an interface field, statically inventory every exact symbol
reference before testing. Preserve traversal coverage with a concrete sibling
fixture-run proof path derived inside the unique fixture root, never with a
removed production-metadata constant.
