# UAW-C34P FIX5 public-auth sideload r60.79 cold-start qualification

## Outcome

r60.79 is the distinct REG3085 cold-start successor. It renders a named
Flutter-owned bootstrap frame before Firebase or any other platform bootstrap,
bounds every pre-app asynchronous stage, and retains truthful recovery.

## Qualification

- focused startup/auth: 35/35;
- two identical affected cycles: 21 suites, 197/197 each;
- Flutter analysis: no issues;
- source files: 287;
- source SHA-256:
  `375AE203A5E484361A837876A4F8253489F9726EF5CE49F540F3F84638015EFE`;
- r60.77 update-screen rejection preserved;
- r60.78 blank-frame rejection preserved.

## Enforced production rule

No authentication candidate may advance from source/build qualification to
method testing until the installed checksum-matched APK cold-starts to a named
Flutter-owned frame, reports no fatal/ANR marker and retains a screenshot. A
unit or source pass cannot substitute for that device gate.

## Held boundaries

- no Play upload or Production promotion;
- no OPPO update until the built artifact is independently qualified and the
  founder confirms the exact in-place update;
- no private login, real email or real SMS without method-specific action-time
  confirmation.

## Built artifact

- bytes: 101,589,372;
- SHA-256: `E7495D126FBE4B20C547EF4F7F0C9B7E8EA941EF11644D0735D900DF6B9F02C4`;
- signature, signer, package, version and provenance: qualified;
- debuggable: false;
- in-place update possible without uninstall or data clear;
- Play upload: not performed.
