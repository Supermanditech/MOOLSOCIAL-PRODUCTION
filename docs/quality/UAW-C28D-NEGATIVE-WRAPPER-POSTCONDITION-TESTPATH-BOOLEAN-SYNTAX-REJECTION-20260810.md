# C28D negative-wrapper postcondition syntax rejection

- Date: 2026-08-10
- Phase: closed-authority wrapper self-test
- Passed first: the wrapper reached scope and premium-motion gates, then
  rejected exactly because APK machine state remained the consumed C27F state;
  Flutter build did not start.
- Rejection: the following verification expression placed `-or` inside one
  `Test-Path` invocation, so PowerShell treated the second `-LiteralPath` as a
  duplicate parameter.
- Product/device effect: no APK, provenance, install or OPPO mutation occurred.
- Root cause: two path predicates were not parenthesized as separate cmdlet
  calls.
- Prevention: evaluate `(Test-Path pathA) -or (Test-Path pathB)` as two explicit
  expressions and require both reserved outputs absent before sealing the
  expected negative result.
