# Android share contract correction

Ticket: UAW-CODEX-ANDROID-SHARE-CONTRACT-FIX-V1-20260905

Parent: `477a0084f1264231e69cb54a4eaab6358f6bdd14`

The pre-APK source audit found two regressions in the parent implementation:

- The app replaced the registered share_plus method handler and reported an empty string after every activity resume. share_plus interprets this as dismissed, including successful destination selection.
- The replacement passed arbitrary file paths directly to the provider. The plugin provider allows only `cache/share_plus/`; the upstream implementation first copies attachments into that directory.

Restore the existing registered plugin and its result/file behavior. Preserve the parent commit as evidence. This correction does not claim to resolve the original Redmi Gmail return defect: it still needs a task-stack reproduction on the review device. The earlier OPPO check did not reproduce that specific defect.

Functional owners are only MainActivity.kt and platform_configuration_test.dart. Tests must exercise the real Dart share API response contract and retain the existing Android activity/provider delegation checks. No manifest, Buy source, SDK, dependency, APK, account or device change belongs to this correction.

Qualification evidence is retained outside managed worktrees at `C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/android-share-contract-fix/`.
