# Universal Chat boundary contract correction

Ticket: `UAW-CODEX-UNIVERSAL-CHAT-BOUNDARY-CONTRACT-V1-20260904`

Work ID: `universal-chat-boundary-contract-v1-20260904`

Baseline: `300f4247165a097d82624f4b40c9c2d611c7bc48`

Functional task-start base after exact owner admission: `9ccb302210e6300824e9e5e0ce84f2dd03c1e99c`

## Exact functional scope

- `apps/mobile/test/universal_intent_completion_test.dart`

The accepted Chat inbox displays its Business filter while preserving the requested Business initial filter and exact conversation results. The stale assertion that the filter is absent is corrected without changing product source, routing, Chat behavior, Store, Buy or accepted UI.

## Required qualification

- Complete Universal intent-completion test passes.
- Corrected C20E test remains fully passing.
- Exact ten-file Work/Store batch remains `145 passed, 70 skipped, 0 failed` after the child enters the replacement repair.
- Full analysis and combined Store/Buy/Chat boundaries pass on the replacement repair.
- No APK, device, deployment or private-account action.
