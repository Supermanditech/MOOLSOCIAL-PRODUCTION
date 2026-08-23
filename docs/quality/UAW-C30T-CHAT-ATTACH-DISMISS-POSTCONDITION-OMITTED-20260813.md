# C30T Chat attachment dismiss postcondition omitted

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Device: OPPO CPH2375, serial `2b3e0f71`
- Installed artifact: Play Internal Testing `1.0.0-r60.44` (`2026081244`)

The Chat attachment-sheet sequence tapped the exact enabled `Dismiss` semantic target, but the next command attempted to find `Back to conversations` without first proving the sheet had closed. Its assertion found no target and stopped before any second tap.

No message, attachment, call, order, payment, uninstall, data clear, downgrade, or install occurred. The current overlay state must be inspected read-only. Every later dialog or sheet action requires its own fresh postcondition before another control can be exercised.
