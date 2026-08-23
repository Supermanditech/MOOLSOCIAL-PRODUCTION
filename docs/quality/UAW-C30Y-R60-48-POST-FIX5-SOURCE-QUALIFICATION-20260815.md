# UAW C30Y r60.48 post-FIX5 source qualification

Date: 2026-08-15
Ticket: `UAW-C30Y-R60-48-SUCCESSOR-AAB-PLAY-INTERNAL-OPPO-ACCEPTANCE`
Repair ticket: `UAW-C30Y-FIX5-FLUTTER-JSON-EVENT-SHAPE-CLASSIFIER-TRUTH`
State: two identical current-source cycles qualified; founder prompt required

## Canonical source seal

- Path: `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/source-manifest-c30y-post-fix5.txt`
- Files: 1,135
- SHA-256: `54645062FBAA0233759B0F3C6F5C1C4C539D1A322DE7E7FA14629ECF3EDCDED4`
- Focused manifest: 59 files, SHA-256
  `6F6C9C7AE281510F156CA4869854A37D0424338F88839D23F64C8A1114F47147`

## Two qualifying cycles

Both cycles passed and are substantively equal:

- Flutter: 417 authored passes, 3 declared skips, 0 failures, 0 error
  events, 0 non-JSON lines and 0 untyped JSON objects.
- Whole-mobile analyzer: clean.
- Backend: typecheck passed with retained output/exit evidence; 528/528 tests,
  0 failures; 53 compiled test files.
- Hosting: 8/8 tests, 0 failures.
- Release actions: build/upload/install `0/0/0`.
- New issues/defects inside either successful cycle: `0/0`.
- Static release controls and FIX5 classifier passed under PowerShell 7 and
  Windows PowerShell; both cycle summaries passed the evidence binder under
  both hosts.

Evidence:

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-cycle-01-attempt-07-summary.json`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-cycle-02-attempt-05-summary.json`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-post-reg2206-two-cycle-substantive-compare.log`

## Preserved failed evidence

Earlier partials, failed binders and final-replay failures remain preserved and
are not qualification inputs. The final pair above was run only after REG-2205
and REG-2206 registration, with regression memory at 2,177 entries and 1,268
implementation-applicable entries.

## Authority boundary

The founder's existing exact authorization makes one r60.48 AAB, one Internal
Testing upload/activation and one in-place OPPO Play update available only
through the qualified wrappers and later postbuild/postupload/postinstall
gates. MVP scope build authority is now true, while MVP device-install
authority remains false until the separately qualified postupload/preinstall
transition. Hidden upload password, Firebase Android API key and Google OAuth
server client ID remain founder-only. No other track, ADB install/sideload,
deployment, email/quota submission, funds or credential access is authorized.
