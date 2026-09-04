# Android share contract correction

Ticket: UAW-CODEX-ANDROID-SHARE-CONTRACT-FIX-V1-20260905

Parent: `477a0084f1264231e69cb54a4eaab6358f6bdd14`

The pre-APK source audit found two regressions in the parent implementation:

- The app replaced the registered share_plus method handler and reported an empty string after every activity resume. share_plus interprets this as dismissed, including successful destination selection.
- The replacement passed arbitrary file paths directly to the provider. The plugin provider allows only `cache/share_plus/`; the upstream implementation first copies attachments into that directory.

Restore the existing registered plugin and its result/file behavior. Preserve the parent commit as evidence. This correction does not claim to resolve the original Redmi Gmail return defect: it still needs a task-stack reproduction on the review device. The earlier OPPO check did not reproduce that specific defect.

Functional owners are only MainActivity.kt and platform_configuration_test.dart. Tests must exercise the real Dart share API response contract and retain the existing Android activity/provider delegation checks. No manifest, Buy source, SDK, dependency, APK, account or device change belongs to this correction.

Qualification evidence is retained outside managed worktrees at `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/android-share-contract-fix/`.

## Source qualification

Two separate `flutter test --no-pub test/platform_configuration_test.dart --reporter expanded --concurrency=1` runs passed all 13 tests each. Both complete stdout hashes: D62CC994F2F849EDE2835A1A31DDFD80FF69DAFE670ADA8B806618D05564CF64. `flutter analyze --no-pub` reported zero issues; stdout hash 0F44D55F483489DDACD80A3400B756C2CDFDB46F9BE24F875E8409C49A32298C. All stderr files were empty. The retained results.json records exact commands, UTC start/end and exit codes; SHA-256 D76EE922D44DADCD6CF7A571ADE03835401D14B71A96F46CAD857AA214DDE0ED.

REG-20260905-4488 records the actual source regression and correction. Historical evidence-reference support is carried forward from the already sealed Codex child records without importing their product code. The existing checker permits this exact branch/task/ticket/bootstrap to seal these support owners once with the source correction; it cannot authorize another implementation commit or another branch/owner. No general lane or root changes are introduced.

Founder now directs independent Codex and Cursor lanes. This commit remains a Codex input for its candidate and the next integration; it is not a new shared baseline. Native Gmail task return remains open until the exact device journey is reproduced. No recipient delivery, external account operation, APK or device result is claimed from channel-contract tests.
