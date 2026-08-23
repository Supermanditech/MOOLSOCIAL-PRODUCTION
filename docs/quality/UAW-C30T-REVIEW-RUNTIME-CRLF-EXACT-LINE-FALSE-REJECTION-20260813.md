# C30T review-runtime CRLF exact-line false rejection

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1884-C30T-REVIEW-RUNTIME-CRLF-EXACT-LINE-FALSE-REJECTION`

## Observation

The new C30T provider wrapper failed in local validation before any file or cloud write, reporting that `YOUTUBE_PUBLIC_DATA_REVIEW_MODE=accepted` was missing even though the common runtime materializer appended it.

## Root cause and correction

The generated runtime uses CRLF line endings, while the wrapper's multiline exact-line regex did not account for the carriage return. The wrapper now normalizes a validation-only copy to LF before checking exact lines. The original generated runtime bytes and their SHA-256 remain unchanged for temporary deployment materialization.

## External effect

None. The wrapper stopped before writing the ignored runtime and before any provider or Hosting deployment.
