# C33L FIX2 gate parent-replay compatibility qualification

Ticket: `UAW-C33L-FIX2-FIX1-GATE-PARENT-REPLAY-COMPATIBILITY`

The existing FIX1 prevention gate now preserves its exact Screen 04 safe-boot,
YouTube-return, email-link-return, and boot-fallback assertions while enforcing
three explicit lifecycle identities only: active FIX1, active FIX2 repair, or
active parent C33L. FIX2 and parent replay require the exact qualified FIX1
ticket SHA-256 and evidence path; parent replay also requires the exact C33L
ticket SHA-256. Every other active ticket, changed hash, or missing qualification
evidence fails closed.

PowerShell 7 and Windows PowerShell 5.1 both passed in the FIX2 repair-selected
state. Product runtime, Flutter UI, routes, sessions, services, backend, Hosting,
Firebase/provider state, Play, OPPO, email, SMS, and secrets were unchanged.
Build/upload/install/device-acceptance counts remain `0/0/0/0`.

The prior manifest and partial cycle are rejected attempt evidence. Parent C33L
must be reselected, the same gate must pass on both hosts in parent-replay mode,
and a fresh registry-bound source seal plus two complete zero-failure cycles are
required before any founder input prompt or AAB.
