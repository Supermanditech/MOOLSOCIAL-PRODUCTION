# C29U Chrome address-bar set-value rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1297-C29U-CHROME-ADDRESS-BAR-SET-VALUE-REJECTION`

The address-bar focus was verified, but Computer Use `set_value` returned an
unknown outcome. A fresh screenshot and accessibility observation proved the
original Firebase project-settings URL was still present, so no navigation or
cloud mutation occurred.

The recovery uses Chrome's `Ctrl+L` omnibox selection, re-verifies focus, types
only the exact Dev Firebase Storage URL, and presses Enter in separate observed
actions. `set_value` is not retried on this omnibox.
