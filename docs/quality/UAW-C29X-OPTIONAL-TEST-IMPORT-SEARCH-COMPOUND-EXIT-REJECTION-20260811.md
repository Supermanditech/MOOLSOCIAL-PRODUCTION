# C29X optional test-import search compound exit rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-CHAT-GLOBAL-EDGE-AND-CONTRAST-C29X`
- Result: compound diagnostic rejected

A bounded read of the Chat test import block completed, but the same shell command then searched optional tokens that were absent. Ripgrep returned its normal zero-match exit code and made the compound diagnostic appear failed. The displayed import block remains a lead only; subsequent required reads and optional searches are isolated with explicit exit semantics. No source retry, test, build, install or device action followed the rejected diagnostic.
