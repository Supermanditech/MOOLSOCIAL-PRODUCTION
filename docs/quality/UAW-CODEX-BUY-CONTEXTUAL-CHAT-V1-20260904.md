# Buy contextual Chat closure

Ticket: `UAW-CODEX-BUY-CONTEXTUAL-CHAT-V1-20260904`

Defects: `UAT-BUY-004–014`, `UAT-BUY-022`

Baseline: `f94cfd4752dd73b58a69568475803d6cf25cb8d0`

## Scope

Shared Chat consumes the accepted Buy adapter context without editing Buy implementation owners. Supplier identity, product and order facts, truthful message/call states, compact keyboard-safe composition, exact return navigation and customer-facing empty states remain inside the existing shared Chat experience.

## Boundaries

- No Buy catalogue, cart, checkout, order or session implementation edits.
- No backend, APK, device or deployment action.
- No new Chat shell or duplicated commerce model.
