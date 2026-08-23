# C10E OPPO IME off-screen rail semantics tap

- Registry: `REG-20260807-237-C10E-OPPO-IME-OFFSCREEN-RAIL-SEMANTICS-TAP`
- State: resolved; permanent device-test rule active.

During the unsent Chat draft replay, Android's visible IME covered the global
rail. UIAutomator retained off-screen global-rail semantic bounds, and the
first automation attempt tapped the remembered Mool coordinate. The tap hit
the keyboard's symbol-mode key, not Mool, and is not counted as a navigation
result. It did not send or delete any message.

OPPO navigation automation now cross-checks the current screenshot/IME state
with hierarchy bounds. When the IME covers the rail, the real-user sequence is
Back to dismiss the IME, verify the rail is visibly restored, then tap the
global destination. Hidden semantics are never treated as a visible hit target.
