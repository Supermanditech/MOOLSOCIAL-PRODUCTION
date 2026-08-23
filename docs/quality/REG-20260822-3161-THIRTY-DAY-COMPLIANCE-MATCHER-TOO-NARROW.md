# REG3161 - 30-day compliance matcher too narrow

## Classification

Registered false absence with zero external mutation.

## Evidence

The matcher required `30` immediately followed by `days` and returned false for both live content and the qualified source. It was therefore invalid for classifying Hosting drift.

## Prevention

Prove one bounded flexible matcher against current source, then apply the identical matcher live and report only source/live booleans plus HTTP status.
