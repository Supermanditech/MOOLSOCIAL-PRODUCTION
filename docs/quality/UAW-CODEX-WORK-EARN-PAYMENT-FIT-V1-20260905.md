# Earn Today payment-row fit correction

Ticket: UAW-CODEX-WORK-EARN-PAYMENT-FIT-V1-20260905.

Base: f94cfd4752dd73b58a69568475803d6cf25cb8d0.

Confirmed pre-APK defect: at 320 logical pixels and 130% text, a payment-amount Text in the opportunity-card Row is unconstrained and makes the Row overflow horizontally by 70 pixels. Both the production-themed app and isolated Work screen reproduce it. The overflow also surfaces while profile Help/Privacy/Security tests return through Earn Today; those profile pages must not be patched for this Work defect.

Source owner: apps/mobile/lib/features/work/screens/work_earn_screens.dart.

Regression owner: apps/mobile/test/ui_v2/work/work_main_v2_test.dart.

Bound the payment amount to its share of the Row, allow meaningful wrapping and retain the original typography, colour, monthly-first hierarchy and actions. Do not remove payment facts, shrink tap targets or silence rendering exceptions. Cover both initially visible and later opportunity cards at compact/large-text sizes, then the connected Work and global Profile returns.

Reproduction: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/boundary-probe-attempt1.log, SHA-256 8F63AD30DD5A18A4D01B3ED7A1934066937A329AD84F50D29FF15E46608A915F.

No Buy, Chat, Profile, backend, APK, device, historical golden or approved baseline edit belongs to this child. Local qualification is not OPPO acceptance.

## Implemented correction and local qualification

Both payment columns now share bounded width (monthly 3, task amount 2). The task amount wraps without truncation; font sizes, payment facts, card design, routes and actions remain unchanged. The added tests scroll through all 15 opportunities at 320 px / 130%, 320 px / 140%, 390 px / 140% and 430 px / 140%, checking exact payment content, non-overlap, card containment and retained Apply controls.

All evidence below is under `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/`:

- `work-payment-fit-attempt1.log`: 19 passed, 0 failed; SHA-256 `C6C0EEC6A614B8E54A3869E5AA81C2AFA52DF077622B2E8383CE9B23B55B79DF`.
- `work-payment-connected-attempt1.log`: 164 passed, 70 existing skipped captures, 0 failed; SHA-256 `582D6A1914DEA8F28B58B58E55D29408D1D0458B7DFE63A23E77941AFCDC87D7`. Exact owners: Work main V2, opportunity home C24G, vertical slice, workspace layout safety, production gateway, store atomic operations, global Help, Privacy and Security. All five formerly overflowing Profile-return cases pass without changing Profile source.
- `work-payment-fit-analysis.log`: full `flutter analyze --no-pub`, zero issues; SHA-256 `53B1AFFE3D78D11178C0C4425B666DEFF87D86B144704294723DDA5F0F1DA93F`.

Toolchain: Flutter 3.44.6, Dart 3.12.2. Tests use `--no-pub --reporter expanded --concurrency=1`. No protected golden was changed. Support is limited to registering the confirmed overflow, retaining unavailable historical UI-evidence provenance and binding these exact support owners for this single child commit; general lane roots and memory-checker behavior are unchanged.

Founder sequence clarified on 5 September: the combined corrected, regression-qualified, clean and remote-equal baseline is handed to Cursor for Redmi UAT BEFORE Codex OPPO testing. OPPO qualification is explicitly pending at that source handoff. This child alone is not the combined handoff baseline; outstanding shared/platform and Cursor-owner audit findings still require closure or explicit coordination.
