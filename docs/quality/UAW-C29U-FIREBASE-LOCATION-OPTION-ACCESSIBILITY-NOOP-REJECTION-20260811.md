# C29U Firebase location-option accessibility no-op rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1299-C29U-FIREBASE-LOCATION-OPTION-ACCESSIBILITY-NOOP-REJECTION`

The open Firebase location list exposed an accessibility option labelled
`ASIA-SOUTH1`, but invoking it closed the list and left `US` selected. No bucket
was created and Continue was not pressed.

The recovery opens the list, scrolls inside that exact screenshot-bounded
control until the regional row is visible, clicks the rendered `ASIA-SOUTH1`
row and requires the closed combo to display that value before advancing.
