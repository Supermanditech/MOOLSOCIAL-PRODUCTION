# Earn Today payment-row fit correction

Ticket: UAW-CODEX-WORK-EARN-PAYMENT-FIT-V1-20260905.

Base: f94cfd4752dd73b58a69568475803d6cf25cb8d0.

Confirmed pre-APK defect: at 320 logical pixels and 130% text, a payment-amount Text in the opportunity-card Row is unconstrained and makes the Row overflow horizontally by 70 pixels. Both the production-themed app and isolated Work screen reproduce it. The overflow also surfaces while profile Help/Privacy/Security tests return through Earn Today; those profile pages must not be patched for this Work defect.

Source owner: apps/mobile/lib/features/work/screens/work_earn_screens.dart.

Regression owner: apps/mobile/test/ui_v2/work/work_main_v2_test.dart.

Bound the payment amount to its share of the Row, allow meaningful wrapping and retain the original typography, colour, monthly-first hierarchy and actions. Do not remove payment facts, shrink tap targets or silence rendering exceptions. Cover both initially visible and later opportunity cards at compact/large-text sizes, then the connected Work and global Profile returns.

Reproduction: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/boundary-probe-attempt1.log, SHA-256 8F63AD30DD5A18A4D01B3ED7A1934066937A329AD84F50D29FF15E46608A915F.

No Buy, Chat, Profile, backend, APK, device, historical golden or approved baseline edit belongs to this child. Local qualification is not OPPO acceptance.
