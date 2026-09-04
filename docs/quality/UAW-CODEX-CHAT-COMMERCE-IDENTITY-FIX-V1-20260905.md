# Shared Chat authoritative identity correction

Ticket: UAW-CODEX-CHAT-COMMERCE-IDENTITY-FIX-V1-20260905. Parent: 30b9b8c7eb92b7ee688a40550a438175bb522e08, clean and origin-equal before child creation.

MVP-required correction, not a UI redesign: URI commerce metadata must never relabel a loaded conversation or borrow its verified badge/recipient identity. Preserve the exact loaded ChatThread. Unknown conversation fallbacks may show the supplied supplier context without verification. Keep the complete product context and existing return URI behavior separately intact.

Functional source owner: apps/mobile/lib/features/chat/chat_session.dart. Focused test owner: apps/mobile/test/global_contextual_chat_shell_test.dart. Both are already Codex-owned shared Chat paths. No Buy source, Work source, backend, account, credential, APK or device change belongs to this child.

Original deterministic probe: C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/boundary-probe-attempt1.log, SHA-256 8F63AD30DD5A18A4D01B3ED7A1934066937A329AD84F50D29FF15E46608A915F.

Required tests: production-gateway identity before/after loading, verified and unverified loaded threads, refresh failure, unknown unverified fallback, retained commerce facts, rendered conversation header/info and exact product/Back return. Then the existing shared Chat flow, settings, gateway and router suites plus full Flutter analysis. Use no-pub and retained expanded logs. Local qualification is not live backend or device acceptance.

Retain actual command/result/exit/hash evidence outside managed worktrees in C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905/chat-commerce-identity-fix/. This bootstrap document declares scope and evidence destination; it does not claim tests have passed. Registry support carries forward only the already sealed historical-evidence reference correction from f4658311d6a8000d680205b1a6043ee4e723cca5 and adds REG-20260905-4486. The source baseline remains the exact Chat parent; no other child's product changes are copied here.

After all source children and required combined regressions pass, the new clean, pushed, remote-equal combined baseline goes to Cursor for Redmi UAT BEFORE Codex OPPO APK/testing, as explicitly directed by the founder on 5 September.
