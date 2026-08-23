# C30M fixed-string alternation false-zero inventory rejection

- ID: `REG-20260812-1436-C30M-FIXED-STRING-ALTERNATION-FALSE-ZERO-INVENTORY-REJECTION`
- Date: 2026-08-12
- Scope: local read-only provider deploy-owner discovery
- Result: false zero; no cloud call or device mutation occurred

The first inventory treated regex alternation as one literal fixed string. C30M retries with a three-element fixed-pattern array and requires at least one exact returned owner before reading any deployment implementation.
