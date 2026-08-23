# UAW C33J focused Flutter failure output truncation

- Regression: `REG-20260815-2493-C33J-FOCUSED-FLUTTER-FAILURE-OUTPUT-TRUNCATED`
- Failure: the render assertion repeated a long intrinsic-layout stack until the tool output was truncated.
- Impact: the failure cause is established, but the truncated command is not complete test evidence.
- Prevention: retry only after repair, use the compact reporter, and retain bounded exact pass/fail evidence.
