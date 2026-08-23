# REG2871 — C34L capture FIX2 combined retained-device schema skew

- Status: registered first combined PowerShell 7 failure; no retry.
- Scope: capture/producer to retained-evidence integration.
- Failure: the combined producer gate reached the retained child and rejected valid FIX2 OPPO cold-start evidence as missing legacy `deviceSerial`.
- Root cause: the OPPO FIX2 owner correctly replaced raw device identifiers with approved `deviceBindingSha256`, while the concurrently changing retained gate still required the obsolete raw field.
- Prevention: retained/recovery FIX2 must require `deviceBindingSha256`, forbid every raw device-identifier field, bind the exact approved value, and expose a stable identity before the combined producer gate is retried.
- Containment: combined fixture cleanup ran; no WinPS retry, real device, Play, OPPO, browser, private, secret, or external action occurred.
