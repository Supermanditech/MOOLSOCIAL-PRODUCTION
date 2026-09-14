# UAW-CURSOR-UI-SHOP-CHAT-V1-CHILD4-20260829

State: `clean_shared_adapter_implementation_authorized`

- Parent product ticket: `UAW-CURSOR-UI-SHOP-CHAT-V1-20260829`.
- Coordination baseline: `b234900c28d9675f5043aadcbf8afc6b80822890`.
- Approved product baseline: `fa09a2ba171b2e6a709771ab46b37fc3821c99a3`.
- Authoritative shared Chat: `work/codex-ui/global-contextual-chat-shell-v1-20260828` at `30f4614574aae3c315d586944636a35ba314873d`.
- Work ID: `shop-chat-v1-child4-20260829`.

This is the clean implementation continuation of the existing Shop Chat ticket.
It does not create or reorder a product ticket. Child 3 retained the complete
fail-closed coordination and evidence repairs; Child 4 starts from that exact
state with one declared bootstrap commit and must pass `task_start` before any
Buy source change.

Smallest authorized product scope:

- inspect every founder-named shared Chat and current Buy owner;
- record the ordered mismatch inventory;
- implement only a Buy-owned thin route adapter to the authoritative shared
  contextual Chat shell where the mismatch is proved;
- prove exact Shop/Orders/Wholesale/Offers context and Android Back recovery;
- preserve the current custom Buy Chat only as a non-router test fallback until
  a separately proved cleanup is authorized.

Shared Chat source, backend, Firebase, Android configuration, OPPO,
`com.moolsocial.app.runtime`, and all unrelated approved behavior are excluded.
