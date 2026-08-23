# C31A Chat test-double optional tuple typecheck failure

Date: 2026-08-14
Registry ID: `REG-20260814-2123-C31A-CHAT-TEST-DOUBLE-OPTIONAL-TUPLE-TYPECHECK-FAILURE`

The first C31A backend typecheck rejected the fake Chat repository's `sendInput` tuple. The capture always writes six positions and the reply position may be `undefined`, but the tuple declared an optional final string under exact optional typing.

The correction declares the recorded slot as `string | undefined`, then reruns the implementation regression gate before the backend typecheck. No backend execution, live Dev write or deployment occurred.
