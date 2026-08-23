# C30T missing-search-hit negative line window

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1887-C30T-MISSING-SEARCH-HIT-NEGATIVE-LINE-WINDOW`

## Observation

A local inspection command expected an exact text hit in the package gate. The hit was absent, but the command still derived context offsets and printed negative line labels rather than the intended source window.

## Prevention

Future derived windows require exactly one non-null line hit before arithmetic. When a failure already reports a fixed line, inspection uses a fixed bounded range.

## External effect

None. This was a read-only local inspection failure.
