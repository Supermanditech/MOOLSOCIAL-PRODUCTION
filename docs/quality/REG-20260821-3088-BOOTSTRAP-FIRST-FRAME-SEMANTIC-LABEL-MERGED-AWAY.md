# REG3088 — bootstrap first-frame semantic label merged away

- Date: 2026-08-21
- Status: registered before retry

The focused bootstrap test found the visible `Starting MoolSocial` text but no
node with the required `MoolSocial is starting` semantics label. Nested brand
semantics merged the wrapper instead of preserving a named first-frame node.
Flutter analysis remained clean. No build or device action followed.

Prevention: make the bootstrap wrapper an explicit semantic container with
explicit child nodes and retain both visible-text and semantic-label tests.
