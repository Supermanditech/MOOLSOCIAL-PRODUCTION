# r66.9 bounded native PDF timeout child

Current outcome: source ac19156695918e4b226fac95557180ce0e3aef9c is qualified,pushed and remote-equal; its single guarded APK is built and installed with exact checksum92E7D302CEE91EA54F889FDB71C9A73E60231918F76CA3C37A923018683C9550. AUDIT-R668-01 native PDF rendering/recovery passes on OPPO. See device-review.md and post-install.json for bounded evidence and remaining dependencies. The original plan below is retained as history,not current build authority. One-build authority is consumed; no production promotion or founder acceptance is implied.

Parent evidence seal: a62c24b6dd3fb37c5c2e7ed98307a777dceba316. Child AUDIT-R668-01, inherited authorized local Android PDF preview. r66.8 remains failed-native evidence; no source/history replacement.

Change only WorkDocumentPreviewBridge.kt and WorkDocumentRenderService.kt plus the dependency-free WorkDocumentFrameRegression.kt executable native transport regression. Replace an EOF-dependent result transfer with a bounded length-framed single-page payload. Keep isolated/non-exported service, private read-only input, no URL/credentials/dependency, 10MB/pixel/page bounds, PNG/IHDR validation, cancellation and timeouts. No MainActivity, manifest, Buy or customer collection changes.

Native root cause is not yet proven: r66.8 valid QA PDF times out twice after actual service binding. Root-only stack access was refused and not escalated. Require successor actual PDF rendering/paging and recovery on OPPO before closure; host transport tests do not prove PdfRenderer or Binder behavior.

Run executable native protocol positive/negative tests and native compile; required Flutter regression cycles, analysis and existing gates; seal source clean/remote-equal before guarded unique APK1.0.0-r66.9/code2026090804. This candidate is only reserved, not build-authorized. Preserve current OPPO hotspot/security, Cursor/Redmi and all raw evidence. No real approval/message/payment/backend action.
