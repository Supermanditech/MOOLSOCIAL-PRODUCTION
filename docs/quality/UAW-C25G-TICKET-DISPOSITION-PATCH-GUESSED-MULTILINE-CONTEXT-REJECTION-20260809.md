# C25G disposition patch guessed multiline context

Date: 2026-08-09

## Rejection

The ticket's reuse inventory is stored as compact JSON on one line. A correction
patch derived from pretty-printed object output expected a multiline array and
was rejected without applying.

## Recovery

The raw target line was read before one exact-context retry.

## Permanent rule

Converted JSON describes values; only raw file text supplies patch context.
