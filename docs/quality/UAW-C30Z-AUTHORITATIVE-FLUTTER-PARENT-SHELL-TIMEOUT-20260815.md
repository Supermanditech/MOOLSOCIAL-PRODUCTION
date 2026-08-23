# C30Z authoritative Flutter parent-shell timeout

Date: 2026-08-15
Regression: `REG-20260815-2225-C30Z-AUTHORITATIVE-FLUTTER-PARENT-SHELL-TIMEOUT`
Status: resolved; long-lived cell emitted the complete counted summary

## Finding

The authoritative 59-file Flutter JSON audit was launched with a 60-second
parent shell timeout. The shell returned exit 124 before the wrapper emitted
its bounded passed/skipped/failed/native-exit summary. The attempt is zero
qualification evidence.

## Prevention

The exact immutable manifest and expected counts are rerun with a long-lived
process cell and short wait yields. Only the wrapper's final bounded summary
and native exit are accepted. No source, build, Play, OPPO, provider,
credential or external-service state changed.
