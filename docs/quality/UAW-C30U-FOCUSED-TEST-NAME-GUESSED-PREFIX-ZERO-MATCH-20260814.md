# C30U focused test-name guessed-prefix zero match

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

After the focused analyzer passed, the diagnostic attempted to locate the four
new tests by an assumed `guest YouTube` test-name prefix. The search returned no
matches and a nonzero shell result. It is rejected as test-name evidence and no
test was started.

## Root cause

The test-name prefix was reconstructed from remembered behavior rather than
derived from the freshly formatted current test owner. The expected-empty
outcome was also not normalized explicitly.

## Prevention

Read the exact current test owner with a no-match-safe literal `YouTube`
projection, capture only matched line numbers/text, and copy each complete test
name from that output. Never guess a named-test prefix or leave a diagnostic
zero match unclassified.

## Release effect

The formatter completed and the focused analyzer passed with no issues. No test
was run by the failed lookup. No AAB, upload, Play activation, installation or
OPPO mutation occurred; all release counts remain zero.

## Exact current names resolved

The no-match-safe current-owner projection and bounded source windows resolved
these four complete names:

- `guest YouTube action explains the two account steps first`
- `guest can cancel YouTube explanation without entering auth`
- `guest can dismiss YouTube explanation through the barrier`
- `guest YouTube continuation enters exact MoolSocial auth state`

Only these literal names may be supplied to the bounded focused invocations.
