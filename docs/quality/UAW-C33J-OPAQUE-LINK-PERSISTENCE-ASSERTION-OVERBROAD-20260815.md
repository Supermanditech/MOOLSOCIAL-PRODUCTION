# UAW C33J opaque-link persistence assertion over-broad

- Regression: `REG-20260815-2495-C33J-OPAQUE-LINK-PERSISTENCE-ASSERTION-OVERBROAD`
- Failure: the gate searched the whole session owner for `emailLink:` and rejected the legitimate in-memory Firebase adapter argument as though it were a persisted snapshot field.
- Impact: zero gate pass evidence; no external state changed.
- Prevention: inspect only the exact `JourneySnapshot` declaration through the `JourneyStore` boundary and reject `emailLink` or `emailAddress` there.
