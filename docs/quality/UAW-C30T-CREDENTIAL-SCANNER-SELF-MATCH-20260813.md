# C30T credential-scanner self-match — 2026-08-13

## Failure

Qualification cycle 1 reached static release readiness after a successful no-artifact release config preflight. The credential scan then matched the gate scripts' own `AIza` detector definitions and reported seven source files.

## Impact

- No credential value was read or printed.
- No AAB was built and build authority remains unused.
- The immutable failed qualification-attempt evidence is retained.
- OPPO r60.44 remains installed without data clear or uninstall.

## Prevention

Product, Android and backend source remain fully scanned. Gate-script content must exclude only the literal detector-definition lines before applying the same credential pattern; all other matches continue to fail closed.

## Correction

The subsequent filename-only inventory proved the seven matches were not gate scripts. They were existing backend security/redaction test files containing credential-shaped fixtures. The corrected classification and prevention are recorded in `UAW-C30T-CREDENTIAL-HIT-CAUSE-MISCLASSIFICATION-20260813.md`; this original mistaken diagnosis remains retained.
