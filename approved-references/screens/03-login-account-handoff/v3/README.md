# Screen 03 — Login / Account Handoff — native production v3

Production status: **Founder Accepted — immutable**

Screen03 v3 preserves the founder-accepted v2 login method, provider handoff,
email OTP and mobile OTP presentation byte-for-byte. It adds no screen, route,
copy, interaction, provider or customer-visible pixel.

This successor exists only to retain mandatory production-candidate provenance
coverage: profile device-review builds must emit their exact candidate identity
and both ready and boot-failure startup outcomes. The assertion prevents
`REG-20260806-006-PROFILE-RUNTIME-MARKER-SUPPRESSED` from recurring.

The accepted decision remains:

1. Screen03 follows explicit completion of Screen02.
2. Six provider handoffs and email/mobile OTP remain one-tap native actions.
3. MoolSocial never collects provider credentials or falsely claims that a
   device-review routing failure proves the customer is offline.
4. Successful verification preserves Screen02 state and opens Universal.
5. All v2 presentation, asset, behavior, fitment and golden owners remain exact.

This package is native-production/test-lock evidence. It intentionally contains
no HTML, CSS, JavaScript, reference-image copy or screenbook source. Screen03 v1
and v2 remain immutable history. A future founder-directed replacement requires
a new version; this directory must never be overwritten.
