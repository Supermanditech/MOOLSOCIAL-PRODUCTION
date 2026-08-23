# C30J source-hash output truncation rejection

## Finding

A read-only command requested hashes for multiple C30J source and test files in one response. The combined output exceeded the available model context and could not serve as bounded state-transition evidence.

## Disposition

Rejected and registered as `REG-20260812-1398-C30J-SOURCE-HASH-OUTPUT-TRUNCATION-REJECTION`.

## Permanent prevention

Hash only the single artifact required by the current state transition, constrain direct output, and keep broader inventories in sealed repository evidence files rather than returning them inline.
