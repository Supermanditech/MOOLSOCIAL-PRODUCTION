# UAW C33E Social public-card source-range output truncation

Date: 2026-08-15
Regression: `REG-20260815-2346-C33E-SOCIAL-PUBLIC-CARD-SOURCE-RANGE-OUTPUT-TRUNCATED`

## Failure

A read-only audit requested lines 1–135 of the dense Social public-content owner in one tool result. The result was truncated, so it cannot be used as complete source evidence.

## Root cause and recovery

The range was too large for a dense Flutter widget source. The partial result is discarded. Any retry must use non-overlapping windows of at most 60 lines around exact symbols, with each result accepted only when it completes without truncation.

No source, ticket, build, provider, device or release state changed.
