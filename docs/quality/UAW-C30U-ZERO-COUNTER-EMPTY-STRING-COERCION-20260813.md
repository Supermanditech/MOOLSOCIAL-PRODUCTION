# C30U zero counter and empty-string coercion

## Incident

The exact C30U state projection returned numeric zero for every pending
release counter. A generic empty-string comparison coerced those zeros and
falsely reported them as missing.

## Root cause

The validator did not check value type before applying string emptiness rules.

## Permanent prevention

Use reference-null validation for every value, whitespace validation only for
strings, and exact integer assertions for release counters. Zero is the
required pre-release value and must remain admissible.

No release or device mutation occurred.
