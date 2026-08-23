# REG2719 — C34J dual-host parser positional path binding invalid

Date: 2026-08-17 IST

A redundant nested PowerShell `-Command` parser wrapper did not bind its
relative file argument as intended and reported an invalid parser path. It
stopped before either lifecycle fixture checker executed, so it is zero parser
or fixture evidence.

The wrapper is not retried. PowerShell 7 and Windows PowerShell each execute
the checker directly with `-File`; the checker parses the transition owner
before creating any fixture and its process exit code is authoritative.
