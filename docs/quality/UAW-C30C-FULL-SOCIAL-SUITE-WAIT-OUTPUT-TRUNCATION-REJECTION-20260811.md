# C30C full Social suite wait-output truncation rejection

- Regression: `REG-20260811-1367-C30C-FULL-SOCIAL-SUITE-WAIT-OUTPUT-TRUNCATION-REJECTION`
- Date: 2026-08-11
- Rejected evidence: the first full Social Flutter-suite wait exceeded the available model context and was truncated.
- Consequence: its completion state and result are not accepted or reported.
- Prevention: rerun the complete suite with all output retained in a fresh evidence log, then expose only the exit code, final bounded lines, file size and SHA-256.
