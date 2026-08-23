# C25G bare ripgrep no-match exit recurrence

Date: 2026-08-09

## Rejection

A read-only registry-discovery command used a bare optional ripgrep match. The
legitimate no-match exit code made the overall command fail and discarded a
clean diagnostic outcome.

## Recovery

The retry used a bounded JSON read and made no product, machine or device
mutation.

## Permanent rule

Optional discovery uses `Select-String` or explicit handling for ripgrep exit
code 1. Unhandled nonzero status is reserved for required-match gates.
