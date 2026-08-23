# C29U Firebase wrong-region selection pre-Continue rejection

- Date: 2026-08-11
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-DEV-BACKEND-DEPLOYMENT-C29U`
- Regression: `REG-20260811-1300-C29U-FIREBASE-WRONG-REGION-SELECTION-PRECONTINUE-REJECTION`

After scrolling the Firebase location overlay, the first rendered-row
coordinate selected `ASIA-NORTHEAST3` rather than `ASIA-SOUTH1`. The closed
combo exposed the mismatch immediately. Continue was not pressed and no bucket
or billing resource was created.

The recovery reopens and scrolls the same list, uses the observed adjacent-row
delta, and blocks until the closed combo reads exactly `ASIA-SOUTH1`.
