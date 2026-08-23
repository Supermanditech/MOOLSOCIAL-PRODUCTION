# REG-20260816-2619 — Chrome DOM rectangle coordinate opened Testing section

Date: 2026-08-16 IST

After REG2618, one coordinate click derived from the visible Internal Testing
anchor's DOM rectangle did not navigate to the track. Because the external
Chrome content coordinates did not align with the control surface, it expanded
the nearby `Testing` navigation section and left the app dashboard active. No
release, draft, file attachment, upload, activation or other Play write
occurred.

The correction is to count no route proof and prohibit further coordinate
actions derived from DOM rectangles on this browser surface. Use one keyboard
activation on the exact already-inspected Internal Testing anchor, then verify
the sanitized route shape and heading. If that fails, stop and require founder
navigation rather than trying another automation surface.
